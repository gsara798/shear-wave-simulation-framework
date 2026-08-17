function wavefield = synthesizeWavefield2D(cfg, maps, directions)
%SYNTHESIZEWAVEFIELD2D Synthesize a complex shear-like field U(z,x).
%
% This function preserves the current REQ-ML synthetic behavior:
%
% - plane-wave and spherical-wave superposition;
% - public output orientation U(z,x);
% - single-precision internal accumulation;
% - random transverse polarization in 3D direction space;
% - in-plane SV-like polarization in 2D direction space;
% - random amplitudes and phases;
% - optional geometric amplitude decay for spherical waves;
% - optional complex additive white Gaussian noise.
%
% Usage:
%   cfg = swsynth.defaultConfig();
%   [cfg, ~] = swsynth.validateConfig(cfg);
%   maps = swsynth.buildMediumMaps(cfg);
%   directions = swsynth.generateDirections(cfg);
%   wavefield = swsynth.synthesizeWavefield2D(cfg, maps, directions);

arguments
    cfg (1,1) struct
    maps (1,1) struct
    directions (1,1) struct
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

if cfg.propagation.model == "plane_wave"
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
else
    % Always evaluate the legacy polarization, including for point-force
    % radiation, so the established random-number sequence is unchanged.
    legacyPolarizationZ = computePolarizationZ(ux, uy, uz, cfg);

    amplitudeJitter = ...
        single(cfg.sources.amplitude_jitter_fraction);

    amplitude = ...
        single(1 + ...
        amplitudeJitter * randn(1, N, "single"));

    phase = ...
        2*pi * rand(1, N, "single");

    if cfg.sources.radiation.model == ...
            "constant_directional_polarization"
        polarizationZ = legacyPolarizationZ;
        weights = ...
            (amplitude .* polarizationZ .* ...
             exp(1i * phase)) / sqrt(N);
    else
        % The spatially varying point-force projection is applied exactly
        % once inside the spherical propagation loops below.
        polarizationZ = single(zeros(0, 1));
        weights = (amplitude .* exp(1i * phase)) / sqrt(N);
    end
end

fieldXZ = complex(zeros(Nx, Nz, "single"));
observationY = single(cfg.domain.observation_y_m);
useParallel = cfg.execution.use_parallel;

if useParallel
    try
        if isempty(gcp("nocreate"))
            parpool("threads");
        end
    catch
        % Fall back to serial execution when no parallel pool is available.
        useParallel = false;
    end
end

switch cfg.propagation.model
    case "spherical_wave"
        switch cfg.propagation.phase_model
            case "local_k_distance"
                parfor (zIndex = 1:Nz, parallelFlag(useParallel))
                    column = complex(zeros(Nx, 1, "single"));
                    xColumn = single(x(:));
                    zValue = single(z(zIndex));
                    localK = single(kMapZX(zIndex, :).');

                    for directionIndex = 1:N
                        distance = sqrt( ...
                            (xColumn - xSource(directionIndex)).^2 + ...
                            (observationY - ySource(directionIndex)).^2 + ...
                            (zValue - zSource(directionIndex)).^2);

                        geometricAmplitude = computeGeometricAmplitude( ...
                            distance, ...
                            cfg.amplitude.geometric_decay_exponent);

                        if cfg.sources.radiation.model == ...
                                "point_force_shear_far_field"
                            radiationProjection = ...
                                computeRadiationProjection( ...
                                    cfg, ...
                                    [xSource(directionIndex), ...
                                     ySource(directionIndex), ...
                                     zSource(directionIndex)], ...
                                    xColumn, observationY, zValue);

                            column = column + ...
                                weights(directionIndex) .* ...
                                radiationProjection .* ...
                                exp(1i * (localK .* distance)) .* ...
                                geometricAmplitude;
                        else
                            % Preserve the legacy arithmetic path exactly.
                            column = column + ...
                                weights(directionIndex) .* ...
                                exp(1i * (localK .* distance)) .* ...
                                geometricAmplitude;
                        end
                    end

                    fieldXZ(:, zIndex) = column;
                end

            case "straight_ray_numerical"
                [targetX, targetZ] = ndgrid(x, z);
                pointCount = numel(targetX);

                targetXYZ = [ ...
                    targetX(:), ...
                    double(observationY) * ones(pointCount, 1), ...
                    targetZ(:)];

                contributionByDirection = ...
                    complex(zeros(pointCount, N, "single"));

                omega = 2*pi*cfg.wavefield.frequency_hz;
                amplitudeExponent = ...
                    cfg.amplitude.geometric_decay_exponent;

                parfor (directionIndex = 1:N, parallelFlag(useParallel))
                    sourceXYZ = double([ ...
                        xSource(directionIndex), ...
                        ySource(directionIndex), ...
                        zSource(directionIndex)]);

                    travelTimeS = ...
                        swsynth.integrateStraightRayTravelTime( ...
                            cfg, sourceXYZ, targetXYZ);

                    distance = sqrt(sum( ...
                        (targetXYZ - sourceXYZ).^2, ...
                        2));

                    geometricAmplitude = computeGeometricAmplitude( ...
                        distance, ...
                        amplitudeExponent);

                    propagationPhase = single(omega .* travelTimeS);

                    if cfg.sources.radiation.model == ...
                            "point_force_shear_far_field"
                        radiationProjection = ...
                            computeRadiationProjectionForPoints( ...
                                cfg, sourceXYZ, targetXYZ);

                        contributionByDirection(:, directionIndex) = ...
                            weights(directionIndex) .* ...
                            radiationProjection .* ...
                            exp(1i .* propagationPhase) .* ...
                            single(geometricAmplitude);
                    else
                        % Preserve the legacy arithmetic path exactly.
                        contributionByDirection(:, directionIndex) = ...
                            weights(directionIndex) .* ...
                            exp(1i .* propagationPhase) .* ...
                            single(geometricAmplitude);
                    end
                end

                fieldXZ(:) = sum(contributionByDirection, 2);
        end

    case "plane_wave"
        referenceK = double(kMapZX(1,1));
        relativeVariation = ...
            max(abs(kMapZX(:) - referenceK)) / ...
            max(abs(referenceK), eps);

        if relativeVariation > 1e-9
            error("swsynth:PlaneWaveRequiresHomogeneousMedium", ...
                "plane_wave requires a spatially uniform wavenumber map.");
        end

        parfor (zIndex = 1:Nz, parallelFlag(useParallel))
            column = complex(zeros(Nx, 1, "single"));
            xColumn = single(x(:));
            zValue = single(z(zIndex));

            for directionIndex = 1:N
                spatialPhase = referenceK * ( ...
                    ux(directionIndex) * xColumn + ...
                    uy(directionIndex) * observationY + ...
                    uz(directionIndex) * zValue);

                column = column + ...
                    weights(directionIndex) .* exp(1i * spatialPhase);
            end

            fieldXZ(:, zIndex) = column;
        end
end

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
wavefield.amplitude = double(amplitude(:));

if cfg.propagation.model == "spherical_wave"
    wavefield.sources = struct( ...
        "x_m", double(xSource), ...
        "y_m", double(ySource), ...
        "z_m", double(zSource), ...
        "radius_m", double(sourceRadius), ...
        "radiation_model", cfg.sources.radiation.model, ...
        "force_direction_xyz", ...
            double(cfg.sources.radiation.force_direction_xyz), ...
        "observed_direction_xyz", [0, 0, 1]);
else
    wavefield.sources = struct( ...
        "x_m", [], ...
        "y_m", [], ...
        "z_m", [], ...
        "radius_m", []);
end

end

function projection = computeRadiationProjection( ...
    cfg, sourceXYZ, xColumn, observationY, zValue)

observationXYZ = [ ...
    double(xColumn), ...
    double(observationY) * ones(numel(xColumn), 1), ...
    double(zValue) * ones(numel(xColumn), 1)];

projection = single( ...
    swsynth.propagation.spherical.computePointForceShearProjection( ...
        double(sourceXYZ), ...
        observationXYZ, ...
        double(cfg.sources.radiation.force_direction_xyz), ...
        [0, 0, 1]));

end

function projection = computeRadiationProjectionForPoints( ...
    cfg, sourceXYZ, observationXYZ)

projection = single( ...
    swsynth.propagation.spherical.computePointForceShearProjection( ...
        double(sourceXYZ), ...
        double(observationXYZ), ...
        double(cfg.sources.radiation.force_direction_xyz), ...
        [0, 0, 1]));

end

function geometricAmplitude = computeGeometricAmplitude( ...
    distance, exponent)

if exponent ~= 0
    geometricAmplitude = ...
        1 ./ max(distance, 1e-6).^exponent;
else
    geometricAmplitude = ones(size(distance), "like", distance);
end

end

function polarizationZ = computePolarizationZ(ux, uy, uz, cfg)

if cfg.polarization.model == "in_plane_sv"
    polarizationZ = ux;
    return;
end

N = numel(ux);
polarizationZ = zeros(1, N, "single");

for i = 1:N
    direction = [ux(i), uy(i), uz(i)];

    randomVector = randn(1, 3, "single");
    polarization = ...
        randomVector - dot(randomVector, direction) * direction;
    magnitude = norm(polarization);

    if magnitude < 1e-10
        randomVector = randn(1, 3, "single");
        polarization = ...
            randomVector - dot(randomVector, direction) * direction;
        magnitude = norm(polarization);

        if magnitude < 1e-10
            if abs(direction(1)) < 0.9
                fallback = [1, 0, 0];
            else
                fallback = [0, 1, 0];
            end

            polarization = ...
                fallback - dot(fallback, direction) * direction;
            magnitude = norm(polarization);
        end
    end

    polarization = polarization / magnitude;
    polarizationZ(i) = polarization(3);
end

end

function flag = parallelFlag(useParallel)

flag = 1;
if ~useParallel
    flag = 0;
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
