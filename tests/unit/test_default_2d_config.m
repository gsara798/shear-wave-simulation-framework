function tests = test_default_2d_config
%TEST_DEFAULT_2D_CONFIG Unit tests for configuration resolution and safeguards.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
testCase.TestData.root = root;
end

function testDefaultConfigurationResolves(testCase)
cfg = kwsim.two_d.defaultConfig();
[resolved, preflight] = kwsim.two_d.validateConfig(cfg);
verifyTrue(testCase, preflight.valid);
verifyEqual(testCase, resolved.medium.cp_m_s, 20);
verifyGreaterThanOrEqual(testCase, ...
    resolved.derived.shear_points_per_wavelength, 8);
verifyEqual(testCase, resolved.source.center_index_xz(2), 48.5);
end

function testRejectsNonphysicalCompressionalSpeed(testCase)
cfg = kwsim.two_d.defaultConfig();
cfg.medium.reduced_cp_factor = 1;
verifyError(testCase, @() kwsim.two_d.validateConfig(cfg), ...
    'kwsim:InvalidConfiguration');
end

function testRejectsUnderresolvedShearWavelength(testCase)
cfg = kwsim.two_d.defaultConfig();
cfg.source.f0_hz = 750;
verifyError(testCase, @() kwsim.two_d.validateConfig(cfg), ...
    'kwsim:InvalidConfiguration');
end

function testReportsMemoryBeforeSimulation(testCase)
cfg = kwsim.two_d.defaultConfig();
[resolved, ~] = kwsim.two_d.validateConfig(cfg);
verifyGreaterThan(testCase, resolved.derived.estimated_sensor_memory_bytes, 0);
verifyLessThan(testCase, resolved.derived.estimated_sensor_memory_bytes, ...
    cfg.diagnostics.maximum_sensor_memory_bytes);
end
