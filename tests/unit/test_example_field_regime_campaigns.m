function tests = test_example_field_regime_campaigns
%TEST_EXAMPLE_FIELD_REGIME_CAMPAIGNS Validate current V2 campaign fixtures.
tests = functiontests(localfunctions);
end

function testTwoDimensionalV2Campaign(testCase)
root=repoRoot();
addpath(fullfile(root,"src"));
file=fullfile(root,"configs","campaigns","swsynth","smoke", ...
    "swsynth_v2_homogeneous_smoke.json");
[runs,validation]=simcampaigns.validateCampaign(file);
verifyTrue(testCase,validation.valid);
verifyEqual(testCase,numel(runs),4);
verifyTrue(testCase,all(arrayfun(@(r) ...
    string(r.config.geometry)=="2d",runs)));
verifyTrue(testCase,all(arrayfun(@(r) ...
    string(r.config.propagation.model)=="plane_wave",runs)));
verifyEqual(testCase,sort(arrayfun(@(r) ...
    r.config.excitation.frequency_hz,runs)),[400;400;500;500]);
end

function testVolumetricV2HeterogeneousScenario(testCase)
root=repoRoot();
addpath(fullfile(root,"src"));
file=fullfile(root,"configs","swsynth","v2", ...
    "volumetric3d_heterogeneous_eikonal.json");
config=jsondecode(fileread(file));
[scenario,meta]=swsynth.io.resolveConfigV2(config);
verifyEqual(testCase,string(meta.geometry),"volumetric3d");
verifyEqual(testCase,string(meta.phase_method),"eikonal");
verifyEqual(testCase,string(scenario.propagation.model),"plane_wave");
verifyEqual(testCase,meta.material_object_count,1);
end

function root = repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
