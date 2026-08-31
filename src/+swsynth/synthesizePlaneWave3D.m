function out = synthesizePlaneWave3D(cfg)
%SYNTHESIZEPLANEWAVE3D Synthesize an observed 3D harmonic plane-wave field.
%
% Output orientation is U_zyx(z,y,x). The synthesized observable is the
% configured measurement-axis projection of a shear-polarized vector field.

arguments
    cfg (1,1) struct
end

[cfg, ~] = swsynth.validateConfig3D(cfg);

Nx = round(cfg.domain.Lx_m / cfg.domain.dx_m) + 1;
Ny = round(cfg.domain.Ly_m / cfg.domain.dy_m) + 1;
Nz = round(cfg.domain.Lz_m / cfg.domain.dz_m) + 1;

x_m = linspace(0, cfg.domain.Lx_m, Nx);
y_m = linspace(0, cfg.domain.Ly_m, Ny);
z_m = linspace(0, cfg.domain.Lz_m, Nz);

directionCfg = swsynth.defaultConfig();
directionCfg.seed = cfg.seed;
directionCfg.directions = cfg.directions;
directions = swsynth.generateDirections(directionCfg);

dirsXYZ = double([directions.ux(:), directions.uy(:), directions.uz(:)]);
measurementAxis = double(cfg.measurement.axis_xyz(:)).';

% generateDirections resets the RNG to cfg.seed. For deterministic angular
% samplers this leaves the subsequent polarization/amplitude/phase stream
% aligned with the legacy REQ3D analytical implementation.
[polarizations, projectionWeights] = polarizationsFor( ...
    dirsXYZ, measurementAxis, cfg.polarization.model);

N = size(dirsXYZ,1);
amp = 1 + cfg.sources.amplitude_jitter_fraction * randn(1,N);
phase0 = 2*pi*rand(1,N);
weights = (amp .* exp(1i*phase0)) / sqrt(N);
observedWeights = projectionWeights .* weights;

k0 = 2*pi*cfg.wavefield.frequency_hz / cfg.medium.background_cs_m_s;
U_zyx = complex(zeros(Nz, Ny, Nx, 'single'));
[X_yx, Y_yx] = meshgrid(single(x_m), single(y_m));
zSingle = single(z_m);
k0Single = single(k0);
batchSize = cfg.execution.synthesis_batch_size;

parfor (iz = 1:Nz, parallelCount(cfg.execution.use_parallel))
    plane = complex(zeros(Ny, Nx));
    zj = zSingle(iz);
    for n0 = 1:batchSize:N
        n1 = min(N, n0 + batchSize - 1);
        idx = n0:n1;
        phase = k0Single * ( ...
            X_yx(:) * double(directions.ux(idx)) + ...
            Y_yx(:) * double(directions.uy(idx)) + ...
            double(zj) * double(directions.uz(idx)));
        plane = plane + reshape( ...
            exp(1i*phase) * observedWeights(idx).', Ny, Nx);
    end
    U_zyx(iz,:,:) = plane;
end

U_zyx = double(U_zyx);

if isfinite(cfg.noise.snr_db)
    signalPower = mean(abs(U_zyx(:)).^2);
    noisePower = signalPower / (10^(cfg.noise.snr_db/10));
    noise = sqrt(noisePower/2) * ...
        (randn(size(U_zyx)) + 1i*randn(size(U_zyx)));
    U_zyx = U_zyx + noise;
end

out = struct();
out.U_zyx = U_zyx;
out.x_m = x_m;
out.y_m = y_m;
out.z_m = z_m;
out.dx_m = cfg.domain.dx_m;
out.dy_m = cfg.domain.dy_m;
out.dz_m = cfg.domain.dz_m;
out.directions = directions;
out.polarization_xyz = polarizations;
out.projection_weights = projectionWeights;
out.source_weights = weights;
out.observed_weights = observedWeights;
out.k0_rad_m = k0;
out.frequency_hz = cfg.wavefield.frequency_hz;
out.component = cfg.wavefield.observed_component;
out.quantity = cfg.wavefield.quantity;
out.measurement_axis_xyz = measurementAxis;
out.phasor_convention = "u(t) = real{U exp(i 2*pi*f*t)}";
out.output_convention = "U_zyx(z,y,x)";

end

function [polarizations, projectionWeights] = polarizationsFor( ...
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
            "Unsupported 3D polarization model %s.", model);
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

function count = parallelCount(useParallel)
if useParallel
    count = Inf;
else
    count = 0;
end
end
