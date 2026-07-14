function metrics = angularSpectrum2D(result)
%ANGULARSPECTRUM2D Quantify propagation directions of the vector shear field.
%
% metrics = kwsim.diagnostics.angularSpectrum2D(result)
%
% The lateral and axial complex shear-displacement phasors are tapered and
% transformed together. Energy is integrated over an annulus around the
% expected shear wavenumber k_s=2*pi*f0/c_s. With the repository phasor
% convention U(x,z)*exp(+i*omega*t), a wave travelling in direction d has
% U proportional to exp(-i*k*d.r); therefore propagation direction is the
% negative of MATLAB's spatial-FFT wavenumber.
%
% Angles are measured in public [x,z] coordinates: 0 deg is lateral +x and
% +90 deg is axial +z. Entropy is normalized to [0,1], where a single
% angular bin is zero and uniform energy over all bins is one.

arguments
    result struct
end

cfg = result.config_resolved;
ux = double(result.fields.displacement.lateral_shear_zx);
uz = double(result.fields.displacement.axial_shear_zx);
[Nz, Nx] = size(ux);
if ~isequal(size(uz), [Nz, Nx]) || Nx < 4 || Nz < 4
    error('kwsim:InvalidAngularField', ...
        'Vector shear fields must be matching [Nz,Nx] arrays of at least 4-by-4.');
end

dx_m = mean(diff(result.axes.x_m));
dz_m = mean(diff(result.axes.z_m));
window_x = hannLocal(Nx).';
window_z = hannLocal(Nz);
window_zx = window_z * window_x;

% Fourfold zero-padding improves integration of angular sectors without
% pretending to add physical spatial resolution.
Nfft_x = 2^nextpow2(4*Nx);
Nfft_z = 2^nextpow2(4*Nz);
Ux = fftshift(fft2(ux .* window_zx, Nfft_z, Nfft_x));
Uz = fftshift(fft2(uz .* window_zx, Nfft_z, Nfft_x));
energy = abs(Ux).^2 + abs(Uz).^2;

kx_fft_rad_m = 2*pi*((-floor(Nfft_x/2)):(ceil(Nfft_x/2)-1)) / ...
    (Nfft_x*dx_m);
kz_fft_rad_m = 2*pi*((-floor(Nfft_z/2)):(ceil(Nfft_z/2)-1)) / ...
    (Nfft_z*dz_m);
[KXfft, KZfft] = meshgrid(kx_fft_rad_m, kz_fft_rad_m);
wavenumber = hypot(KXfft, KZfft);
angle_deg = atan2d(-KZfft, -KXfft);

reference_cs_m_s = median(result.truth.cs_m_s_zx, 'all');
reference_k_rad_m = 2*pi*result.axes.f0_hz / reference_cs_m_s;
relative_halfwidth = cfg.diagnostics.angular_annulus_relative_halfwidth;
annulus = wavenumber >= reference_k_rad_m*(1-relative_halfwidth) & ...
    wavenumber <= reference_k_rad_m*(1+relative_halfwidth);
annular_energy = energy(annulus);
if isempty(annular_energy) || sum(annular_energy) <= realmin('double')
    error('kwsim:EmptyAngularSpectrum', ...
        'No finite shear energy was found in the expected wavenumber annulus.');
end

bin_width_deg = cfg.diagnostics.angular_bin_width_deg;
bin_edges_deg = -180:bin_width_deg:180;
if abs(bin_edges_deg(end) - 180) > 10*eps(180)
    error('kwsim:InvalidAngularBinWidth', ...
        'diagnostics.angular_bin_width_deg must divide 360 degrees exactly.');
end
bin_index = discretize(angle_deg(annulus), bin_edges_deg);
valid_bin = ~isnan(bin_index);
bin_energy = accumarray(bin_index(valid_bin), annular_energy(valid_bin), ...
    [numel(bin_edges_deg) - 1, 1], @sum, 0).';
probability = bin_energy / sum(bin_energy);
bin_centres_deg = bin_edges_deg(1:end-1) + bin_width_deg/2;

nonzero = probability > 0;
entropy_normalized = -sum(probability(nonzero) .* ...
    log(probability(nonzero))) / log(numel(probability));
target_deg = cfg.source.target_angle_deg;
angular_distance_deg = abs(wrapTo180Local(bin_centres_deg - target_deg));
target_sector = angular_distance_deg <= ...
    cfg.diagnostics.directional_half_angle_deg;
target_concentration = sum(probability(target_sector));
[~, dominant_index] = max(probability);

mean_k_rad_m = sum(wavenumber(annulus) .* annular_energy) / ...
    sum(annular_energy);
spectral_speed_m_s = 2*pi*result.axes.f0_hz / mean_k_rad_m;

% This eigenvalue contrast describes whether one transverse displacement
% orientation dominates. It is descriptive, not the angular diffuseness
% acceptance metric, because a 2D diffuse shear field can still be locally
% polarized.
vector_samples = [ux(:), uz(:)];
coherency = vector_samples' * vector_samples;
eigenvalues = sort(real(eig(coherency)), 'descend');
polarization_coherence = (eigenvalues(1) - eigenvalues(2)) / ...
    max(sum(eigenvalues), realmin('double'));

% Complex vector coherence between nearest spatial neighbours is one for a
% perfect plane wave (the constant phase increment changes only its angle)
% and decreases when neighbouring vectors belong to unrelated wavefronts.
ux_left = reshape(ux(:, 1:end-1), [], 1);
ux_right = reshape(ux(:, 2:end), [], 1);
uz_left = reshape(uz(:, 1:end-1), [], 1);
uz_right = reshape(uz(:, 2:end), [], 1);
ux_upper = reshape(ux(1:end-1, :), [], 1);
ux_lower = reshape(ux(2:end, :), [], 1);
uz_upper = reshape(uz(1:end-1, :), [], 1);
uz_lower = reshape(uz(2:end, :), [], 1);
[coherence_x, weight_x] = pairCoherence( ...
    ux_left, uz_left, ux_right, uz_right);
[coherence_z, weight_z] = pairCoherence( ...
    ux_upper, uz_upper, ux_lower, uz_lower);
spatial_coherence = (weight_x*coherence_x + weight_z*coherence_z) / ...
    max(weight_x + weight_z, realmin('double'));

metrics = struct();
metrics.bin_centres_deg = bin_centres_deg;
metrics.bin_energy_normalized = probability;
metrics.entropy_normalized = entropy_normalized;
metrics.target_angle_deg = target_deg;
metrics.target_half_angle_deg = cfg.diagnostics.directional_half_angle_deg;
metrics.target_concentration = target_concentration;
metrics.dominant_angle_deg = bin_centres_deg(dominant_index);
metrics.reference_wavenumber_rad_m = reference_k_rad_m;
metrics.mean_wavenumber_rad_m = mean_k_rad_m;
metrics.spectral_speed_m_s = spectral_speed_m_s;
metrics.polarization_coherence = polarization_coherence;
metrics.nearest_neighbor_spatial_coherence = spatial_coherence;
metrics.lateral_neighbor_spatial_coherence = coherence_x;
metrics.axial_neighbor_spatial_coherence = coherence_z;
metrics.annulus_relative_halfwidth = relative_halfwidth;
metrics.kx_propagation_rad_m = -kx_fft_rad_m;
metrics.kz_propagation_rad_m = -kz_fft_rad_m;
metrics.energy_kspace = energy;
metrics.annulus_mask = annulus;
metrics.angle_convention = ...
    "0 deg = +x lateral; +90 deg = +z axial/depth";

end

function window = hannLocal(count)
if count == 1
    window = 1;
else
    index = (0:(count - 1)).';
    window = 0.5 - 0.5*cos(2*pi*index/(count - 1));
end
end

function angle = wrapTo180Local(angle)
angle = mod(angle + 180, 360) - 180;
end

function [coherence, weight] = pairCoherence(ux_a, uz_a, ux_b, uz_b)
inner_product = sum(conj(ux_a).*ux_b + conj(uz_a).*uz_b);
energy_a = sum(abs(ux_a).^2 + abs(uz_a).^2);
energy_b = sum(abs(ux_b).^2 + abs(uz_b).^2);
coherence = abs(inner_product) / sqrt(max( ...
    energy_a*energy_b, realmin('double')));
weight = sqrt(energy_a*energy_b);
end
