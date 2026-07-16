function tests = test_directional_homogeneous_validation
%TEST_DIRECTIONAL_HOMOGENEOUS_VALIDATION
% Cross-run acceptance test for the homogeneous directional reference.

tests = functiontests(localfunctions);

end

function setupOnce(~)

root = fileparts( ...
    fileparts(fileparts(mfilename('fullpath'))));

addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'benchmarks'));

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
