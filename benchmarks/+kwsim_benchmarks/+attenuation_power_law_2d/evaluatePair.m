function pair = evaluatePair(attenuated, attenuated_report, ...
        lossless, lossless_report)
%EVALUATEPAIR Diagnose one matched attenuated/lossless frequency pair.

arguments
    attenuated struct
    attenuated_report struct
    lossless struct
    lossless_report struct
end

cfg = attenuated.config_resolved;
if ~attenuated.truth.attenuation.enabled || lossless.truth.attenuation.enabled
    error('kwsim:InvalidAttenuationPair', ...
        'The first run must be attenuated and the second explicitly lossless.');
end
material_ids = unique(attenuated.truth.material_id_zx);
if numel(material_ids) ~= 1
    error('kwsim:UnsupportedAttenuationBenchmark', ...
        'Attenuation recovery currently requires a homogeneous medium.');
end

estimate = kwsim.analysis.estimateAttenuation(attenuated, lossless);
target = unique(attenuated.truth.attenuation.shear_alpha_at_f0_db_cm_zx);
target = target(1);
recovered = estimate.vector_shear.attenuation_db_cm;
relative_error = abs(recovered - target)/max(abs(target), realmin);

checks = repmat(emptyCheck(), 0, 1);
addCheck("attenuated_run_valid", attenuated_report.valid, ...
    double(attenuated_report.valid), 1);
addCheck("lossless_run_valid", lossless_report.valid, ...
    double(lossless_report.valid), 1);
addCheck("attenuation_fit_points", ...
    estimate.vector_shear.usable_points >= ...
    cfg.diagnostics.minimum_attenuation_fit_points, ...
    estimate.vector_shear.usable_points, ...
    cfg.diagnostics.minimum_attenuation_fit_points);
addCheck("attenuation_fit_r_squared", ...
    estimate.vector_shear.r_squared >= ...
    cfg.diagnostics.minimum_attenuation_fit_r_squared, ...
    estimate.vector_shear.r_squared, ...
    cfg.diagnostics.minimum_attenuation_fit_r_squared);
addCheck("attenuation_relative_error", isfinite(relative_error) && ...
    relative_error <= cfg.diagnostics.maximum_attenuation_relative_error, ...
    relative_error, cfg.diagnostics.maximum_attenuation_relative_error);
addCheck("attenuated_speed_relative_difference", ...
    isfinite(estimate.speed_relative_difference) && ...
    estimate.speed_relative_difference <= ...
    cfg.diagnostics.maximum_attenuated_speed_relative_difference, ...
    estimate.speed_relative_difference, ...
    cfg.diagnostics.maximum_attenuated_speed_relative_difference);

pair = struct();
pair.benchmark = "attenuation_power_law_2d";
pair.frequency_hz = attenuated.axes.f0_hz;
pair.valid = all([checks.pass]);
pair.checks = checks;
pair.target_attenuation_db_cm = target;
pair.recovered_attenuation_db_cm = recovered;
pair.relative_error = relative_error;
pair.estimate = estimate;
pair.attenuated = attenuated;
pair.lossless = lossless;
pair.reports = struct('attenuated', attenuated_report, 'lossless', lossless_report);
pair.summary = sprintf(['valid=%d, f0=%.1f Hz, target=%.4f dB/cm, ', ...
    'recovered=%.4f dB/cm, error=%.2f%%, R2=%.5f, speed change=%.2f%%'], ...
    pair.valid, pair.frequency_hz, target, recovered, 100*relative_error, ...
    estimate.vector_shear.r_squared, 100*estimate.speed_relative_difference);

    function addCheck(name, pass, value, threshold)
        check = emptyCheck();
        check.name = string(name);
        check.pass = logical(pass);
        check.value = double(value);
        check.threshold = double(threshold);
        checks(end + 1, 1) = check;
    end
end

function check = emptyCheck()
check = struct('name', "", 'pass', false, 'value', NaN, 'threshold', NaN);
end
