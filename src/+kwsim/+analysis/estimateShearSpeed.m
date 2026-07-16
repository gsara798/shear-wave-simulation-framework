function estimate = estimateShearSpeed(axial_shear_phasor_zx, x_m, z_m, source_z_m, f0_hz)
%ESTIMATESHEARSPEED Estimate phase velocity along the directional beam axis.
%
% The center-depth row is selected, low-amplitude samples are rejected, and
% unwrapped phase is fitted against lateral distance. This diagnostic is
% intended for the homogeneous directional benchmark, not heterogeneous or
% diffuse fields.

arguments
    axial_shear_phasor_zx {mustBeNumeric}
    x_m {mustBeNumeric, mustBeVector}
    z_m {mustBeNumeric, mustBeVector}
    source_z_m (1,1) double
    f0_hz (1,1) double {mustBePositive}
end

[~, row] = min(abs(z_m - source_z_m));
line_phasor = axial_shear_phasor_zx(row, :);
amplitude = abs(line_phasor);
usable = amplitude >= 0.20 * max(amplitude);

if nnz(usable) < 8
    estimate = struct('speed_m_s', NaN, 'slope_rad_m', NaN, ...
        'r_squared', NaN, 'row_index', row, 'usable_points', nnz(usable));
    return;
end

phase = unwrap(angle(line_phasor));
x_fit = double(x_m(usable).');
phase_fit = double(phase(usable).');
coefficients = [x_fit, ones(size(x_fit))] \ phase_fit;
prediction = [x_fit, ones(size(x_fit))] * coefficients;
residual_sum = sum((phase_fit - prediction).^2);
total_sum = sum((phase_fit - mean(phase_fit)).^2);

estimate = struct();
estimate.speed_m_s = 2*pi*f0_hz / abs(coefficients(1));
estimate.slope_rad_m = coefficients(1);
estimate.r_squared = 1 - residual_sum / max(total_sum, eps);
estimate.row_index = row;
estimate.usable_points = nnz(usable);
estimate.x_fit_m = x_fit;
estimate.phase_fit_rad = phase_fit;
estimate.phase_prediction_rad = prediction;

end
