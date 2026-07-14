function sweep = runSizeSweep(point_cfg, finite_spans_m)
%RUNSIZESWEEP Compare one point vibrator with finite contact sizes.
%
% sweep = kwsim_benchmarks.finite_contacts_2d.runSizeSweep()
%
% This diagnostic uses one external vibrator and fixed prescribed drive. The
% angular concentration gate is disabled because a single compact radiator
% is intentionally not the directional-array acceptance benchmark. All
% source, finiteness, stationarity, geometry, and drive checks remain active.

arguments
    point_cfg struct = defaultPointConfig()
    finite_spans_m (1,:) double {mustBePositive} = [4e-3, 8e-3]
end

point_cfg.source.contact_model = "point";
point_cfg.source.contact_sampling = "point";
point_cfg.source.vibrator_count = 1;
point_cfg.output.directory = "";
point_cfg.diagnostics.fail_on_invalid = false;
point_cfg.diagnostics.minimum_directional_concentration = 0;
[point_result, point_report] = kwsim.two_d.run(point_cfg);

finite_results = cell(numel(finite_spans_m), 1);
finite_reports = cell(numel(finite_spans_m), 1);
comparisons = cell(numel(finite_spans_m), 1);
for index = 1:numel(finite_spans_m)
    finite_cfg = point_cfg;
    finite_cfg.scenario = sprintf('contact_size_sweep_%.3g_mm', ...
        1e3*finite_spans_m(index));
    finite_cfg.source.contact_model = "finite_segment";
    finite_cfg.source.contact_sampling = "sparse_patch";
    finite_cfg.source.contact_profile = "raised_cosine";
    finite_cfg.source.contact_node_spacing_points = ...
        finite_cfg.diagnostics.minimum_finite_contact_node_spacing_points;
    finite_cfg.source.contact_radius_m = finite_spans_m(index)/2;
    [finite_results{index}, finite_reports{index}] = ...
        kwsim.two_d.run(finite_cfg);
    comparisons{index} = kwsim_benchmarks.finite_contacts_2d.compareModels( ...
        point_result, finite_results{index});
end

correlation = [1; cellfun(@(value) value.correlation_magnitude, comparisons)];
shape_error = [0; cellfun(@(value) ...
    value.optimal_scaled_shape_relative_error, comparisons)];
all_valid = point_report.valid && all(cellfun(@(report) report.valid, finite_reports));

sweep = struct();
sweep.valid = all_valid;
sweep.contact_span_m = [0; finite_spans_m(:)];
sweep.correlation_magnitude_to_point = correlation;
sweep.optimal_scaled_shape_relative_error = shape_error;
sweep.point_result = point_result;
sweep.point_report = point_report;
sweep.finite_results = finite_results;
sweep.finite_reports = finite_reports;
sweep.comparisons = comparisons;
sweep.summary = sprintf( ...
    'valid=%d | spans mm=%s | correlation to point=%s | shape error=%s', ...
    all_valid, mat2str(1e3*sweep.contact_span_m.', 4), ...
    mat2str(correlation.', 4), mat2str(shape_error.', 4));
sweep.acceptance_scope = ...
    "Contact-size sensitivity only; angular concentration is descriptive. " + ...
    "All temporal, geometry, source, and drive gates remain active.";

end

function cfg = defaultPointConfig()
%DEFAULTPOINTCONFIG Compact point-contact reference for the size sweep.

cfg = kwsim.two_d.defaultConfig();

cfg.scenario = "compact_contact_size_sweep_point";
cfg.seed = 1002;

cfg.grid.Nx = 48;
cfg.grid.Nz = 48;
cfg.solver.pml_size_points = 8;

cfg.source.perimeter_margin_m = 2e-3;
cfg.sensor.source_buffer_m = 1e-3;
cfg.sensor.boundary_margin_m = 3e-3;

cfg.time.settling_cycles = 1;
cfg.output.directory = "";

cfg = kwsim.sources.configureVibratorBank( ...
    cfg, "directional", 1);

cfg = kwsim.sources.configurePointContact( ...
    cfg, ContactRadiusM=1e-3);

end
