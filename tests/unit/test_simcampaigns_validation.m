function tests = test_simcampaigns_validation
%TEST_SIMCAMPAIGNS_VALIDATION Test backend-neutral campaign validation.

tests = functiontests(localfunctions);

end

function setupOnce(testCase)

repository_root = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repository_root, "src"));

testCase.TestData.repository_root = string(repository_root);

end

function testValidatesSwsynthCampaignWithoutOutputs(testCase)

campaign_file = fullfile( ...
    testCase.TestData.repository_root, ...
    "configs", ...
    "campaigns", ...
    "swsynth", ...
    "smoke", ...
    "swsynth_homogeneous_smoke.json");

requested = jsondecode(fileread(campaign_file));

output_root = string(tempname);
requested.output.directory = output_root;

temporary_campaign = string(tempname) + ".json";

file_id = fopen(temporary_campaign, "w");
assert(file_id >= 0);

cleanup_file = onCleanup(@() fclose(file_id));

fprintf(file_id, "%s", ...
    jsonencode(requested, PrettyPrint=true));

clear cleanup_file

cleanup = onCleanup(@() cleanupPaths( ...
    temporary_campaign, ...
    output_root));

[runs, validation] = ...
    simcampaigns.validateCampaign(temporary_campaign);

verifyEqual(testCase, numel(runs), 4);
verifyTrue(testCase, validation.valid);
verifyEqual(testCase, validation.backend, "swsynth");
verifyEqual(testCase, validation.valid_count, 4);
verifyEqual(testCase, validation.failed_count, 0);
verifyFalse(testCase, isfolder(output_root));

clear cleanup

end

function testLegacyKwsimCampaignStillValidates(testCase)

campaign_file = fullfile( ...
    testCase.TestData.repository_root, ...
    "configs", ...
    "campaigns", ...
    "kwsim", ...
    "smoke", ...
    "homogeneous_partial_3d_n8_p2_smoke.json");

[~, validation] = ...
    simcampaigns.validateCampaign(campaign_file);

verifyTrue(testCase, validation.valid);
verifyEqual(testCase, validation.backend, "kwsim");
verifyEqual(testCase, validation.valid_count, 2);

end

function cleanupPaths(temporary_campaign, output_root)

if isfile(temporary_campaign)
    delete(temporary_campaign);
end

if isfolder(output_root)
    rmdir(output_root, "s");
end

end
