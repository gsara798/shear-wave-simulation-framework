function tests = test_example_field_regime_campaigns
tests = functiontests(localfunctions);
end

function testTwoDimensionalCampaign(testCase)
file=fullfile(repoRoot(),"examples","swsynth","2d","campaign_field_regimes","campaign.json");
[runs,validation]=simcampaigns.validateCampaign(file);
verifyTrue(testCase,validation.valid);
verifyEqual(testCase,numel(runs),3);
verifyEqual(testCase,[runs.config], [runs.config]); %#ok<NBRAK>
verifyEqual(testCase,sort(arrayfun(@(r) r.config.directions.count,runs)),[1 16 128]);
verifyTrue(testCase,all(arrayfun(@(r) r.config.directions.space=="two_dimensional",runs)));
end

function testVolumetricCampaign(testCase)
file=fullfile(repoRoot(),"examples","swsynth","volumetric3d","campaign_field_regimes","campaign.json");
[runs,validation]=simcampaigns.validateCampaign(file);
verifyTrue(testCase,validation.valid);
verifyEqual(testCase,numel(runs),3);
verifyEqual(testCase,sort(arrayfun(@(r) r.config.directions.count,runs)),[1 16 128]);
verifyTrue(testCase,all(arrayfun(@(r) isfield(r.config.domain,"Ly_m"),runs)));
verifyTrue(testCase,all(arrayfun(@(r) r.config.propagation.phase_model=="homogeneous_analytic",runs)));
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
