function result = run(requestedConfig)
%RUN Execute a synthetic wavefield in planar or volumetric geometry.
%
% Usage:
%   cfg = swsynth.defaultConfig();
%   result = swsynth.run(cfg);
%
% Result fields:
%   config
%   validation
%   coordinates
%   medium
%   directions
%   direction_metrics
%   wavefield
%   truth
%   output_convention

arguments
    requestedConfig (1,1) struct = swsynth.defaultConfig()
end

% V2 unified public entry: preserve legacy volumetric configs (domain.Ly_m)
% and support an explicit observation geometry on volumetric requests.
% Keep the two established numerical backends and validations unchanged.
requestedGeometry = "";
isVolumetric = isfield(requestedConfig, "domain") && ...
    isstruct(requestedConfig.domain) && ...
    isfield(requestedConfig.domain, "Ly_m");
if isfield(requestedConfig, "observation") && ...
        isstruct(requestedConfig.observation) && ...
        isfield(requestedConfig.observation, "geometry")
    observationGeometry = lower(string(requestedConfig.observation.geometry));
    requestedGeometry = observationGeometry;
    if ~isscalar(observationGeometry) || ...
            ~ismember(observationGeometry, ["volumetric3d","2d","projected3d"])
        error("swsynth:InvalidObservationGeometry", ...
            "Unsupported observation.geometry.");
    end
    if observationGeometry == "volumetric3d"
        if ~isVolumetric
            error("swsynth:MissingVolumetricDomain", ...
                "volumetric3d requires domain.Ly_m and domain.dy_m.");
        end
        isVolumetric = true;
    elseif isVolumetric
        error("swsynth:ObservationDomainMismatch", ...
            "A 3D domain cannot request a planar observation in this API.");
    end
    if isfield(requestedConfig.observation,"component") && ...
            lower(string(requestedConfig.observation.component)) ~= "z"
        error("swsynth:UnsupportedObservationComponent", ...
            "The explicit observation contract currently supports component=z.");
    end
    requestedConfig = rmfield(requestedConfig,"observation");
end
% New contract: plane_wave + eikonal + projected3d is mapped to the
% established projected3d directional solver; legacy configs remain valid.
if requestedGeometry == "projected3d" && ...
        isfield(requestedConfig,"propagation") && ...
        isfield(requestedConfig.propagation,"phase_model") && ...
        string(requestedConfig.propagation.phase_model) == "eikonal"
    if ~isfield(requestedConfig.propagation,"model") || ...
            string(requestedConfig.propagation.model) ~= "plane_wave"
        error("swsynth:PhaseRoutingUnsupported", ...
            "projected3d eikonal currently requires propagation.model=plane_wave.");
    end
    solver = swsynth.phase.resolveSolver("plane_wave","eikonal","projected3d");
    if solver ~= "projected3d_directional_eikonal"
        error("swsynth:PhaseRoutingUnsupported","No projected 3D eikonal solver.");
    end
    requestedConfig.propagation.model = "projected3d_eikonal";
elseif requestedGeometry == "2d" && ...
        isfield(requestedConfig,"propagation") && ...
        isfield(requestedConfig.propagation,"phase_model") && ...
        string(requestedConfig.propagation.phase_model) == "eikonal"
    error("swsynth:PhaseRoutingUnsupported", ...
        "2D eikonal plane-wave synthesis is not implemented.");
end
if isVolumetric
    result = swsynth.internal.runVolumetric(requestedConfig);
    return;
end

[cfg, validation] = swsynth.validateConfig(requestedConfig);
maps = swsynth.buildMediumMaps(cfg);

requestedDirections = swsynth.generateDirections(cfg);
requestedDirectionMetrics = ...
    swsynth.summarizePlaneIntersection(requestedDirections);

switch cfg.propagation.model
    case "projected3d_eikonal"
        wavefield = ...
            swsynth.propagation.plane_wave.synthesizeProjected3D( ...
                cfg, ...
                maps, ...
                requestedDirections);

    case "spherical_wave"
        if cfg.sources.radiation.model == "point_force_shear_far_field"
            if cfg.directions.space == "two_dimensional"
                wavefield = swsynth.propagation.spherical.point_source.shear_far_field.synthesize2D( ...
                    cfg, maps, requestedDirections);
            else
                wavefield = swsynth.propagation.spherical.point_source.shear_far_field.synthesizeProjected3D( ...
                    cfg, maps, requestedDirections);
            end
        else
            wavefield = swsynth.synthesizeWavefield2D(cfg,maps,requestedDirections);
        end

    case "plane_wave"
        % Select the analytic solver from the actual directional geometry.
        % Legacy local_k_distance is retained as the analytical alias here.
        planeGeometry = "2d";
        if cfg.directions.space == "three_dimensional"
            planeGeometry = "projected3d";
        end
        selectedSolver = swsynth.phase.resolveSolver( ...
            "plane_wave",cfg.propagation.phase_model,planeGeometry);
        if ~ismember(selectedSolver, ...
                ["homogeneous_plane_2d","homogeneous_projected_3d"])
            error("swsynth:PhaseRoutingUnsupported", ...
                "Unsupported plane-wave phase solver.");
        end
        wavefield = swsynth.propagation.plane_wave.synthesizeObserved2D( ...
            cfg,maps,requestedDirections);

    otherwise
        error("swsynth:UnsupportedPropagationModel", ...
            "Unsupported propagation model: %s",cfg.propagation.model);
end

if isfield(wavefield, "directions_xyz")
    directions = effectiveDirectionsFromXYZ( ...
        wavefield.directions_xyz, ...
        requestedDirections, ...
        cfg);
else
    directions = requestedDirections;
end

directionMetrics = ...
    swsynth.summarizePlaneIntersection(directions);

spectralMetrics = ...
    swsynth.metrics.computeWavefieldSpectralMetrics( ...
        wavefield.U_zx, ...
        maps.dx_m, ...
        maps.dz_m);

result = struct();
result.config = cfg;
result.validation = validation;

result.coordinates = struct();
result.coordinates.x_m = maps.x_m;
result.coordinates.z_m = maps.z_m;
result.coordinates.dx_m = maps.dx_m;
result.coordinates.dz_m = maps.dz_m;

result.medium = maps;

result.requested_directions = requestedDirections;
result.requested_direction_metrics = ...
    requestedDirectionMetrics;

result.directions = directions;
result.direction_metrics = directionMetrics;

result.wavefield = wavefield;
result.spectral_metrics = spectralMetrics;

result.truth = struct();
result.truth.cs_map_zx = maps.cs_map_zx;
result.truth.k_map_zx = maps.k_map_zx;
result.truth.material_id_zx = maps.material_id_zx;
result.truth.valid_mask_zx = true(size(maps.cs_map_zx));

result.output_convention = "U(z,x), maps(z,x)";
result.sample = swsynth.buildWavefieldSample(result);

end


function directions = effectiveDirectionsFromXYZ( ...
        directionsXYZ, requestedDirections, cfg)

directionsXYZ = double(directionsXYZ);

if ~ismatrix(directionsXYZ) || ...
        size(directionsXYZ,2) ~= 3 || ...
        any(~isfinite(directionsXYZ), "all")
    error( ...
        "swsynth:InvalidEffectiveDirections", ...
        "wavefield.directions_xyz must be a finite N-by-3 array.");
end

directionNorms = vecnorm(directionsXYZ,2,2);

if any(directionNorms <= eps)
    error( ...
        "swsynth:InvalidEffectiveDirections", ...
        "Every effective direction must have nonzero magnitude.");
end

directionsXYZ = directionsXYZ ./ directionNorms;

directions = struct();

directions.ux = single(directionsXYZ(:,1).');
directions.uy = single(directionsXYZ(:,2).');
directions.uz = single(directionsXYZ(:,3).');

directions.count = size(directionsXYZ,1);
directions.space = requestedDirections.space;
directions.sampling_method = ...
    requestedDirections.sampling_method;
directions.support_type = ...
    requestedDirections.support_type;

directions.in_plane_count = ...
    nnz(abs(directionsXYZ(:,2)) <= 1e-12);

directions.requested_in_plane_count = ...
    cfg.directions.in_plane_count;

fieldsToCopy = [
    "solid_angle_sr"
    "support_axis_xyz"
    "support_half_angle_deg"];

for fieldIndex = 1:numel(fieldsToCopy)
    fieldName = fieldsToCopy(fieldIndex);

    if isfield(requestedDirections, fieldName)
        directions.(fieldName) = ...
            requestedDirections.(fieldName);
    end
end

end
