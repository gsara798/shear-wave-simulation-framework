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

campaignFile = publicSwsynthCampaignFile();

[campaign,~] = ...
    simcampaigns.loadCampaignJson(campaignFile);

verifyEqual(testCase,campaign.backend,"swsynth");

[runs,validation] = ...
    simcampaigns.validateCampaign(campaignFile);

verifyEqual(testCase,numel(runs),300);
verifyEqual(testCase,validation.run_count,300);
verifyEqual(testCase,validation.failed_count,0);
verifyTrue(testCase,validation.valid);

end

function testRejectsUnknownBackend(testCase)

sourceFile = publicSwsynthCampaignFile();

campaign = jsondecode(fileread(sourceFile));
campaign.backend = "unknown_backend";

temporaryFile = string(tempname) + ".json";
cleanup = onCleanup(@() deleteIfPresent(temporaryFile)); %#ok<NASGU>

writeJson(temporaryFile,campaign);

verifyError( ...
    testCase, ...
    @() simcampaigns.loadCampaignJson(temporaryFile), ...
    "simcampaigns:UnsupportedBackend");

end

function testVectorRowsAreSeparateSweepValues(testCase)

sourceFile = publicSwsynthCampaignFile();
campaign = jsondecode(fileread(sourceFile));

campaign.campaign_name = "vector_row_sweep_test";
campaign.sweep = [ ...
    struct("path","medium.background_cs_m_s","values",[2.0,3.0,4.0]), ...
    struct("path","wavefield.frequency_hz","values",[200,400,600]), ...
    struct("path","directions.support.axis_xyz","values",[ ...
        1.0, 0.0, 0.0; ...
        0.0, 0.0, 1.0; ...
        1/sqrt(2), 0.0, 1/sqrt(2)]), ...
    struct("path","seed","values",[4101,4102])];

temporaryFile = string(tempname) + ".json";
cleanup = onCleanup(@() deleteIfPresent(temporaryFile)); %#ok<NASGU>
writeJson(temporaryFile,campaign);

[runs,expansion] = ...
    simcampaigns.expandCampaign(temporaryFile);

verifyEqual(testCase,expansion.run_count,54);
verifyEqual(testCase,numel(runs),54);

axes = zeros(numel(runs),3);

for index = 1:numel(runs)
    axes(index,:) = ...
        runs(index).config.directions.support.axis_xyz;
end

expected = [
    1, 0, 0
    0, 0, 1
    1/sqrt(2), 0, 1/sqrt(2)
];

verifyEqual( ...
    testCase, ...
    sortrows(unique(axes,"rows")), ...
    sortrows(expected), ...
    AbsTol=1e-12);

end

function campaignFile = publicSwsynthCampaignFile()

repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));

campaignFile = fullfile( ...
    repoRoot, ...
    "configs", ...
    "campaigns", ...
    "swsynth", ...
    "scientific", ...
    "homogeneous_projected3d_clean_v1.json");

end

function writeJson(path,value)

fileId = fopen(path,"w");
assert(fileId >= 0);

cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
fprintf(fileId,"%s",jsonencode(value,PrettyPrint=true));

end

function deleteIfPresent(path)

if isfile(path)
    delete(path);
end

end