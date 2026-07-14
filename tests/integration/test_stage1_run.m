function tests = test_stage1_run
%TEST_STAGE1_RUN End-to-end Stage 1 simulation and artifact test.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
end

function testCompactBenchmarkPasses(testCase)
cfg = kwsim.diagnostics.compactValidationConfig();
[result, report] = kwsim.two_d.run(cfg);
verifyTrue(testCase, report.valid, report.summary);
verifyTrue(testCase, result.valid);
verifyEqual(testCase, size(result.fields.velocity.axial_total_zx), ...
    [numel(result.axes.z_m), numel(result.axes.x_m)]);
verifyEqual(testCase, result.fields.velocity.units, "m/s");
verifyEqual(testCase, result.fields.displacement.units, "m");
verifyEqual(testCase, size(result.fields.displacement.lateral_total_zx), ...
    size(result.fields.displacement.axial_total_zx));
verifyFalse(testCase, result.time_series.saved);
end

function testSavesSelfContainedArtifacts(testCase)
cfg = kwsim.diagnostics.compactValidationConfig();
cfg.diagnostics.fail_on_invalid = false;
[result, report] = kwsim.two_d.run(cfg);
directory = string(tempname);
cleanup = onCleanup(@() rmdir(directory, 's'));
paths = kwsim.common.saveRun(result, report, directory);
verifyTrue(testCase, isfile(paths.run_mat));
verifyTrue(testCase, isfile(paths.summary));
verifyTrue(testCase, isfile(paths.source_figure));
verifyTrue(testCase, isfile(paths.field_figure));
verifyTrue(testCase, isfile(paths.component_figure));
loaded = load(paths.run_mat, 'result', 'report');
verifyEqual(testCase, loaded.result.config_resolved.seed, cfg.seed);
verifyEqual(testCase, loaded.report.valid, report.valid);
clear cleanup;
end
