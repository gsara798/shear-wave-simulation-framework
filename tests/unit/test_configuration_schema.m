function tests = test_configuration_schema
%TEST_CONFIGURATION_SCHEMA Protect the dimension-independent configuration contract.

tests = functiontests(localfunctions);

end

function setupOnce(~)

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'benchmarks'));

end

function testDefaultConfigurationHasNoStageField(testCase)

cfg = kwsim.two_d.defaultConfig();

verifyFalse(testCase, isfield(cfg, 'stage'));
verifyTrue(testCase, isfield(cfg, 'scenario'));
verifyTrue(testCase, isfield(cfg, 'schema_version'));

end

function testBenchmarkConfigurationsHaveNoStageField(testCase)

configurations = {
    kwsim_benchmarks.directional_homogeneous_2d.config()
    kwsim_benchmarks.circular_inclusion_2d.config()
    kwsim_benchmarks.field_regimes_2d.config("directional")
    kwsim_benchmarks.finite_contacts_2d.config("directional")
    kwsim_benchmarks.attenuation_power_law_2d.config()
};

for index = 1:numel(configurations)
    verifyFalse(testCase, isfield(configurations{index}, 'stage'));
end

end
