function out = synthesizeVolumetricEikonal3D(cfg, maps)
%SYNTHESIZEVOLUMETRICEIKONAL3D Synthesize a heterogeneous 3D harmonic field.
%
% Each directional component solves |grad(T)| = 1/c(x,y,z), then contributes
% exp(i*omega*T) weighted by shear polarization projected onto the explicit
% measurement axis. Output orientation is U_zyx(z,y,x).

arguments
    cfg (1,1) struct
    maps (1,1) struct
end

[cfg, ~] = swsynth.validateConfig3D(cfg);
if cfg.propagation.model ~= "volumetric_eikonal"
    error("swsynth:IncorrectVolumetricPropagationModel", ...
        "synthesizeVolumetricEikonal3D requires volumetric_eikonal.");
end

requiredMaps = ["x_m","y_m","z_m","cs_map_zyx","dx_m","dy_m","dz_m"];
for name = requiredMaps
    if ~isfield(maps, name)
        error("swsynth:MissingVolumetricMapField", ...
            "maps.%s is required.", name);
    end
end

directionCfg = swsynth.defaultConfig();
directionCfg.seed = cfg.seed;
directionCfg.directions = cfg.directions;
directions = swsynth.generateDirections(directionCfg);
directionsXYZ = double([directions.ux(:), directions.uy(:), directions.uz(:)]);
measurementAxis = double(cfg.measurement.axis_xyz(:)).';

[polarizations, projectionWeights] = polarizationFor( ...
    directionsXYZ, measurementAxis, cfg.polarization.model);

N = size(directionsXYZ,1);
amp = 1 + cfg.sources.amplitude_jitter_fraction * randn(1,N);
phase0 = 2*pi*rand(1,N);
sourceWeights = (amp .* exp(1i*phase0)) / sqrt(N);
observedWeights = projectionWeights .* sourceWeights;

omega = 2*pi*cfg.wavefield.frequency_hz;
referenceCs = cfg.medium.background_cs_m_s;
solverOptions = struct( ...
    "MaximumIterations", cfg.propagation.eikonal.maximum_iterations, ...
    "ToleranceS", cfg.propagation.eikonal.tolerance_s);

contributions = cell(N,1);
travelTimeDiagnostics = cell(N,1);

if cfg.execution.use_parallel
    try
        if isempty(gcp("nocreate"))
            parpool("threads");
        end
        parfor n = 1:N
            [tau, diagTau] = directionalSolve( ...
                maps, directionsXYZ(n,:), referenceCs, solverOptions);
            contributions{n} = observedWeights(n) .* exp(1i*omega.*tau);
            travelTimeDiagnostics{n} = diagTau;
        end
    catch
        for n = 1:N
            [tau, diagTau] = directionalSolve( ...
                maps, directionsXYZ(n,:), referenceCs, solverOptions);
            contributions{n} = observedWeights(n) .* exp(1i*omega.*tau);
            travelTimeDiagnostics{n} = diagTau;
        end
    end
else
    for n = 1:N
        [tau, diagTau] = directionalSolve( ...
            maps, directionsXYZ(n,:), referenceCs, solverOptions);
        contributions{n} = observedWeights(n) .* exp(1i*omega.*tau);
        travelTimeDiagnostics{n} = diagTau;
    end
end

U_zyx = complex(zeros(size(maps.cs_map_zyx)));
for n = 1:N
    U_zyx = U_zyx + contributions{n};
end

if isfinite(cfg.noise.snr_db)
    signalPower = mean(abs(U_zyx(:)).^2);
    noisePower = signalPower / (10^(cfg.noise.snr_db/10));
    U_zyx = U_zyx + sqrt(noisePower/2) .* ...
        (randn(size(U_zyx)) + 1i*randn(size(U_zyx)));
end

out = struct();
out.U_zyx = U_zyx;
out.x_m = maps.x_m;
out.y_m = maps.y_m;
out.z_m = maps.z_m;
out.dx_m = maps.dx_m;
out.dy_m = maps.dy_m;
out.dz_m = maps.dz_m;
out.directions = directions;
out.polarization_xyz = polarizations;
out.projection_weights = projectionWeights;
out.source_weights = sourceWeights;
out.observed_weights = observedWeights;
out.frequency_hz = cfg.wavefield.frequency_hz;
out.component = cfg.wavefield.observed_component;
out.quantity = cfg.wavefield.quantity;
out.measurement_axis_xyz = measurementAxis;
out.phasor_convention = "u(t) = real{U exp(i 2*pi*f*t)}";
out.output_convention = "U_zyx(z,y,x)";
out.propagation_model = "volumetric_eikonal";
out.travel_time_diagnostics = travelTimeDiagnostics;

end

function [tau, diagnostics] = directionalSolve(maps, direction, referenceCs, options)
[tau, diagnostics] = ...
    swsynth.propagation.volumetric3d.computeDirectionalTravelTime( ...
        maps.cs_map_zyx, maps.x_m, maps.y_m, maps.z_m, ...
        direction, referenceCs, options);
end

function [polarizations, projectionWeights] = polarizationFor( ...
        directions, measurementAxis, model)
N = size(directions,1);
polarizations = zeros(N,3);

switch string(model)
    case "transverse_preferred"
        for n = 1:N
            k = directions(n,:) / norm(directions(n,:));
            p = measurementAxis - dot(measurementAxis,k)*k;
            if norm(p) < 1e-10
                p = fallbackTransverse(k);
            end
            polarizations(n,:) = p / norm(p);
        end

    case "transverse_random"
        for n = 1:N
            k = directions(n,:) / norm(directions(n,:));
            p = [];
            for attempt = 1:8
                r = randn(1,3);
                candidate = r - dot(r,k)*k;
                if norm(candidate) >= 1e-10
                    p = candidate / norm(candidate);
                    break
                end
            end
            if isempty(p)
                p = fallbackTransverse(k);
            end
            polarizations(n,:) = p;
        end

    otherwise
        error("swsynth:InvalidPolarizationModel", ...
            "Unsupported volumetric polarization model %s.", model);
end

projectionWeights = (polarizations * measurementAxis(:)).';
end

function p = fallbackTransverse(k)
axes = eye(3);
for i = 1:3
    candidate = axes(i,:) - dot(axes(i,:),k)*k;
    if norm(candidate) >= 1e-10
        p = candidate / norm(candidate);
        return
    end
end
error("swsynth:PolarizationFailure", ...
    "Could not construct a transverse polarization.");
end
