function result = run(requestedConfig)
%RUN Execute one fast synthetic shear-wave simulation.
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

[cfg, validation] = swsynth.validateConfig(requestedConfig);
maps = swsynth.buildMediumMaps(cfg);

requestedDirections = swsynth.generateDirections(cfg);
requestedDirectionMetrics = ...
    swsynth.summarizePlaneIntersection(requestedDirections);

switch cfg.propagation.model
    case "projected3d_eikonal"
        wavefield = ...
            swsynth.synthesizeProjected3DEikonal( ...
                cfg, ...
                maps, ...
                requestedDirections);

    otherwise
        wavefield = ...
            swsynth.synthesizeWavefield2D( ...
                cfg, ...
                maps, ...
                requestedDirections);
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
