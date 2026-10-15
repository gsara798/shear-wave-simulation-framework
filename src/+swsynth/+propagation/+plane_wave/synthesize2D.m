function wavefield = synthesize2D(cfg, maps, directions)
%SYNTHESIZE2D Legacy-compatible planar observation of homogeneous plane waves.
% The source-radius and aperture precomputation is deliberately retained
% because the historical random-number stream consumes those draws.
arguments
    cfg (1,1) struct
    maps (1,1) struct
    directions (1,1) struct
end
if string(cfg.propagation.model) ~= "plane_wave"
    error("swsynth:InvalidPlaneWaveModel", ...
        "synthesize2D requires propagation.model=plane_wave.");
end

[cfg, ~] = swsynth.validateConfig(cfg);
validateMaps(maps);
validateDirections(directions, cfg.directions.count);

% Reproduce the legacy random-number stream. generateDirections starts from
% cfg.seed and consumes a model-dependent number of random draws. Re-run it
% here only to advance MATLAB's RNG to the exact state immediately after
% direction generation, then verify that the supplied directions match.
generatedDirections = swsynth.generateDirections(cfg);
verifyDirectionMatch(directions, generatedDirections);

N = cfg.directions.count;
ux = single(directions.ux(:).');
uy = single(directions.uy(:).');
uz = single(directions.uz(:).');

x = double(maps.x_m(:).');
z = double(maps.z_m(:).');

Nx = numel(x);
Nz = numel(z);

kMapZX = double(maps.k_map_zx);
if ~isequal(size(kMapZX), [Nz, Nx])
    error("swsynth:MapSizeMismatch", ...
        "maps.k_map_zx must have size [Nz, Nx].");
end

% Source radii are generated for both propagation models to preserve the
% historical RNG order, even though they are only used by spherical waves.
radiusRange = single(cfg.sources.radius_range_m);
rho = rand(1, N, "single");

if cfg.directions.space == "two_dimensional"
    sourceRadius = sqrt( ...
        (radiusRange(2)^2 - radiusRange(1)^2) .* rho + ...
        radiusRange(1)^2);
else
    sourceRadius = ( ...
        (radiusRange(2)^3 - radiusRange(1)^3) .* rho + ...
        radiusRange(1)^3).^(1/3);
end

xSource = sourceRadius .* ux + single(cfg.domain.Lx_m/2);
ySource = sourceRadius .* uy + single(cfg.domain.observation_y_m);
zSource = sourceRadius .* uz + single(cfg.domain.Lz_m/2);

% Explicit point position overrides legacy radius/direction placement only.
% Keep the historical random draws above to preserve regression behavior.
if ~isempty(cfg.sources.position_xyz_m)
    xSource(:) = single(cfg.sources.position_xyz_m(:,1));
    ySource(:) = single(cfg.sources.position_xyz_m(:,2));
    zSource(:) = single(cfg.sources.position_xyz_m(:,3));
end
parentSourceXYZ = [double(xSource(:)), double(ySource(:)), ...
    double(zSource(:))];
apertureDefinition = swsynth.sources.buildCoherentAperture( ...
    parentSourceXYZ(1,:), cfg.sources.aperture);
useFiniteAperture = cfg.sources.aperture.model == "line_segment";

if useFiniteAperture
    elementOffsetsXYZ = ...
        apertureDefinition.node_offsets_m(:) .* ...
        apertureDefinition.axis_xyz;
    sourceElementXYZ = reshape(parentSourceXYZ, N, 1, 3) + ...
        reshape(elementOffsetsXYZ, 1, [], 3);
else
    sourceElementXYZ = zeros(0, 0, 3);
end

directionsXYZ = double([
    ux(:), ...
    uy(:), ...
    uz(:)]);

excitation = ...
    swsynth.generateDirectionalExcitation( ...
        cfg, ...
        directionsXYZ);

polarizationZ = ...
    single(excitation.polarization_z(:));

amplitude = ...
    single(excitation.amplitude(:));

phase = ...
    single(excitation.phase_rad(:));

weights = ...
    single(excitation.weights(:));

fieldXZ = swsynth.propagation.plane_wave.synthesizeHomogeneousFieldXZ( ...
    kMapZX, x, z, ux, uy, uz, single(cfg.domain.observation_y_m), ...
    weights, initializeParallel(cfg.execution.use_parallel));

fieldZX = double(fieldXZ.');

if isfinite(cfg.noise.snr_db)
    signalPower = mean(abs(fieldZX(:)).^2);
    noisePower = signalPower / (10^(cfg.noise.snr_db/10));

    dataType = class(fieldZX);
    noiseReal = sqrt(noisePower/2) * ...
        randn(size(fieldZX), dataType);
    noiseImag = sqrt(noisePower/2) * ...
        randn(size(fieldZX), dataType);

    fieldZX = fieldZX + complex(noiseReal, noiseImag);
end

wavefield = struct();
wavefield.U_zx = fieldZX;
wavefield.component = cfg.wavefield.observed_component;
wavefield.frequency_hz = cfg.wavefield.frequency_hz;
wavefield.phase_model = cfg.propagation.phase_model;
wavefield.is_complex = true;
wavefield.output_convention = "U(z,x)";

wavefield.polarization_z = double(polarizationZ(:));
wavefield.weights = double(weights(:));
wavefield.phase_rad = double(phase(:));
if ~isempty(cfg.sources.excitation)
    wavefield.source_force_directions_xyz=double(cfg.sources.excitation.force_direction_xyz);
end
wavefield.amplitude = double(amplitude(:));

wavefield.sources = struct( ...
    "x_m", [], "y_m", [], "z_m", [], "radius_m", []);
end

function useParallel = initializeParallel(useParallel)
if useParallel
    try
        if isempty(gcp("nocreate"))
            parpool("threads");
        end
    catch
        useParallel = false;
    end
end
end

function validateMaps(maps)

required = ["x_m", "z_m", "k_map_zx"];

for i = 1:numel(required)
    if ~isfield(maps, required(i))
        error("swsynth:MissingMapField", ...
            "maps.%s is required.", required(i));
    end
end

end

function validateDirections(directions, expectedCount)

required = ["ux", "uy", "uz"];

for i = 1:numel(required)
    if ~isfield(directions, required(i))
        error("swsynth:MissingDirectionComponent", ...
            "directions.%s is required.", required(i));
    end
end

if any([ ...
        numel(directions.ux), ...
        numel(directions.uy), ...
        numel(directions.uz)] ~= expectedCount)
    error("swsynth:DirectionCountMismatch", ...
        "Direction arrays must contain directions.count elements.");
end

end

function verifyDirectionMatch(actual, expected)

tolerance = 10*eps("single");

if max(abs(double(actual.ux(:)) - double(expected.ux(:)))) > tolerance || ...
        max(abs(double(actual.uy(:)) - double(expected.uy(:)))) > tolerance || ...
        max(abs(double(actual.uz(:)) - double(expected.uz(:)))) > tolerance
    error("swsynth:DirectionConfigMismatch", ...
        "Supplied directions do not match the validated configuration and seed.");
end

end
