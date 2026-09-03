function tests = test_circular_inclusion_benchmark
%TEST_CIRCULAR_INCLUSION_BENCHMARK Integration tests for heterogeneous circular-inclusion simulations.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'benchmarks'));
end

function testCompactInclusionRunPasses(testCase)
cfg = kwsim_benchmarks.circular_inclusion_2d.compactConfig();
[result, report] = kwsim.two_d.run(cfg);
verifyTrue(testCase, report.valid, report.summary);
verifyEqual(testCase, unique(result.truth.material_id_zx), uint16([1; 2]));
verifyEqual(testCase, unique(result.truth.cs_m_s_zx), [2; 3]);
verifyEqual(testCase, result.config_resolved.medium.cp_m_s, 30);
end

function testCircularInclusionAcceptanceSuitePasses(testCase)
cfg = kwsim_benchmarks.circular_inclusion_2d.compactConfig();
validation = kwsim_benchmarks.circular_inclusion_2d.run(cfg);
verifyTrue(testCase, validation.valid, validation.summary);
verifyLessThanOrEqual(testCase, ...
    validation.metrics.zero_contrast_relative_error, 1e-6);
verifyLessThanOrEqual(testCase, ...
    validation.metrics.axial_symmetry_error, 0.02);
end
