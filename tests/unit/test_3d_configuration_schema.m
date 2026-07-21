function tests = test_3d_configuration_schema
%TEST_3D_CONFIGURATION_SCHEMA Protect the 3D configuration contract.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
end

function testMissingRequiredFieldFails(testCase)
cfg = kwsim.three_d.defaultConfig();
cfg = rmfield(cfg, 'source');

verifyError(testCase, ...
    @() kwsim.three_d.validateConfig(cfg), ...
    "kwsim:Invalid3DConfig");
end

function testDimensionMustBeThree(testCase)
cfg = kwsim.three_d.defaultConfig();
cfg.dimension = 2;

verifyError(testCase, ...
    @() kwsim.three_d.validateConfig(cfg), ...
    "kwsim:Invalid3DConfig");
end

function testInsufficientResolutionFails(testCase)
cfg = kwsim.three_d.defaultConfig();
cfg.grid.dx_m = 2e-3;

verifyError(testCase, ...
    @() kwsim.three_d.validateConfig(cfg), ...
    "kwsim:Invalid3DConfig");
end

function testNonTransversePolarizationFails(testCase)
cfg = kwsim.three_d.defaultConfig();
cfg.source.polarization_xyz = [1, 0, 0];

verifyError(testCase, ...
    @() kwsim.three_d.validateConfig(cfg), ...
    "kwsim:Invalid3DConfig");
end

function testMemoryLimitCanRejectRun(testCase)
cfg = kwsim.three_d.defaultConfig();
cfg.execution.maximum_memory_bytes = 1;

verifyError(testCase, ...
    @() kwsim.three_d.validateConfig(cfg), ...
    "kwsim:MemoryLimitExceeded");
end
