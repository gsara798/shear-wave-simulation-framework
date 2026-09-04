function validation = validate(base_cfg)
%VALIDATE Run cross-simulation directional homogeneous reliability checks.
%
% validation = kwsim_benchmarks.directional_homogeneous_2d.validate(base_cfg)
%
% Four simulations are performed: baseline, exact repeat, 25% finer grid,
% and a physically larger lateral domain. The suite measures deterministic
% repeatability, complex field correlation across grids, shear-speed
% convergence, and sensitivity to reflections from the absorbing boundary.
% Use the compact configuration supplied in
% examples/two_d for routine validation; the full 96-by-96 default is more
% expensive but follows the same contract.

arguments
    base_cfg struct = kwsim_benchmarks.directional_homogeneous_2d.config()
end

base_cfg.diagnostics.fail_on_invalid = false;
base_cfg.output.directory = "";
base_cfg.output.save_time_series = false;

[baseline, baseline_report] = kwsim.two_d.run(base_cfg);
[repeated, repeated_report] = kwsim.two_d.run(base_cfg);

fine_cfg = base_cfg;
refinement = 1.25;
length_x_m = (base_cfg.grid.Nx - 1) * base_cfg.grid.dx_m;
length_z_m = (base_cfg.grid.Nz - 1) * base_cfg.grid.dz_m;
fine_cfg.grid.dx_m = base_cfg.grid.dx_m / refinement;
fine_cfg.grid.dz_m = base_cfg.grid.dz_m / refinement;
fine_cfg.grid.Nx = round(length_x_m / fine_cfg.grid.dx_m) + 1;
fine_cfg.grid.Nz = round(length_z_m / fine_cfg.grid.dz_m) + 1;
[fine, fine_report] = kwsim.two_d.run(fine_cfg);

domain_cfg = base_cfg;
% Extend the domain downstream while preserving the source and all baseline
% sample coordinates. This is a cleaner PML test than changing PMLSize,
% because changing the exterior FFT grid can itself perturb the solution.
domain_cfg.grid.Nx = base_cfg.grid.Nx + max(16, ceil(base_cfg.grid.Nx / 4));
[domain_reference, domain_report] = kwsim.two_d.run(domain_cfg);

base_field = baseline.fields.velocity.axial_shear_zx;
repeat_field = repeated.fields.velocity.axial_shear_zx;
repeat_error = relativeDifference(base_field, repeat_field);

fine_on_base = interpolateComplex(fine.fields.velocity.axial_shear_zx, ...
    fine.axes.x_m, fine.axes.z_m, baseline.axes.x_m, baseline.axes.z_m);
valid_overlap = isfinite(real(fine_on_base)) & isfinite(imag(fine_on_base));
grid_correlation = complexCorrelation(base_field(valid_overlap), fine_on_base(valid_overlap));
grid_speed_difference = abs( ...
    baseline_report.metrics.shear_speed.speed_m_s - ...
    fine_report.metrics.shear_speed.speed_m_s) / base_cfg.medium.cs_m_s;

domain_on_base = interpolateComplex( ...
    domain_reference.fields.velocity.axial_shear_zx, ...
    domain_reference.axes.x_m, domain_reference.axes.z_m, ...
    baseline.axes.x_m, baseline.axes.z_m);
pml_difference = relativeDifference(base_field, domain_on_base);

checks = repmat(emptyCheck(), 0, 1);
addCheck("baseline_valid", baseline_report.valid, double(baseline_report.valid), 1);
addCheck("repeat_valid", repeated_report.valid, double(repeated_report.valid), 1);
addCheck("fine_grid_valid", fine_report.valid, double(fine_report.valid), 1);
addCheck("domain_reference_valid", domain_report.valid, double(domain_report.valid), 1);
addCheck("repeat_relative_error", ...
    repeat_error <= base_cfg.diagnostics.maximum_repeat_relative_error, ...
    repeat_error, base_cfg.diagnostics.maximum_repeat_relative_error);
addCheck("grid_complex_correlation", ...
    grid_correlation >= base_cfg.diagnostics.minimum_grid_correlation, ...
    grid_correlation, base_cfg.diagnostics.minimum_grid_correlation);
addCheck("grid_speed_difference", ...
    grid_speed_difference <= base_cfg.diagnostics.maximum_speed_relative_error, ...
    grid_speed_difference, base_cfg.diagnostics.maximum_speed_relative_error);
addCheck("pml_relative_difference", ...
    pml_difference <= base_cfg.diagnostics.maximum_pml_relative_difference, ...
    pml_difference, base_cfg.diagnostics.maximum_pml_relative_difference);

validation = struct();
validation.benchmark = "directional_homogeneous_2d";
validation.valid = all([checks.pass]);
validation.checks = checks;
validation.metrics = struct('repeat_relative_error', repeat_error, ...
    'grid_complex_correlation', grid_correlation, ...
    'grid_speed_difference', grid_speed_difference, ...
    'pml_relative_difference', pml_difference);
validation.reports = struct('baseline', baseline_report, 'repeat', repeated_report, ...
    'fine_grid', fine_report, 'domain_reference', domain_report);
validation.configurations = struct('baseline', baseline.config_resolved, ...
    'fine_grid', fine.config_resolved, ...
    'domain_reference', domain_reference.config_resolved);
validation.summary = sprintf(['valid=%d, repeat=%.3g, grid correlation=%.6f, ', ...
    'grid speed difference=%.3f%%, PML difference=%.3f%%'], ...
    validation.valid, repeat_error, grid_correlation, ...
    100*grid_speed_difference, 100*pml_difference);

    function addCheck(name, pass, value, threshold)
        check = emptyCheck();
        check.name = string(name);
        check.pass = logical(pass);
        check.value = double(value);
        check.threshold = double(threshold);
        checks(end + 1, 1) = check;
    end

end

function value = relativeDifference(reference, candidate)
value = norm(candidate(:) - reference(:)) / max(norm(reference(:)), eps);
end

function value = complexCorrelation(a, b)
a = a(:);
b = b(:);
value = abs(a' * b) / max(norm(a) * norm(b), eps);
end

function interpolated = interpolateComplex(field, x_source, z_source, x_target, z_target)
[Xs, Zs] = meshgrid(x_source, z_source);
[Xt, Zt] = meshgrid(x_target, z_target);
interpolated = interp2(Xs, Zs, real(field), Xt, Zt, 'linear', NaN) + ...
    1i * interp2(Xs, Zs, imag(field), Xt, Zt, 'linear', NaN);
end

function check = emptyCheck()
check = struct('name', "", 'pass', false, 'value', NaN, 'threshold', NaN);
end
