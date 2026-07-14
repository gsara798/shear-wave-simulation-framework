function tests = test_stage1_validation
%TEST_STAGE1_VALIDATION Cross-run acceptance gate for Stage 1.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
end

function testCrossRunGatePasses(testCase)
cfg = kwsim.diagnostics.compactValidationConfig();
validation = kwsim.diagnostics.runStage1Validation(cfg);
verifyTrue(testCase, validation.valid, validation.summary);
end
