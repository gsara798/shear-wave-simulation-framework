function estimate = estimateDirectionalSpeed3D(result, options)
%ESTIMATEDIRECTIONALSPEED3D Estimate shear speed along the +x beam axis.
%
% The diagnostic uses the z-polarized shear field on the transverse line
% nearest the source center. Phase is unwrapped along x and fitted using
% amplitude-squared weighted least squares.
%
% This estimator is intended for a homogeneous field propagating primarily
% along +x with polarization along z.

arguments
    result struct
    options.AmplitudeFloorFraction (1,1) double = 0.20
    options.MinimumPoints (1,1) double {mustBeInteger, mustBePositive} = 8
end

if options.AmplitudeFloorFraction <= 0 || ...
        options.AmplitudeFloorFraction > 1
    error("kwsim:InvalidAmplitudeFloor", ...
        "AmplitudeFloorFraction must lie in (0,1].");
end

cfg = result.config_resolved;

field_zyx = ...
    result.fields.harmonic_velocity.z_shear_zyx;

x_m = double(result.axes.x_m(:));
y_m = double(result.axes.y_m(:));
z_m = double(result.axes.z_m(:));

source_center_xyz = ...
    double(cfg.source.center_m_xyz);

[~, y_index] = min(abs( ...
    y_m - source_center_xyz(2)));

[~, z_index] = min(abs( ...
    z_m - source_center_xyz(3)));

line_phasor = reshape( ...
    field_zyx(z_index, y_index, :), ...
    [], 1);

if numel(line_phasor) ~= numel(x_m)
    error("kwsim:Unexpected3DFieldSize", ...
        "The x-axis length does not match the harmonic field.");
end

amplitude = abs(line_phasor);
peak_amplitude = max(amplitude);

usable = ...
    isfinite(line_phasor) & ...
    amplitude >= ...
        options.AmplitudeFloorFraction * peak_amplitude;

if peak_amplitude <= 0 || ...
        nnz(usable) < options.MinimumPoints
    estimate = emptyEstimate( ...
        y_index, z_index, nnz(usable));

    estimate.line_phasor = line_phasor;
    estimate.amplitude = amplitude;
    estimate.usable_mask = usable;
    return
end

phase_rad = unwrap(angle(line_phasor));

x_fit_m = x_m(usable);
phase_fit_rad = double(phase_rad(usable));

weights = double(amplitude(usable)).^2;
weights = weights / max(weights);

design = [
    x_fit_m, ...
    ones(size(x_fit_m))
];

square_root_weights = sqrt(weights);

weighted_design = ...
    design .* square_root_weights;

weighted_phase = ...
    phase_fit_rad .* square_root_weights;

coefficients = ...
    weighted_design \ weighted_phase;

phase_prediction_rad = ...
    design * coefficients;

weighted_mean_phase = ...
    sum(weights .* phase_fit_rad) / ...
    sum(weights);

residual_sum = sum( ...
    weights .* ...
    (phase_fit_rad - phase_prediction_rad).^2);

total_sum = sum( ...
    weights .* ...
    (phase_fit_rad - weighted_mean_phase).^2);

slope_rad_m = coefficients(1);
wavenumber_rad_m = abs(slope_rad_m);

estimate = struct();

estimate.speed_m_s = ...
    2*pi*cfg.source.f0_hz / ...
    wavenumber_rad_m;

estimate.wavenumber_rad_m = ...
    wavenumber_rad_m;

estimate.wavelength_m = ...
    2*pi / wavenumber_rad_m;

estimate.slope_rad_m = ...
    slope_rad_m;

estimate.intercept_rad = ...
    coefficients(2);

estimate.r_squared = ...
    1 - residual_sum / ...
    max(total_sum, realmin);

estimate.y_index = y_index;
estimate.z_index = z_index;

estimate.y_m = y_m(y_index);
estimate.z_m = z_m(z_index);

estimate.usable_points = nnz(usable);
estimate.usable_mask = usable;

estimate.x_m = x_m;
estimate.line_phasor = line_phasor;
estimate.amplitude = amplitude;
estimate.phase_unwrapped_rad = phase_rad;

estimate.x_fit_m = x_fit_m;
estimate.phase_fit_rad = phase_fit_rad;
estimate.phase_prediction_rad = ...
    phase_prediction_rad;

end


function estimate = emptyEstimate( ...
    y_index, z_index, usable_points)

estimate = struct();

estimate.speed_m_s = NaN;
estimate.wavenumber_rad_m = NaN;
estimate.wavelength_m = NaN;
estimate.slope_rad_m = NaN;
estimate.intercept_rad = NaN;
estimate.r_squared = NaN;

estimate.y_index = y_index;
estimate.z_index = z_index;
estimate.y_m = NaN;
estimate.z_m = NaN;

estimate.usable_points = usable_points;
estimate.usable_mask = [];

estimate.x_m = [];
estimate.line_phasor = [];
estimate.amplitude = [];
estimate.phase_unwrapped_rad = [];
estimate.x_fit_m = [];
estimate.phase_fit_rad = [];
estimate.phase_prediction_rad = [];

end
