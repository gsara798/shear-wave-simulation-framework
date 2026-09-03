function tests = test_directional_homogeneous_validation
%TEST_DIRECTIONAL_HOMOGENEOUS_VALIDATION
% Archived cross-run acceptance test for the legacy homogeneous directional benchmark.
%
% This test depends on the archived kwsim_benchmarks package and is retained
% only as historical validation provenance. It is not part of the active test suite.

tests = functiontests(localfunctions);

end

function setupOnce(~)

root = fileparts( ...
    fileparts(fileparts(fileparts(mfilename('fullpath')))));

addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'archive', 'legacy_benchmarks'));

end

function testCrossRunGatePasses(testCase)

cfg = ...
    kwsim_benchmarks.directional_homogeneous_2d.compactConfig();

validation = ...
    kwsim_benchmarks.directional_homogeneous_2d.validate(cfg);

verifyTrue( ...
    testCase, validation.valid, validation.summary);

verifyEqual( ...
    testCase, ...
    validation.benchmark, ...
    "directional_homogeneous_2d");

end
