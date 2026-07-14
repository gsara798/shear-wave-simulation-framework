function estimate = estimateAttenuation(attenuated, lossless)
%ESTIMATEATTENUATION Recover shear attenuation from a matched lossless run.
%
% estimate = kwsim.diagnostics.estimateAttenuation(attenuated, lossless)
%
% Both inputs must describe the same monofrequency source, grid, seed, and
% sensor ROI. Geometric spreading is cancelled by the pointwise amplitude
% ratio. A narrow strip around the source depth is RMS-averaged before
% fitting attenuation loss in dB against lateral propagation distance in
% cm. The full vector shear magnitude defines the fit; the axial-only
% estimate is retained as a secondary ultrasound-like measurement.

arguments
    attenuated struct
    lossless struct
end

verifyMatchedRuns(attenuated, lossless);
cfg = attenuated.config_resolved;
source_z_m = attenuated.source.center_m_xz(2);
half_width_m = cfg.diagnostics.attenuation_fit_half_width_m;
rows = find(abs(attenuated.axes.z_m - source_z_m) <= half_width_m);
if isempty(rows)
    [~, rows] = min(abs(attenuated.axes.z_m - source_z_m));
end

loss_vector = vectorShearAmplitude(lossless);
atten_vector = vectorShearAmplitude(attenuated);
loss_axial = abs(lossless.fields.velocity.axial_shear_zx);
atten_axial = abs(attenuated.fields.velocity.axial_shear_zx);

loss_vector_profile = sqrt(mean(loss_vector(rows,:).^2, 1));
atten_vector_profile = sqrt(mean(atten_vector(rows,:).^2, 1));
loss_axial_profile = sqrt(mean(loss_axial(rows,:).^2, 1));
atten_axial_profile = sqrt(mean(atten_axial(rows,:).^2, 1));

distance_cm = (attenuated.axes.x_m - attenuated.source.center_m_xz(1))*100;
[vector_fit, usable] = fitProfile(distance_cm, loss_vector_profile, ...
    atten_vector_profile, cfg);
[axial_fit, ~] = fitProfile(distance_cm, loss_axial_profile, ...
    atten_axial_profile, cfg, usable);

loss_db_map = 20*log10(max(loss_vector, realmin)./max(atten_vector, realmin));
lossless_speed = kwsim.diagnostics.estimateShearSpeed( ...
    lossless.fields.velocity.axial_shear_zx, lossless.axes.x_m, ...
    lossless.axes.z_m, source_z_m, lossless.axes.f0_hz);
attenuated_speed = kwsim.diagnostics.estimateShearSpeed( ...
    attenuated.fields.velocity.axial_shear_zx, attenuated.axes.x_m, ...
    attenuated.axes.z_m, source_z_m, attenuated.axes.f0_hz);
speed_difference = abs(attenuated_speed.speed_m_s - lossless_speed.speed_m_s) / ...
    max(abs(lossless_speed.speed_m_s), realmin);

estimate = struct();
estimate.frequency_hz = attenuated.axes.f0_hz;
estimate.vector_shear = vector_fit;
estimate.axial_shear = axial_fit;
estimate.loss_db_zx = loss_db_map;
estimate.fit_rows = rows;
estimate.fit_z_m = attenuated.axes.z_m(rows);
estimate.distance_cm = distance_cm;
estimate.lossless_vector_profile_m_s = loss_vector_profile;
estimate.attenuated_vector_profile_m_s = atten_vector_profile;
estimate.lossless_axial_profile_m_s = loss_axial_profile;
estimate.attenuated_axial_profile_m_s = atten_axial_profile;
estimate.lossless_speed = lossless_speed;
estimate.attenuated_speed = attenuated_speed;
estimate.speed_relative_difference = speed_difference;
estimate.units = struct('attenuation', "dB/cm", 'distance', "cm", ...
    'profile', "m/s");

end

function amplitude = vectorShearAmplitude(result)
velocity = result.fields.velocity;
amplitude = sqrt(abs(velocity.lateral_shear_zx).^2 + ...
    abs(velocity.axial_shear_zx).^2);
end

function [fit, usable] = fitProfile(distance_cm, lossless_profile, ...
        attenuated_profile, cfg, prescribed_usable)
relative_floor = cfg.diagnostics.attenuation_fit_relative_amplitude_floor;
usable = distance_cm > 0 & isfinite(lossless_profile) & ...
    isfinite(attenuated_profile) & lossless_profile > 0 & ...
    attenuated_profile > 0 & ...
    lossless_profile >= relative_floor*max(lossless_profile);
downstream_wavelengths = 1.5;
if isfield(cfg.diagnostics, 'attenuation_fit_downstream_wavelengths')
    downstream_wavelengths = ...
        cfg.diagnostics.attenuation_fit_downstream_wavelengths;
end
downstream_buffer_cm = downstream_wavelengths * ...
    cfg.derived.shear_wavelength_m * 100;
usable = usable & distance_cm <= max(distance_cm) - downstream_buffer_cm;
if nargin >= 5
    usable = usable & prescribed_usable;
end
attenuation_db = 20*log10(max(lossless_profile, realmin)./ ...
    max(attenuated_profile, realmin));

if nnz(usable) < 2
    fit = emptyFit(nnz(usable));
    return;
end
x = double(distance_cm(usable).');
y = double(attenuation_db(usable).');
design = [x, ones(size(x))];
coefficients = design\y;
prediction = design*coefficients;
residual_sum = sum((y - prediction).^2);
total_sum = sum((y - mean(y)).^2);

fit = struct();
fit.attenuation_db_cm = coefficients(1);
fit.intercept_db = coefficients(2);
fit.r_squared = 1 - residual_sum/max(total_sum, realmin);
fit.usable_points = nnz(usable);
fit.distance_cm = x;
fit.measured_loss_db = y;
fit.predicted_loss_db = prediction;
fit.residual_rms_db = sqrt(mean((y - prediction).^2));
fit.usable_mask = usable;
end

function fit = emptyFit(usable_points)
fit = struct('attenuation_db_cm', NaN, 'intercept_db', NaN, ...
    'r_squared', NaN, 'usable_points', usable_points, ...
    'distance_cm', [], 'measured_loss_db', [], ...
    'predicted_loss_db', [], 'residual_rms_db', NaN, ...
    'usable_mask', false(1,0));
end

function verifyMatchedRuns(attenuated, lossless)
same_axes = isequal(attenuated.axes.x_m, lossless.axes.x_m) && ...
    isequal(attenuated.axes.z_m, lossless.axes.z_m) && ...
    attenuated.axes.f0_hz == lossless.axes.f0_hz;
same_source = attenuated.config_resolved.seed == lossless.config_resolved.seed && ...
    isequal(attenuated.source.mask_zx, lossless.source.mask_zx) && ...
    isequal(attenuated.source.waveform_m_s, lossless.source.waveform_m_s);
if ~same_axes || ~same_source
    error('kwsim:UnmatchedAttenuationPair', ...
        'Attenuated and lossless runs must use identical axes and source realization.');
end
end
