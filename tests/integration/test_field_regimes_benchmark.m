function tests = test_field_regimes_benchmark
%TEST_FIELD_REGIMES_BENCHMARK Integration tests for compact multi-vibrator simulations.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'benchmarks'));
end

function testCompactFieldRegimesSuitePasses(testCase)
configs = struct();
for regime = ["directional", "partially_diffuse", "diffuse"]
    cfg = kwsim_benchmarks.field_regimes_2d.compactConfig(regime);
    % The compact aperture has coarser angular sampling than the 96x96
    % acceptance benchmark; its adjacent entropy separation is 0.08.
    cfg.diagnostics.minimum_partial_metric_margin = 0.08;
    configs.(regime) = cfg;
end
validation = kwsim_benchmarks.field_regimes_2d.run(configs);
verifyTrue(testCase, validation.valid, validation.summary);
verifyGreaterThanOrEqual(testCase, ...
    validation.metrics.target_concentration(1), 0.80);
verifyGreaterThanOrEqual(testCase, ...
    validation.metrics.angular_entropy_normalized(3), 0.75);
verifyLessThanOrEqual(testCase, validation.metrics.drive_spread_relative, 0.01);
verifyTrue(testCase, all(validation.metrics.source_bank_reproducible));
end
