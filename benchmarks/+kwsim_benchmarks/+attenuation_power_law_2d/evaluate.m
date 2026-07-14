function sweep = evaluate(pairs, base_cfg)
%EVALUATE Recover the cross-run attenuation power-law exponent.

arguments
    pairs struct
    base_cfg struct
end

if numel(pairs) < 3
    error('kwsim:InsufficientSweepFrequencies', ...
        'At least three independent frequencies are required for a power-law fit.');
end

frequencies_hz = reshape([pairs.frequency_hz], [], 1);
target_db_cm = reshape([pairs.target_attenuation_db_cm], [], 1);
recovered_db_cm = reshape([pairs.recovered_attenuation_db_cm], [], 1);
law = base_cfg.attenuation.materials(1).shear;
x = log(frequencies_hz/law.f_ref_hz);
y = log(recovered_db_cm);
finite_positive = isfinite(x) & isfinite(y) & recovered_db_cm > 0;
if nnz(finite_positive) >= 2
    design = [x(finite_positive), ones(nnz(finite_positive),1)];
    coefficients = design\y(finite_positive);
    prediction = design*coefficients;
    total_sum = sum((y(finite_positive) - mean(y(finite_positive))).^2);
    residual_sum = sum((y(finite_positive) - prediction).^2);
    recovered_y = coefficients(1);
    fitted_alpha_ref = exp(coefficients(2));
    fit_r_squared = 1 - residual_sum/max(total_sum, realmin);
else
    recovered_y = NaN;
    fitted_alpha_ref = NaN;
    fit_r_squared = NaN;
end
exponent_error = abs(recovered_y - law.power_y);

checks = repmat(emptyCheck(), 0, 1);
for index = 1:numel(pairs)
    addCheck(sprintf('frequency_%g_hz_valid', pairs(index).frequency_hz), ...
        pairs(index).valid, double(pairs(index).valid), 1);
end
addCheck("power_law_exponent_absolute_error", isfinite(exponent_error) && ...
    exponent_error <= ...
    base_cfg.diagnostics.maximum_power_law_exponent_absolute_error, ...
    exponent_error, ...
    base_cfg.diagnostics.maximum_power_law_exponent_absolute_error);

sweep = struct();
sweep.benchmark = "attenuation_power_law_2d";
sweep.valid = all([checks.pass]);
sweep.checks = checks;
sweep.frequencies_hz = frequencies_hz;
sweep.target_attenuation_db_cm = target_db_cm;
sweep.recovered_attenuation_db_cm = recovered_db_cm;
sweep.relative_errors = reshape([pairs.relative_error], [], 1);
sweep.requested_power_y = law.power_y;
sweep.recovered_power_y = recovered_y;
sweep.power_y_absolute_error = exponent_error;
sweep.fitted_alpha_ref_db_cm = fitted_alpha_ref;
sweep.power_law_fit_r_squared = fit_r_squared;
sweep.reference_frequency_hz = law.f_ref_hz;
sweep.pairs = pairs;
sweep.base_configuration = base_cfg;
sweep.summary = sprintf(['valid=%d, requested y=%.4f, recovered y=%.4f, ', ...
    '|Delta y|=%.4f, maximum alpha error=%.2f%%'], sweep.valid, ...
    law.power_y, recovered_y, exponent_error, 100*max(sweep.relative_errors));

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
