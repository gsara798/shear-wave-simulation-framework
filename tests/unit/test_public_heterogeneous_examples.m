function tests = test_public_heterogeneous_examples
tests = functiontests(localfunctions);
end

function testSyntheticVolumetricInclusion(testCase)
addSourcePath();
cfg = readSyntheticConfig("inclusion");
[cfg, report] = swsynth.validateConfig3D(cfg);
verifyTrue(testCase,report.valid);
verifyEqual(testCase,string(cfg.medium.objects{1}.type),"sphere");
end

function testSyntheticVolumetricBilayer(testCase)
addSourcePath();
cfg = readSyntheticConfig("bilayer");
[cfg, report] = swsynth.validateConfig3D(cfg);
verifyTrue(testCase,report.valid);
verifyEqual(testCase,string(cfg.medium.objects{1}.type),"slab");
end

function testKWave2DInclusion(testCase)
addSourcePath();
outcome = kwsim.cli.runConfig(examplePath("kwave","2d","inclusion"),DryRun=true);
verifyEqual(testCase,string(outcome.status),"dry_run_valid");
end

function testKWave2DBilayer(testCase)
addSourcePath();
outcome = kwsim.cli.runConfig(examplePath("kwave","2d","bilayer"),DryRun=true);
verifyEqual(testCase,string(outcome.status),"dry_run_valid");
verifyEqual(testCase,string(outcome.config_resolved.geometry.objects(1).type),"rectangle");
end

function testKWave3DInclusion(testCase)
addSourcePath();
outcome = kwsim.cli.runConfig(examplePath("kwave","3d","inclusion"),DryRun=true);
verifyEqual(testCase,string(outcome.status),"dry_run_valid");
verifyTrue(testCase,outcome.config_resolved.geometry.has_heterogeneity);
end

function testKWave3DBilayer(testCase)
addSourcePath();
outcome = kwsim.cli.runConfig(examplePath("kwave","3d","bilayer"),DryRun=true);
verifyEqual(testCase,string(outcome.status),"dry_run_valid");
verifyTrue(testCase,outcome.config_resolved.geometry.bilayer.enabled);
end

function cfg = readSyntheticConfig(name)
pathValue = examplePath("swsynth","volumetric3d",name);
cfg = jsondecode(fileread(pathValue));
if isstruct(cfg.medium.objects)
    cfg.medium.objects = num2cell(cfg.medium.objects);
end
end

function pathValue = examplePath(varargin)
root = repositoryRoot();
parts = string(varargin);
pathValue = fullfile(root,"examples",parts{:},"config.json");
end

function addSourcePath()
addpath(fullfile(repositoryRoot(),"src"));
end

function root = repositoryRoot()
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
