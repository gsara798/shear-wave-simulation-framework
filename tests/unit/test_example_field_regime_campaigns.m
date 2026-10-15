function tests = test_example_field_regime_campaigns
tests = functiontests(localfunctions);
end

function testCurrentV2PlaneWaveCampaign(testCase)
root=repoRoot();
addpath(fullfile(root,"src"));
file=fullfile(root,"configs","campaigns","swsynth","smoke", ...
    "swsynth_v2_homogeneous_smoke.json");
[runs,validation]=simcampaigns.validateCampaign(file);
verifyTrue(testCase,validation.valid);
verifyEqual(testCase,numel(runs),4);
verifyTrue(testCase,all(arrayfun(@(r) ...
    string(r.config.schema_version)=="2.0",runs)));
counts=arrayfun(@(r) size(r.config.incidence.direction_xyz,1),runs);
verifyEqual(testCase,counts,2*ones(size(counts)));
frequencies=sort(arrayfun(@(r) ...
    r.config.excitation.frequency_hz,runs));
verifyEqual(testCase,frequencies(:),[400;400;500;500]);
end

function testCurrentV2VolumetricPlaneEikonal(testCase)
root=repoRoot();
addpath(fullfile(root,"src"));
file=fullfile(root,"configs","swsynth","v2", ...
    "volumetric3d_heterogeneous_eikonal.json");
out=simrunner.runConfig(file,DryRun=true);
verifyEqual(testCase,string(out.implementation),"modular_v2");
verifyEqual(testCase,string(out.validation.geometry),"volumetric3d");
verifyEqual(testCase,string(out.validation.phase_method),"eikonal");
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
