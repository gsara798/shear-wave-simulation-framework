function metrics = contactMetrics(result)
%CONTACTMETRICS Quantify the realized geometry of a finite-contact source bank.
%
% metrics = kwsim.analysis.contactMetrics(result)
%
% A physical finite vibrator may own several solver labels. This diagnostic
% verifies the distinction explicitly: contact-node spacing, realized span,
% profile symmetry, center alignment, and drive contribution are evaluated
% per physical vibrator. Coordinates use internal index pairs only to measure
% distances; reported lengths are in metres.

arguments
    result struct
end

cfg = result.config_resolved;
source = result.source;
vibrators = source.vibrators;
count = numel(vibrators);
node_count = zeros(count, 1);
effective_node_count = zeros(count, 1);
span_m = zeros(count, 1);
minimum_spacing_points = inf(count, 1);
profile_symmetry_error = zeros(count, 1);
profile_center_offset_points = zeros(count, 1);
drive_fraction_error = zeros(count, 1);

for index = 1:count
    vibrator = vibrators(index);
    weights = vibrator.contact_node_weights(:);
    node_count(index) = vibrator.contact_node_count;
    effective_node_count(index) = vibrator.effective_contact_node_count;
    span_m(index) = vibrator.realized_contact_span_m;
    profile_symmetry_error(index) = norm(weights - flip(weights)) / ...
        max(norm(weights), realmin('double'));

    [node_x, node_z] = ind2sub([cfg.grid.Nx, cfg.grid.Nz], ...
        vibrator.contact_node_indices);
    tangent_coordinate = node_x*vibrator.contact_tangent_xz(1) + ...
        node_z*vibrator.contact_tangent_xz(2);
    tangent_coordinate = sort(tangent_coordinate(:));
    if numel(tangent_coordinate) > 1
        minimum_spacing_points(index) = min(diff(tangent_coordinate));
    end
    weighted_center = sum(weights.*tangent_coordinate) / sum(weights);
    geometric_center = vibrator.center_index_xz * ...
        vibrator.contact_tangent_xz.';
    profile_center_offset_points(index) = abs(weighted_center - geometric_center);
    realized_fraction = vibrator.prescribed_drive_rms_squared_m2_s2 / ...
        source.realized_drive_rms_squared_m2_s2;
    drive_fraction_error(index) = abs( ...
        realized_fraction - vibrator.drive_power_weight);
end

if lower(string(source.contact_model)) == "finite_segment"
    requested_span_m = 2*cfg.source.contact_radius_m;
    span_relative_error = abs(span_m - requested_span_m) / requested_span_m;
else
    requested_span_m = 0;
    span_relative_error = zeros(size(span_m));
end

metrics = struct();
metrics.contact_model = string(source.contact_model);
metrics.contact_profile = string(source.contact_profile);
metrics.physical_vibrator_count = count;
metrics.solver_channel_count = source.solver_channel_count;
metrics.contact_node_count = node_count;
metrics.effective_contact_node_count = effective_node_count;
metrics.requested_contact_span_m = requested_span_m;
metrics.realized_contact_span_m = span_m;
metrics.maximum_span_relative_error = max(span_relative_error);
metrics.minimum_node_spacing_points = min(minimum_spacing_points);
metrics.maximum_profile_symmetry_error = max(profile_symmetry_error);
metrics.maximum_profile_center_offset_points = ...
    max(profile_center_offset_points);
metrics.maximum_drive_fraction_error = max(drive_fraction_error);

end
