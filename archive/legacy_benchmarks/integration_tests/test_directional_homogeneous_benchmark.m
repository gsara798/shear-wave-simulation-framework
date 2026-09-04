function tests = test_directional_homogeneous_benchmark
%TEST_DIRECTIONAL_HOMOGENEOUS_BENCHMARK
% End-to-end simulation and artifact tests.

tests = functiontests(localfunctions);

end

function setupOnce(~)

root = fileparts( ...
    fileparts(fileparts(mfilename('fullpath'))));

addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'benchmarks'));

end

function testCompactBenchmarkPasses(testCase)

cfg = ...
    kwsim_benchmarks.directional_homogeneous_2d.compactConfig();

[result, report] = ...
    kwsim_benchmarks.directional_homogeneous_2d.run(cfg);

verifyTrue(testCase, report.valid, report.summary);
verifyTrue(testCase, result.valid);

verifyEqual( ...
    testCase, ...
    size(result.fields.velocity.axial_total_zx), ...
    [numel(result.axes.z_m), numel(result.axes.x_m)]);

verifyEqual( ...
    testCase, result.fields.velocity.units, "m/s");

verifyEqual( ...
    testCase, result.fields.displacement.units, "m");

verifyEqual( ...
    testCase, ...
    size(result.fields.displacement.lateral_total_zx), ...
    size(result.fields.displacement.axial_total_zx));

verifyFalse(testCase, result.time_series.saved);

end

function testSavesSelfContainedArtifacts(testCase)

cfg = ...
    kwsim_benchmarks.directional_homogeneous_2d.compactConfig();

cfg.diagnostics.fail_on_invalid = false;

[result, report] = ...
    kwsim_benchmarks.directional_homogeneous_2d.run(cfg);

directory = string(tempname);

cleanup = onCleanup( ...
    @() rmdir(directory, 's'));

paths = kwsim.io.saveRun( ...
    result, report, directory);

verifyTrue(testCase, isfile(paths.run_mat));
verifyTrue(testCase, isfile(paths.summary));
verifyTrue(testCase, isfile(paths.source_figure));
verifyTrue(testCase, isfile(paths.field_figure));
verifyTrue(testCase, isfile(paths.component_figure));

loaded = load( ...
    paths.run_mat, ...
    'result', ...
    'report');

verifyEqual( ...
    testCase, ...
    loaded.result.config_resolved.seed, ...
    cfg.seed);

verifyEqual( ...
    testCase, ...
    loaded.report.valid, ...
    report.valid);

clear cleanup;

end
