function tests = test_simrunner_unified_entrypoint
tests = functiontests(localfunctions);
end

function testSwsynthDryRun(testCase)
root = addFrameworkPath();
configFile = fullfile(root,"configs","swsynth","v2","volumetric3d_heterogeneous_eikonal.json");
outcome = simrunner.runConfig(configFile,DryRun=true);
verifyEqual(testCase,string(outcome.status),"dry_run_valid");
verifyEqual(testCase,string(outcome.backend),"swsynth");
verifyEqual(testCase,string(outcome.implementation),"modular_v2");
verifyEqual(testCase,string(outcome.validation.geometry),"volumetric3d");
end

function testKWaveDryRun(testCase)
root = addFrameworkPath();
configFile = fullfile(root,"examples","kwave","2d","inclusion","config.json");
outcome = simrunner.runConfig(configFile,DryRun=true);
verifyEqual(testCase,string(outcome.status),"dry_run_valid");
verifyEqual(testCase,double(outcome.dimension),2);
end

function testPublicCampaignDryRun(testCase)
root = addFrameworkPath();
addpath(root);
campaignFile = fullfile(root,"configs","campaigns","swsynth","smoke", ...
    "swsynth_v2_homogeneous_smoke.json");
report = run_campaign(campaignFile,DryRun=true);
verifyTrue(testCase,report.valid);
verifyEqual(testCase,string(report.backend),"swsynth");
verifyEqual(testCase,double(report.run_count),4);
verifyEqual(testCase,double(report.failed_count),0);
end

function testVisibilityNormalization(testCase)
addFrameworkPath();
verifyEqual(testCase,simviz.normalizeVisible(true),"on");
verifyEqual(testCase,simviz.normalizeVisible(false),"off");
verifyEqual(testCase,simviz.normalizeVisible("1"),"on");
verifyEqual(testCase,simviz.normalizeVisible("0"),"off");
verifyEqual(testCase,simviz.normalizeVisible("on"),"on");
verifyEqual(testCase,simviz.normalizeVisible("off"),"off");
end

function root = addFrameworkPath()
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
end
