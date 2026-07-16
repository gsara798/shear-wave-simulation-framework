function metrics = symmetryMetrics(result)
%SYMMETRYMETRICS Measure expected symmetry about the axial source depth.
%
% For an axially polarized source in a medium symmetric about z_source,
% total U_z is even and total U_x is odd under z reflection. Only row pairs
% present on both sides of the recorded ROI are compared. Complex phasors
% are used so the metric tests amplitude and phase simultaneously.

arguments
    result struct
end

z_m = result.axes.z_m(:);
z_source_m = result.source.center_m_xz(2);
tolerance_m = 0.25 * result.axes.dz_m;
upper_rows = find(z_m < z_source_m - tolerance_m);
upper_used = zeros(0, 1);
lower_used = zeros(0, 1);

for index = 1:numel(upper_rows)
    upper = upper_rows(index);
    reflected_z_m = 2*z_source_m - z_m(upper);
    [distance_m, lower] = min(abs(z_m - reflected_z_m));
    if distance_m <= tolerance_m
        upper_used(end + 1, 1) = upper; %#ok<AGROW>
        lower_used(end + 1, 1) = lower; %#ok<AGROW>
    end
end

if isempty(upper_used)
    metrics = struct('axial_even_relative_error', NaN, ...
        'lateral_odd_relative_error', NaN, 'row_pair_count', 0, ...
        'upper_rows', upper_used, 'lower_rows', lower_used);
    return;
end

axial = result.fields.displacement.axial_total_zx;
lateral = result.fields.displacement.lateral_total_zx;
axial_upper = axial(upper_used, :);
axial_lower = axial(lower_used, :);
lateral_upper = lateral(upper_used, :);
lateral_lower = lateral(lower_used, :);

metrics = struct();
metrics.axial_even_relative_error = norm(axial_upper(:) - axial_lower(:)) / ...
    max(norm([axial_upper(:); axial_lower(:)]), eps);
metrics.lateral_odd_relative_error = norm(lateral_upper(:) + lateral_lower(:)) / ...
    max(norm([lateral_upper(:); lateral_lower(:)]), eps);
metrics.row_pair_count = numel(upper_used);
metrics.upper_rows = upper_used;
metrics.lower_rows = lower_used;

end
