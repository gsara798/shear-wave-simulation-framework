function validation = evaluateStage2Results(contrast, contrast_report, ...
        homogeneous, homogeneous_report, zero_contrast, zero_report, base_cfg)
%EVALUATESTAGE2RESULTS Evaluate existing Stage 2 comparison simulations.
%
% This function performs no simulation. It is intentionally separate from
% runStage2Validation so diagnostic definitions can be corrected or extended
% without spending solver time or altering the saved physical fields.

arguments
    contrast struct
    contrast_report struct
    homogeneous struct
    homogeneous_report struct
    zero_contrast struct
    zero_report struct
    base_cfg struct
end

contrast_field = contrast.fields.displacement.axial_total_zx;
homogeneous_field = homogeneous.fields.displacement.axial_total_zx;
zero_field = zero_contrast.fields.displacement.axial_total_zx;
zero_contrast_error = relativeDifference(homogeneous_field, zero_field);
contrast_effect = relativeDifference(homogeneous_field, contrast_field);

inclusion_center_z_m = base_cfg.geometry.objects(1).center_m_xz(2);
[energy_symmetry_error, mirror_correlation, pointwise_symmetry_error] = ...
    scatteredSymmetryMetrics(abs(contrast_field - homogeneous_field), ...
    contrast.axes.z_m, inclusion_center_z_m, contrast.axes.dz_m);

object_info = contrast.truth.geometry.objects;
if isempty(object_info)
    maximum_area_error = NaN;
else
    maximum_area_error = max([object_info.area_relative_error]);
end
material_assignment_exact = verifyMaterialAssignments(contrast);

checks = repmat(emptyCheck(), 0, 1);
addCheck("contrast_run_valid", contrast_report.valid, ...
    double(contrast_report.valid), 1);
addCheck("homogeneous_reference_valid", homogeneous_report.valid, ...
    double(homogeneous_report.valid), 1);
addCheck("zero_contrast_run_valid", zero_report.valid, ...
    double(zero_report.valid), 1);
addCheck("geometry_area_relative_error", maximum_area_error <= ...
    base_cfg.diagnostics.maximum_geometry_area_relative_error, ...
    maximum_area_error, ...
    base_cfg.diagnostics.maximum_geometry_area_relative_error);
addCheck("material_assignment_exact", material_assignment_exact, ...
    double(material_assignment_exact), 1);
addCheck("zero_contrast_relative_error", zero_contrast_error <= ...
    base_cfg.diagnostics.maximum_zero_contrast_relative_error, ...
    zero_contrast_error, ...
    base_cfg.diagnostics.maximum_zero_contrast_relative_error);
addCheck("scattered_energy_axial_symmetry", energy_symmetry_error <= ...
    base_cfg.diagnostics.maximum_axial_symmetry_error, ...
    energy_symmetry_error, ...
    base_cfg.diagnostics.maximum_axial_symmetry_error);

validation = struct();
validation.stage = 2;
validation.valid = all([checks.pass]);
validation.checks = checks;
validation.metrics = struct();
validation.metrics.zero_contrast_relative_error = zero_contrast_error;
validation.metrics.contrast_effect_relative_difference = contrast_effect;
validation.metrics.maximum_area_relative_error = maximum_area_error;
validation.metrics.material_assignment_exact = material_assignment_exact;
validation.metrics.axial_symmetry_error = energy_symmetry_error;
validation.metrics.scattered_mirror_correlation = mirror_correlation;
validation.metrics.scattered_pointwise_symmetry_error = pointwise_symmetry_error;
validation.metrics.total_field_complex_axial_symmetry_error = ...
    contrast_report.metrics.symmetry.axial_even_relative_error;
validation.metrics.lateral_antisymmetry_error = ...
    contrast_report.metrics.symmetry.lateral_odd_relative_error;
validation.reports = struct('contrast', contrast_report, ...
    'homogeneous', homogeneous_report, 'zero_contrast', zero_report);
validation.results = struct('contrast', contrast, ...
    'homogeneous', homogeneous, 'zero_contrast', zero_contrast);
validation.configurations = struct('contrast', contrast.config_resolved, ...
    'homogeneous', homogeneous.config_resolved, ...
    'zero_contrast', zero_contrast.config_resolved);
validation.summary = sprintf([ ...
    'valid=%d, area error=%.3f%%, zero-contrast error=%.3g, ', ...
    'axial energy imbalance=%.3f%%, mirror correlation=%.6f, ', ...
    'contrast effect=%.3f%%'], validation.valid, 100*maximum_area_error, ...
    zero_contrast_error, 100*energy_symmetry_error, mirror_correlation, ...
    100*contrast_effect);

    function addCheck(name, pass, value, threshold)
        check = emptyCheck();
        check.name = string(name);
        check.pass = logical(pass);
        check.value = double(value);
        check.threshold = double(threshold);
        checks(end + 1, 1) = check;
    end

end

function [energy_imbalance, mirror_correlation, pointwise_error] = ...
        scatteredSymmetryMetrics(amplitude_zx, z_m, center_z_m, dz_m)
%SCATTEREDSYMMETRYMETRICS Compare mirrored inclusion-induced amplitudes.
z_m = z_m(:);
upper_rows = find(z_m < center_z_m - 0.1*dz_m);
upper_used = zeros(0, 1);
lower_used = zeros(0, 1);
for index = 1:numel(upper_rows)
    reflected_z_m = 2*center_z_m - z_m(upper_rows(index));
    [distance_m, lower] = min(abs(z_m - reflected_z_m));
    if distance_m <= 0.25*dz_m
        upper_used(end + 1, 1) = upper_rows(index); %#ok<AGROW>
        lower_used(end + 1, 1) = lower; %#ok<AGROW>
    end
end
upper = amplitude_zx(upper_used, :);
lower = amplitude_zx(lower_used, :);
upper_energy = sum(abs(upper).^2, 'all');
lower_energy = sum(abs(lower).^2, 'all');

% realmin, rather than eps, is essential here: displacement energy is often
% around 1e-18 m^2, far below double-precision eps but far above underflow.
energy_imbalance = abs(upper_energy - lower_energy) / ...
    max(upper_energy + lower_energy, realmin);
mirror_correlation = (upper(:)' * lower(:)) / ...
    max(norm(upper(:))*norm(lower(:)), realmin);
pointwise_error = norm(upper(:) - lower(:)) / ...
    max(norm([upper(:); lower(:)]), realmin);
end

function exact = verifyMaterialAssignments(result)
exact = true;
material_map = result.truth.material_id_zx;
for object = result.config_resolved.geometry.objects.'
    mask = material_map == object.material_id;
    exact = exact && any(mask, 'all') && ...
        all(result.truth.cs_m_s_zx(mask) == object.cs_m_s) && ...
        all(result.truth.rho_kg_m3_zx(mask) == object.rho_kg_m3) && ...
        all(result.truth.cp_m_s_zx(mask) == result.config_resolved.medium.cp_m_s);
end
background = material_map == 1;
exact = exact && all(result.truth.cs_m_s_zx(background) == ...
    result.config_resolved.medium.cs_m_s) && ...
    all(result.truth.rho_kg_m3_zx(background) == ...
    result.config_resolved.medium.rho_kg_m3);
end

function value = relativeDifference(reference, candidate)
value = norm(candidate(:) - reference(:)) / max(norm(reference(:)), realmin);
end

function check = emptyCheck()
check = struct('name', "", 'pass', false, 'value', NaN, 'threshold', NaN);
end
