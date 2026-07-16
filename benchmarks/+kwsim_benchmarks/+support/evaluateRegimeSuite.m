function validation = evaluateRegimeSuite( ...
        results, reports, configurations, benchmark_name)
%EVALUATEREGIMESUITE Evaluate directionality and source-bank consistency.
%
% This function performs no wave simulation. Separating it from the runner
% permits saved fields to be re-evaluated after a diagnostic correction.

arguments
    results struct
    reports struct
    configurations struct
    benchmark_name (1,1) string
end

names = ["directional", "partially_diffuse", "diffuse"];
threshold_cfg = results.directional.config_resolved.diagnostics;
margin = threshold_cfg.minimum_partial_metric_margin;

concentration = zeros(1, 3);
entropy = zeros(1, 3);
drive = zeros(1, 3);
spatial_coherence = zeros(1, 3);
p_to_s_energy_ratio = zeros(1, 3);
solver_channel_count = zeros(1, 3);
contact_span_m = zeros(1, 3);
reproducible = false(1, 3);
for index = 1:3
    name = names(index);
    angular = reports.(name).metrics.angular;
    concentration(index) = angular.target_concentration;
    entropy(index) = angular.entropy_normalized;
    spatial_coherence(index) = angular.nearest_neighbor_spatial_coherence;
    p_to_s_energy_ratio(index) = reports.(name).metrics.p_to_s_energy_ratio;
    solver_channel_count(index) = ...
        reports.(name).metrics.contact.solver_channel_count;
    contact_span_m(index) = ...
        reports.(name).metrics.contact.requested_contact_span_m;
    drive(index) = results.(name).source.realized_drive_rms_squared_m2_s2;
    reproducible(index) = bankIsReproducible(configurations.(name));
end

requested_drive = results.directional.source.requested_drive_rms_squared_m2_s2;
drive_spread = (max(drive) - min(drive)) / requested_drive;
checks = repmat(emptyCheck(), 0, 1);
for index = 1:3
    name = names(index);
    addCheck(name + "_run_valid", reports.(name).valid, ...
        double(reports.(name).valid), 1);
    addCheck(name + "_source_reproducible", reproducible(index), ...
        double(reproducible(index)), 1);
end
addCheck("directional_concentration", concentration(1) >= ...
    threshold_cfg.minimum_directional_concentration, concentration(1), ...
    threshold_cfg.minimum_directional_concentration);
addCheck("diffuse_entropy", entropy(3) >= ...
    threshold_cfg.minimum_diffuse_angular_entropy, entropy(3), ...
    threshold_cfg.minimum_diffuse_angular_entropy);
addCheck("directional_to_partial_concentration_margin", ...
    concentration(1) - concentration(2) >= margin, ...
    concentration(1) - concentration(2), margin);
addCheck("partial_to_diffuse_concentration_margin", ...
    concentration(2) - concentration(3) >= margin, ...
    concentration(2) - concentration(3), margin);
addCheck("partial_to_directional_entropy_margin", ...
    entropy(2) - entropy(1) >= margin, entropy(2) - entropy(1), margin);
addCheck("diffuse_to_partial_entropy_margin", ...
    entropy(3) - entropy(2) >= margin, entropy(3) - entropy(2), margin);
addCheck("constant_prescribed_total_drive", drive_spread <= ...
    threshold_cfg.maximum_drive_power_relative_error, drive_spread, ...
    threshold_cfg.maximum_drive_power_relative_error);

validation = struct();
validation.benchmark = benchmark_name;
validation.valid = all([checks.pass]);
validation.checks = checks;
validation.metrics = struct();
validation.metrics.regime_names = names;
validation.metrics.target_concentration = concentration;
validation.metrics.angular_entropy_normalized = entropy;
validation.metrics.nearest_neighbor_spatial_coherence = spatial_coherence;
validation.metrics.p_to_s_energy_ratio = p_to_s_energy_ratio;
validation.metrics.solver_channel_count = solver_channel_count;
validation.metrics.contact_span_m = contact_span_m;
validation.metrics.realized_drive_rms_squared_m2_s2 = drive;
validation.metrics.drive_spread_relative = drive_spread;
validation.metrics.source_bank_reproducible = reproducible;
validation.results = results;
validation.reports = reports;
validation.configurations = struct( ...
    'directional', results.directional.config_resolved, ...
    'partially_diffuse', results.partially_diffuse.config_resolved, ...
    'diffuse', results.diffuse.config_resolved);
validation.summary = sprintf([ ...
    'valid=%d | concentration: directional %.3f, partial %.3f, diffuse %.3f', ...
    ' | entropy: directional %.3f, partial %.3f, diffuse %.3f', ...
    ' | spatial coherence: %.3f, %.3f, %.3f | drive spread %.3g'], ...
    validation.valid, concentration, entropy, spatial_coherence, drive_spread);

    function addCheck(name, pass, value, threshold)
        check = emptyCheck();
        check.name = string(name);
        check.pass = logical(pass);
        check.value = double(value);
        check.threshold = double(threshold);
        checks(end + 1, 1) = check;
    end

end

function reproducible = bankIsReproducible(cfg)
% Regenerate twice from the requested seed and compare all defining arrays.
[first_cfg, ~] = kwsim.two_d.validateConfig(cfg);
[second_cfg, ~] = kwsim.two_d.validateConfig(cfg);
first = first_cfg.source.resolved_bank;
second = second_cfg.source.resolved_bank;
reproducible = isequal(first.label_mask_xz, second.label_mask_xz) && ...
    isequal(vertcat(first.vibrators.center_index_xz), ...
        vertcat(second.vibrators.center_index_xz)) && ...
    isequal(vertcat(first.vibrators.propagation_xz), ...
        vertcat(second.vibrators.propagation_xz)) && ...
    isequal(vertcat(first.vibrators.polarization_xz), ...
        vertcat(second.vibrators.polarization_xz)) && ...
    isequal([first.vibrators.phase_rad], [second.vibrators.phase_rad]);
end

function check = emptyCheck()
check = struct('name', "", 'pass', false, 'value', NaN, 'threshold', NaN);
end
