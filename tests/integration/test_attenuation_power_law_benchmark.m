function tests = test_attenuation_power_law_benchmark
%TEST_ATTENUATION_POWER_LAW_BENCHMARK Integration test for independent attenuation frequency pairs.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'benchmarks'));
end

function testCompactPowerLawSweepPasses(testCase)
cfg = kwsim_benchmarks.attenuation_power_law_2d.compactConfig();
sweep = kwsim_benchmarks.attenuation_power_law_2d.run( ...
    cfg, [500, 300, 400]);
verifyTrue(testCase, sweep.valid, sweep.summary);

verifyEqual( ...
    testCase, ...
    sweep.frequencies_hz, ...
    [300; 400; 500]);

verifyEqual( ...
    testCase, ...
    sweep.reproducibility.seed, ...
    double(cfg.seed));

verifyTrue( ...
    testCase, ...
    sweep.reproducibility.matched_lossless_reference);

verifyLessThanOrEqual(testCase, max(sweep.relative_errors), 0.05);
verifyLessThanOrEqual(testCase, sweep.power_y_absolute_error, 0.05);
verifyTrue(testCase, all(arrayfun(@(p) ...
    p.estimate.vector_shear.r_squared >= 0.98, sweep.pairs)));
end
