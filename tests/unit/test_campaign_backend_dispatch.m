function tests = test_campaign_backend_dispatch
%TEST_CAMPAIGN_BACKEND_DISPATCH Validate campaign backend contract.

tests = functiontests(localfunctions);

end

function testLegacyCampaignDefaultsToKwsim(testCase)

repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));

campaignFile = fullfile( ...
    repoRoot, ...
    "configs", ...
    "campaigns", ...
    "kwsim", ...
    "scientific", ...
    "homogeneous_directional_2d_sweep.json");

[campaign,~] = ...
    simcampaigns.loadCampaignJson(campaignFile);

verifyEqual(testCase,campaign.backend,"kwsim");

end

function testSwsynthCampaignLoadsAndValidates(testCase)

repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));

campaignFile = fullfile( ...
    repoRoot, ...
    "configs", ...
    "campaigns", ...
    "swsynth", ...
    "scientific", ...
    "reqml_projected3d_clean_training_v1", ...
    "homogeneous_n001.json");

[campaign,~] = ...
    simcampaigns.loadCampaignJson(campaignFile);

verifyEqual(testCase,campaign.backend,"swsynth");

[runs,validation] = ...
    simcampaigns.validateCampaign(campaignFile);

verifyEqual(testCase,numel(runs),54);
verifyEqual(testCase,validation.run_count,54);
verifyEqual(testCase,validation.failed_count,0);
verifyTrue(testCase,validation.valid);

end

function testRejectsUnknownBackend(testCase)

repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));

sourceFile = fullfile( ...
    repoRoot, ...
    "configs", ...
    "campaigns", ...
    "swsynth", ...
    "scientific", ...
    "reqml_projected3d_clean_training_v1", ...
    "homogeneous_n001.json");

campaign = jsondecode(fileread(sourceFile));
campaign.backend = "unknown_backend";

temporaryFile = string(tempname) + ".json";
cleanup = onCleanup(@() deleteIfPresent(temporaryFile));

writeJson(temporaryFile,campaign);

verifyError( ...
    testCase, ...
    @() simcampaigns.loadCampaignJson(temporaryFile), ...
    "simcampaigns:UnsupportedBackend");

end

function testExplicitDirectionRowsAreSeparateSweepValues(testCase)

repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));

campaignFile = fullfile( ...
    repoRoot, ...
    "configs", ...
    "campaigns", ...
    "swsynth", ...
    "scientific", ...
    "reqml_projected3d_clean_training_v1", ...
    "homogeneous_n001.json");

[runs,expansion] = ...
    simcampaigns.expandCampaign(campaignFile);

verifyEqual(testCase,expansion.run_count,54);
verifyEqual(testCase,numel(runs),54);

explicitDirections = zeros(numel(runs),3);

for index = 1:numel(runs)
    explicitDirections(index,:) = ...
        runs(index).config.directions.explicit_xyz;
end

expected = [
    1, 0, 0
    0, 0, 1
    1/sqrt(2), 0, 1/sqrt(2)
];

verifyEqual( ...
    testCase, ...
    sortrows(unique(explicitDirections,"rows")), ...
    sortrows(expected), ...
    AbsTol=1e-12);

end


function writeJson(path,value)

fileId = fopen(path,"w");
assert(fileId >= 0);

cleanup = onCleanup(@() fclose(fileId));
fprintf(fileId,"%s",jsonencode(value,PrettyPrint=true));

end

function deleteIfPresent(path)

if isfile(path)
    delete(path);
end

end
