function metrics = directionalFieldMetrics3D(result, options)
%DIRECTIONALFIELDMETRICS3D Measure modal purity, polarization, and symmetry.
%
% The expected field propagates nominally along +x and is excited with
% z-directed particle motion.
%
% Three polarization measurements are reported:
%
%   global:
%       Descriptive ratio over the amplitude-supported full sensor ROI.
%
%   core:
%       Acceptance ratio inside the directional beam core, beginning one
%       shear wavelength downstream from the source.
%
%   central_axis:
%       Descriptive ratio on the propagation line nearest the source center.
%
% Compressional leakage is evaluated globally as total P energy divided by
% total S energy.
%
% Reflection symmetry is evaluated about the nominal source center and about
% the best nearby effective center within a bounded sub-voxel search.

arguments
    result struct

    options.AmplitudeFloorFraction (1,1) double = 0.10

    options.CoreStartWavelengths (1,1) double = 1.0

    options.CoreHalfWidthWavelengths (1,1) double = 0.5

    options.SymmetryScanHalfWidthVoxels (1,1) double = 0.5

    options.SymmetryScanStepVoxels (1,1) double = 0.025
end

validateOptions(options);

fields = result.fields.harmonic_velocity;

required_names = [
    "x_shear_zyx"
    "y_shear_zyx"
    "z_shear_zyx"
    "x_compression_zyx"
    "y_compression_zyx"
    "z_compression_zyx"
];

reference_size = size(fields.z_shear_zyx);
finite_fields = true;

for field_name = required_names.'
    if ~isfield(fields, field_name)
        error("kwsim:Missing3DHarmonicField", ...
            "Missing harmonic field '%s'.", ...
            field_name);
    end

    values = fields.(field_name);

    if ~isequal(size(values), reference_size)
        error("kwsim:Inconsistent3DHarmonicFieldSize", ...
            "Harmonic field '%s' has an inconsistent size.", ...
            field_name);
    end

    finite_fields = ...
        finite_fields && ...
        all(isfinite(values), "all");
end

metrics = struct();
metrics.finite_fields = finite_fields;

metrics.global = emptyEnergySummary();
metrics.core = emptyEnergySummary();
metrics.central_axis = emptyEnergySummary();

metrics.symmetry = struct();
metrics.symmetry.y = emptySymmetrySummary();
metrics.symmetry.z = emptySymmetrySummary();

if ~finite_fields
    assignCompatibilityFields();
    return
end

cfg = result.config_resolved;

x_m = double(result.axes.x_m(:));
y_m = double(result.axes.y_m(:));
z_m = double(result.axes.z_m(:));

source_center_xyz = ...
    double(cfg.source.center_m_xyz);

lambda_s_m = ...
    cfg.medium.cs_m_s / ...
    cfg.source.f0_hz;

%% Global amplitude-supported field

global_geometry = ...
    true(reference_size);

global_support = amplitudeSupport( ...
    fields.z_shear_zyx, ...
    global_geometry, ...
    options.AmplitudeFloorFraction);

metrics.global = componentEnergySummary( ...
    fields, ...
    global_support);

metrics.global.region = ...
    "amplitude_supported_full_sensor_roi";

%% Directional core

[Z, Y, X] = ndgrid( ...
    z_m, ...
    y_m, ...
    x_m);

core_start_x_m = ...
    source_center_xyz(1) + ...
    options.CoreStartWavelengths * ...
    lambda_s_m;

core_half_width_m = ...
    options.CoreHalfWidthWavelengths * ...
    lambda_s_m;

core_geometry = ...
    X >= core_start_x_m & ...
    abs(Y - source_center_xyz(2)) <= core_half_width_m & ...
    abs(Z - source_center_xyz(3)) <= core_half_width_m;

core_support = amplitudeSupport( ...
    fields.z_shear_zyx, ...
    core_geometry, ...
    options.AmplitudeFloorFraction);

metrics.core = componentEnergySummary( ...
    fields, ...
    core_support);

metrics.core.region = ...
    "directional_core";

metrics.core.start_x_m = ...
    core_start_x_m;

metrics.core.start_wavelengths = ...
    options.CoreStartWavelengths;

metrics.core.transverse_half_width_m = ...
    core_half_width_m;

metrics.core.transverse_half_width_wavelengths = ...
    options.CoreHalfWidthWavelengths;

%% Central propagation axis

[~, y_center_index] = min(abs( ...
    y_m - source_center_xyz(2)));

[~, z_center_index] = min(abs( ...
    z_m - source_center_xyz(3)));

axis_x_mask = ...
    x_m >= core_start_x_m;

metrics.central_axis = axisEnergySummary( ...
    fields, ...
    z_center_index, ...
    y_center_index, ...
    axis_x_mask, ...
    options.AmplitudeFloorFraction);

metrics.central_axis.region = ...
    "central_propagation_axis";

metrics.central_axis.y_index = ...
    y_center_index;

metrics.central_axis.z_index = ...
    z_center_index;

metrics.central_axis.y_m = ...
    y_m(y_center_index);

metrics.central_axis.z_m = ...
    z_m(z_center_index);

metrics.central_axis.start_x_m = ...
    core_start_x_m;

%% Reflection symmetry

metrics.symmetry.y = scanEvenSymmetry( ...
    fields.z_shear_zyx, ...
    y_m, ...
    source_center_xyz(2), ...
    2, ...
    options.SymmetryScanHalfWidthVoxels, ...
    options.SymmetryScanStepVoxels);

metrics.symmetry.z = scanEvenSymmetry( ...
    fields.z_shear_zyx, ...
    z_m, ...
    source_center_xyz(3), ...
    1, ...
    options.SymmetryScanHalfWidthVoxels, ...
    options.SymmetryScanStepVoxels);

assignCompatibilityFields();

    function assignCompatibilityFields()
        % Compatibility fields used by the current evaluator.
        metrics.global_cross_polarization_ratio = ...
            metrics.global.cross_polarization_ratio;

        metrics.core_cross_polarization_ratio = ...
            metrics.core.cross_polarization_ratio;

        metrics.central_axis_cross_polarization_ratio = ...
            metrics.central_axis.cross_polarization_ratio;

        % The acceptance polarization metric is now the directional core.
        metrics.cross_polarization_ratio = ...
            metrics.core.cross_polarization_ratio;

        metrics.longitudinal_leakage_ratio = ...
            metrics.global.longitudinal_leakage_ratio;

        metrics.y_nominal_even_symmetry_error = ...
            metrics.symmetry.y.nominal_error;

        metrics.z_nominal_even_symmetry_error = ...
            metrics.symmetry.z.nominal_error;

        % Acceptance symmetry uses the best bounded effective center.
        metrics.y_even_symmetry_error = ...
            metrics.symmetry.y.best_error;

        metrics.z_even_symmetry_error = ...
            metrics.symmetry.z.best_error;

        metrics.y_symmetry_center_offset_voxels = ...
            metrics.symmetry.y.best_offset_voxels;

        metrics.z_symmetry_center_offset_voxels = ...
            metrics.symmetry.z.best_offset_voxels;

        metrics.maximum_symmetry_error = max( ...
            metrics.y_even_symmetry_error, ...
            metrics.z_even_symmetry_error);

        metrics.y_pair_count = ...
            metrics.symmetry.y.best_pair_count;

        metrics.z_pair_count = ...
            metrics.symmetry.z.best_pair_count;
    end

end


function validateOptions(options)

if options.AmplitudeFloorFraction <= 0 || ...
        options.AmplitudeFloorFraction > 1
    error("kwsim:InvalidAmplitudeFloor", ...
        "AmplitudeFloorFraction must lie in (0,1].");
end

if options.CoreStartWavelengths < 0
    error("kwsim:InvalidDirectionalCore", ...
        "CoreStartWavelengths must be nonnegative.");
end

if options.CoreHalfWidthWavelengths <= 0
    error("kwsim:InvalidDirectionalCore", ...
        "CoreHalfWidthWavelengths must be positive.");
end

if options.SymmetryScanHalfWidthVoxels < 0
    error("kwsim:InvalidSymmetryScan", ...
        "SymmetryScanHalfWidthVoxels must be nonnegative.");
end

if options.SymmetryScanStepVoxels <= 0
    error("kwsim:InvalidSymmetryScan", ...
        "SymmetryScanStepVoxels must be positive.");
end

end


function support = amplitudeSupport( ...
    reference_field, geometry_mask, floor_fraction)

support = false(size(reference_field));

available_amplitude = ...
    abs(reference_field(geometry_mask));

if isempty(available_amplitude)
    return
end

peak_amplitude = ...
    max(available_amplitude, [], "all");

if ~isfinite(peak_amplitude) || ...
        peak_amplitude <= 0
    return
end

support = ...
    geometry_mask & ...
    abs(reference_field) >= ...
        floor_fraction * peak_amplitude;

end


function summary = componentEnergySummary(fields, support)

summary = emptyEnergySummary();
summary.support_voxel_count = nnz(support);

if summary.support_voxel_count == 0
    return
end

summary.energy.x_shear = ...
    fieldEnergy(fields.x_shear_zyx, support);

summary.energy.y_shear = ...
    fieldEnergy(fields.y_shear_zyx, support);

summary.energy.z_shear = ...
    fieldEnergy(fields.z_shear_zyx, support);

summary.energy.x_compression = ...
    fieldEnergy(fields.x_compression_zyx, support);

summary.energy.y_compression = ...
    fieldEnergy(fields.y_compression_zyx, support);

summary.energy.z_compression = ...
    fieldEnergy(fields.z_compression_zyx, support);

summary.energy.total_shear = ...
    summary.energy.x_shear + ...
    summary.energy.y_shear + ...
    summary.energy.z_shear;

summary.energy.total_compression = ...
    summary.energy.x_compression + ...
    summary.energy.y_compression + ...
    summary.energy.z_compression;

summary.cross_polarization_ratio = ...
    (summary.energy.x_shear + ...
     summary.energy.y_shear) / ...
    max(summary.energy.z_shear, realmin);

summary.longitudinal_leakage_ratio = ...
    summary.energy.total_compression / ...
    max(summary.energy.total_shear, realmin);

end


function summary = axisEnergySummary( ...
    fields, z_index, y_index, x_mask, floor_fraction)

summary = emptyEnergySummary();

z_shear = reshape( ...
    fields.z_shear_zyx(z_index, y_index, x_mask), ...
    [], 1);

if isempty(z_shear)
    return
end

peak_amplitude = max(abs(z_shear));

if ~isfinite(peak_amplitude) || ...
        peak_amplitude <= 0
    return
end

usable = ...
    abs(z_shear) >= ...
    floor_fraction * peak_amplitude;

summary.support_voxel_count = nnz(usable);

if summary.support_voxel_count == 0
    return
end

x_shear = reshape( ...
    fields.x_shear_zyx(z_index, y_index, x_mask), ...
    [], 1);

y_shear = reshape( ...
    fields.y_shear_zyx(z_index, y_index, x_mask), ...
    [], 1);

x_compression = reshape( ...
    fields.x_compression_zyx(z_index, y_index, x_mask), ...
    [], 1);

y_compression = reshape( ...
    fields.y_compression_zyx(z_index, y_index, x_mask), ...
    [], 1);

z_compression = reshape( ...
    fields.z_compression_zyx(z_index, y_index, x_mask), ...
    [], 1);

summary.energy.x_shear = ...
    vectorEnergy(x_shear(usable));

summary.energy.y_shear = ...
    vectorEnergy(y_shear(usable));

summary.energy.z_shear = ...
    vectorEnergy(z_shear(usable));

summary.energy.x_compression = ...
    vectorEnergy(x_compression(usable));

summary.energy.y_compression = ...
    vectorEnergy(y_compression(usable));

summary.energy.z_compression = ...
    vectorEnergy(z_compression(usable));

summary.energy.total_shear = ...
    summary.energy.x_shear + ...
    summary.energy.y_shear + ...
    summary.energy.z_shear;

summary.energy.total_compression = ...
    summary.energy.x_compression + ...
    summary.energy.y_compression + ...
    summary.energy.z_compression;

summary.cross_polarization_ratio = ...
    (summary.energy.x_shear + ...
     summary.energy.y_shear) / ...
    max(summary.energy.z_shear, realmin);

summary.longitudinal_leakage_ratio = ...
    summary.energy.total_compression / ...
    max(summary.energy.total_shear, realmin);

end


function summary = scanEvenSymmetry( ...
    field_zyx, axis_m, nominal_center_m, dimension, ...
    half_width_voxels, step_voxels)

summary = emptySymmetrySummary();

axis_m = double(axis_m(:));

if numel(axis_m) < 2
    return
end

spacing_m = median(diff(axis_m));

offset_count = max( ...
    round(2 * half_width_voxels / step_voxels), ...
    1);

offsets_voxels = linspace( ...
    -half_width_voxels, ...
    half_width_voxels, ...
    offset_count + 1).';

errors = NaN(size(offsets_voxels));
pair_counts = zeros(size(offsets_voxels));

for index = 1:numel(offsets_voxels)
    candidate_center_m = ...
        nominal_center_m + ...
        offsets_voxels(index) * spacing_m;

    [errors(index), pair_counts(index)] = ...
        evenSymmetryAtCenter( ...
            field_zyx, ...
            axis_m, ...
            candidate_center_m, ...
            dimension);
end

[~, nominal_index] = ...
    min(abs(offsets_voxels));

summary.nominal_error = ...
    errors(nominal_index);

summary.nominal_pair_count = ...
    pair_counts(nominal_index);

finite_candidates = find(isfinite(errors));

if isempty(finite_candidates)
    summary.offsets_voxels = offsets_voxels;
    summary.errors = errors;
    summary.pair_counts = pair_counts;
    return
end

[best_error, local_index] = ...
    min(errors(finite_candidates));

best_index = ...
    finite_candidates(local_index);

summary.best_error = ...
    best_error;

summary.best_offset_voxels = ...
    offsets_voxels(best_index);

summary.best_offset_m = ...
    offsets_voxels(best_index) * spacing_m;

summary.best_center_m = ...
    nominal_center_m + ...
    summary.best_offset_m;

summary.best_pair_count = ...
    pair_counts(best_index);

summary.offsets_voxels = ...
    offsets_voxels;

summary.errors = ...
    errors;

summary.pair_counts = ...
    pair_counts;

end


function [relative_error, pair_count] = ...
    evenSymmetryAtCenter( ...
        field_zyx, axis_m, center_m, dimension)

switch dimension
    case 1
        field_matrix = reshape( ...
            field_zyx, ...
            size(field_zyx, 1), ...
            []);

    case 2
        reordered = permute( ...
            field_zyx, ...
            [2, 1, 3]);

        field_matrix = reshape( ...
            reordered, ...
            size(reordered, 1), ...
            []);

    otherwise
        error("kwsim:InvalidReflectionDimension", ...
            "Reflection dimension must be 1 or 2.");
end

spacing_m = median(diff(axis_m));

lower_indices = find( ...
    axis_m < center_m - 0.1 * spacing_m);

reflected_positions_m = ...
    2 * center_m - ...
    axis_m(lower_indices);

valid = ...
    reflected_positions_m >= min(axis_m) & ...
    reflected_positions_m <= max(axis_m);

lower_indices = ...
    lower_indices(valid);

reflected_positions_m = ...
    reflected_positions_m(valid);

pair_count = ...
    numel(lower_indices);

if pair_count == 0
    relative_error = NaN;
    return
end

lower_values = ...
    field_matrix(lower_indices, :);

reflected_values = interp1( ...
    axis_m, ...
    field_matrix, ...
    reflected_positions_m, ...
    "linear");

relative_error = ...
    norm(lower_values(:) - reflected_values(:)) / ...
    max(norm([ ...
        lower_values(:); ...
        reflected_values(:)]), ...
        realmin);

end


function energy = fieldEnergy(field, support)

energy = vectorEnergy( ...
    field(support));

end


function energy = vectorEnergy(values)

energy = double(sum( ...
    abs(values).^2, ...
    "all"));

end


function summary = emptyEnergySummary()

summary = struct();

summary.region = "";
summary.support_voxel_count = 0;

summary.cross_polarization_ratio = NaN;
summary.longitudinal_leakage_ratio = NaN;

summary.energy = struct();

summary.energy.x_shear = NaN;
summary.energy.y_shear = NaN;
summary.energy.z_shear = NaN;

summary.energy.x_compression = NaN;
summary.energy.y_compression = NaN;
summary.energy.z_compression = NaN;

summary.energy.total_shear = NaN;
summary.energy.total_compression = NaN;

end


function summary = emptySymmetrySummary()

summary = struct();

summary.nominal_error = NaN;
summary.nominal_pair_count = 0;

summary.best_error = NaN;
summary.best_offset_voxels = NaN;
summary.best_offset_m = NaN;
summary.best_center_m = NaN;
summary.best_pair_count = 0;

summary.offsets_voxels = [];
summary.errors = [];
summary.pair_counts = [];

end
