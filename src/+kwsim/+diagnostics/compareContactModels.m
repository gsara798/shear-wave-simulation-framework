function comparison = compareContactModels(point_result, finite_result)
%COMPARECONTACTMODELS Compare point and finite contacts on their common ROI.
%
% comparison = kwsim.diagnostics.compareContactModels(point, finite)
%
% The function performs no simulations. It intersects the physical x and z
% axes exactly and compares the complex measured axial-displacement phasors.
% An optimal complex scale removes the trivial amplitude/phase factor before
% reporting waveform-shape error. This is a diagnostic of model sensitivity,
% not an assertion that a finite contact must reproduce a point source.

arguments
    point_result struct
    finite_result struct
end

if lower(string(point_result.source.contact_model)) ~= "point" || ...
        lower(string(finite_result.source.contact_model)) ~= "finite_segment"
    error('kwsim:ContactComparisonOrder', ...
        'Inputs must be point_result followed by finite_result.');
end
if point_result.axes.f0_hz ~= finite_result.axes.f0_hz
    error('kwsim:ContactComparisonFrequency', ...
        'Contact models must use the same frequency.');
end

[x_common_m, point_x, finite_x] = intersect( ...
    point_result.axes.x_m, finite_result.axes.x_m, 'stable');
[z_common_m, point_z, finite_z] = intersect( ...
    point_result.axes.z_m, finite_result.axes.z_m, 'stable');
if numel(x_common_m) < 4 || numel(z_common_m) < 4
    error('kwsim:ContactComparisonROI', ...
        'Point and finite simulations do not share a sufficient physical ROI.');
end

point_field = point_result.fields.displacement.axial_total_zx( ...
    point_z, point_x);
finite_field = finite_result.fields.displacement.axial_total_zx( ...
    finite_z, finite_x);
point_vector = point_field(:);
finite_vector = finite_field(:);
denominator = max(norm(point_vector)*norm(finite_vector), realmin('double'));
complex_correlation = (point_vector'*finite_vector)/denominator;
optimal_scale = (point_vector'*finite_vector) / ...
    max(point_vector'*point_vector, realmin('double'));
shape_error = norm(finite_vector - optimal_scale*point_vector) / ...
    max(norm(finite_vector), realmin('double'));

comparison = struct();
comparison.x_common_m = x_common_m;
comparison.z_common_m = z_common_m;
comparison.complex_correlation = complex_correlation;
comparison.correlation_magnitude = abs(complex_correlation);
comparison.optimal_finite_over_point_complex_scale = optimal_scale;
comparison.optimal_scaled_shape_relative_error = shape_error;
comparison.rms_amplitude_ratio_finite_to_point = ...
    sqrt(mean(abs(finite_vector).^2)) / max( ...
    sqrt(mean(abs(point_vector).^2)), realmin('double'));
comparison.point_contact_span_m = 0;
comparison.finite_contact_span_m = ...
    finite_result.diagnostics.metrics.contact.requested_contact_span_m;
comparison.definition = ...
    "Complex axial total displacement compared on the exact common ROI.";

end
