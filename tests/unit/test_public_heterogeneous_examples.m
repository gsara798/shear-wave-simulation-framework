function tests = test_public_heterogeneous_examples
tests = functiontests(localfunctions);
end

function testSyntheticVolumetricInclusion(testCase)
addSourcePath();
cfg=readV2SyntheticConfig("volumetric3d_heterogeneous_eikonal");
[scenario,report]=swsynth.io.resolveConfigV2(cfg);
verifyTrue(testCase,report.valid);
verifyEqual(testCase,string(report.geometry),"volumetric3d");
verifyEqual(testCase,string(scenario.medium.objects{1}.type),"sphere");
end

function testSyntheticProjected3DInclusion(testCase)
addSourcePath();
cfg=readV2SyntheticConfig("projected3d_heterogeneous_eikonal");
[scenario,report]=swsynth.io.resolveConfigV2(cfg);
verifyTrue(testCase,report.valid);
verifyEqual(testCase,string(report.geometry),"projected3d");
verifyEqual(testCase,string(scenario.medium.objects{1}.type),"circle");
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

function cfg = readV2SyntheticConfig(name)
root=repositoryRoot();
pathValue=fullfile(root,"configs","swsynth","v2",name+".json");
cfg=jsondecode(fileread(pathValue));
end

function pathValue = examplePath(varargin)
root = repositoryRoot();
pathValue = fullfile(root,"examples",varargin{:},"config.json");
end

function addSourcePath()
addpath(fullfile(repositoryRoot(),"src"));
end

function root = repositoryRoot()
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
