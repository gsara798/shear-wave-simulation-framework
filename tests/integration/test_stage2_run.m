function tests = test_stage2_run
%TEST_STAGE2_RUN Integration tests for heterogeneous Stage 2 simulations.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
end

function testCompactInclusionRunPasses(testCase)
cfg = kwsim.diagnostics.compactStage2Config();
[result, report] = kwsim.two_d.run(cfg);
verifyTrue(testCase, report.valid, report.summary);
verifyEqual(testCase, unique(result.truth.material_id_zx), uint16([1; 2]));
verifyEqual(testCase, unique(result.truth.cs_m_s_zx), [2; 3]);
verifyEqual(testCase, result.config_resolved.medium.cp_m_s, 30);
end

function testStage2AcceptanceSuitePasses(testCase)
cfg = kwsim.diagnostics.compactStage2Config();
validation = kwsim.diagnostics.runStage2Validation(cfg);
verifyTrue(testCase, validation.valid, validation.summary);
verifyLessThanOrEqual(testCase, ...
    validation.metrics.zero_contrast_relative_error, 1e-6);
verifyLessThanOrEqual(testCase, ...
    validation.metrics.axial_symmetry_error, 0.02);
end
