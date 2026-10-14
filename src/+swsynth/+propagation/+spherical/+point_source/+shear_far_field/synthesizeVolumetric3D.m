function out = synthesizeVolumetric3D(cfg, maps)
%SYNTHESIZEVOLUMETRIC3D Homogeneous 3D far-field point-force shear field.
% The field is the measured projection of transverse shear radiation.
% No longitudinal/near-field Green terms or heterogeneous ray bending.
[cfg, ~] = swsynth.validateConfig3D(cfg);

x = double(maps.x_m(:));
y = double(maps.y_m(:));
z = double(maps.z_m(:));
Nx = numel(x); Ny = numel(y); Nz = numel(z);
[X,Y,Z] = meshgrid(x,y,z);
targetXYZ = [X(:),Y(:),Z(:)];
N = cfg.directions.count;
positions = cfg.sources.position_xyz_m;
forces = cfg.sources.force_direction_xyz;
measurement = cfg.measurement.axis_xyz;

% A private seeded stream leaves the caller's global random state alone.
stream = RandStream('mt19937ar','Seed',double(cfg.seed));
jitter = cfg.sources.amplitude_jitter_fraction;
amp = 1 + jitter * randn(stream,N,1);
if jitter > 0
    rejected = amp <= 0;
    while any(rejected)
        amp(rejected) = 1 + jitter * randn(stream,nnz(rejected),1);
        rejected = amp <= 0;
    end
end
amp = amp .* cfg.sources.relative_amplitude(:);
if isempty(cfg.sources.phase_rad)
    phase = 2*pi*rand(stream,N,1);
else
    phase = cfg.sources.phase_rad(:);
end
weights = (amp .* exp(1i*phase)) / sqrt(N);

k = 2*pi*cfg.wavefield.frequency_hz/cfg.medium.background_cs_m_s;
exponent = cfg.propagation.geometric_decay_exponent;
field = complex(zeros(size(targetXYZ,1),1));
for i = 1:N
    delta = targetXYZ - positions(i,:);
    distance = sqrt(sum(delta.^2,2));
    if any(distance <= eps)
        error('swsynth:ObservationAtPointForce', ...
            'Observation points must not coincide with a point force.');
    end
    projection = swsynth.propagation.spherical.point_source.shear_far_field.computeShearProjection( ...
        positions(i,:),targetXYZ,forces(i,:),measurement);
    decay = ones(size(distance));
    if exponent ~= 0
        decay = 1 ./ max(distance,1e-6).^exponent;
    end
    field = field + weights(i) .* projection .* exp(1i*k*distance) .* decay;
end
% meshgrid(x,y,z) has dimensions [Ny,Nx,Nz]. Return [Nz,Ny,Nx].
field = permute(reshape(field,Ny,Nx,Nz),[3,1,2]);
if isfinite(cfg.noise.snr_db)
    power = mean(abs(field(:)).^2);
    sigma = sqrt(power/(10^(cfg.noise.snr_db/10))/2);
    field = field + sigma*(randn(stream,size(field))+1i*randn(stream,size(field)));
end
out = struct();
out.U_zyx = field;
out.x_m = x.'; out.y_m = y.'; out.z_m = z.';
out.dx_m = cfg.domain.dx_m;
out.dy_m = cfg.domain.dy_m;
out.dz_m = cfg.domain.dz_m;
out.directions = struct('count',N,'space',"three_dimensional");
out.source_positions_xyz_m = positions;
out.force_directions_xyz = forces;
out.source_weights = weights;
out.phase_rad = phase;
out.amplitude = amp;
out.k0_rad_m = k;
out.frequency_hz = cfg.wavefield.frequency_hz;
out.component = cfg.wavefield.observed_component;
out.quantity = cfg.wavefield.quantity;
out.measurement_axis_xyz = measurement;
out.phasor_convention = "u(t) = real{U exp(i 2*pi*f*t)}";
out.output_convention = "U_zyx(z,y,x)";
end
