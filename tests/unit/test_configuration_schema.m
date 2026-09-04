function tests = test_configuration_schema
%TEST_CONFIGURATION_SCHEMA Protect the dimension-independent configuration contract.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
end

function testDefaultConfigurationHasNoStageField(testCase)
cfg2 = kwsim.two_d.defaultConfig();
cfg3 = kwsim.three_d.defaultConfig();
for cfg = {cfg2,cfg3}
    verifyFalse(testCase, isfield(cfg{1}, 'stage'));
    verifyTrue(testCase, isfield(cfg{1}, 'scenario'));
    verifyTrue(testCase, isfield(cfg{1}, 'schema_version'));
end
end

function testPublicExampleConfigurationsHaveNoStageField(testCase)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
files = [ ...
    fullfile(root,"examples","kwave","2d","homogeneous","config.json")
    fullfile(root,"examples","kwave","2d","inclusion","config.json")
    fullfile(root,"examples","kwave","2d","bilayer","config.json")
    fullfile(root,"examples","kwave","3d","homogeneous","config.json")
    fullfile(root,"examples","kwave","3d","inclusion","config.json")
    fullfile(root,"examples","kwave","3d","bilayer","config.json")];
for file = files.'
    cfg = jsondecode(fileread(file));
    verifyFalse(testCase,isfield(cfg,'stage'));
end
end
