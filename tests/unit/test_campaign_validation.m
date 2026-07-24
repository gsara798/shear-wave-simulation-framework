function tests = test_campaign_validation
%TEST_CAMPAIGN_VALIDATION Test complete campaign dry-run validation.

tests = functiontests(localfunctions);

end


function setupOnce(testCase)

repository_root = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repository_root, "src"));

testCase.TestData.repository_root = ...
    string(repository_root);

testCase.TestData.campaign_file = fullfile( ...
    repository_root, ...
    "configs", ...
    "campaigns", ...
    "homogeneous_directional_2d_sweep.json");

testCase.TestData.base_config_file = fullfile( ...
    repository_root, ...
    "configs", ...
    "two_d", ...
    "homogeneous_directional_cli.json");

end


function testValidatesEveryExampleRun(testCase)

[runs, validation] = ...
    kwsim.campaigns.validateCampaign( ...
        testCase.TestData.campaign_file);

verifyEqual(testCase, numel(runs), 12);
verifyEqual(testCase, validation.run_count, 12);
verifyEqual(testCase, validation.valid_count, 12);
verifyEqual(testCase, validation.failed_count, 0);
verifyTrue(testCase, validation.valid);

verifyTrue(testCase, ...
    all([validation.runs.valid]));

verifyEqual(testCase, ...
    string({validation.runs.status})', ...
    repmat("dry_run_valid", 12, 1));

verifyEqual(testCase, ...
    validation.summary, ...
    "Campaign dry-run: 12/12 runs valid.");

end


function testPreservesExpansionIdentityAndOrder(testCase)

[runs, validation] = ...
    kwsim.campaigns.validateCampaign( ...
        testCase.TestData.campaign_file);

verifyEqual(testCase, ...
    [validation.runs.ordinal]', ...
    [runs.ordinal]');

verifyEqual(testCase, ...
    string({validation.runs.run_id})', ...
    string({runs.run_id})');

end


function testAggregatesFailureAndContinues(testCase)

campaign = makeCampaign( ...
    testCase.TestData.base_config_file, ...
    [2.0, -1.0, 2.5]);

campaign_file = writeTemporaryJson(campaign);
cleanup = onCleanup(@() deleteIfPresent(campaign_file));

[runs, validation] = ...
    kwsim.campaigns.validateCampaign(campaign_file);

verifyEqual(testCase, numel(runs), 3);
verifyEqual(testCase, validation.run_count, 3);
verifyEqual(testCase, validation.valid_count, 2);
verifyEqual(testCase, validation.failed_count, 1);
verifyFalse(testCase, validation.valid);

verifyEqual(testCase, ...
    [validation.runs.valid]', ...
    [true; false; true]);

verifyEqual(testCase, ...
    validation.runs(2).status, ...
    "dry_run_failed");

verifyGreaterThan(testCase, ...
    strlength( ...
        validation.runs(2).error_identifier), ...
    0);

verifyGreaterThan(testCase, ...
    strlength( ...
        validation.runs(2).error_message), ...
    0);

verifyEqual(testCase, ...
    validation.summary, ...
    "Campaign dry-run: 2/3 runs valid.");

clear cleanup

end


function testDryRunCreatesNoSimulationOutputs(testCase)

output_directory = string(tempname);

base_config = jsondecode( ...
    fileread( ...
        testCase.TestData.base_config_file));

base_config.output.directory = output_directory;
base_config.output.run_name = ...
    "campaign_validation_output_test";
base_config.output.append_timestamp = false;

base_config_file = writeTemporaryJson(base_config);
base_cleanup = onCleanup( ...
    @() deleteIfPresent(base_config_file));

campaign = makeCampaign( ...
    base_config_file, ...
    [2.0, 2.5]);

campaign_file = writeTemporaryJson(campaign);
campaign_cleanup = onCleanup( ...
    @() deleteIfPresent(campaign_file));

[~, validation] = ...
    kwsim.campaigns.validateCampaign(campaign_file);

verifyTrue(testCase, validation.valid);
verifyFalse(testCase, isfolder(output_directory));

clear campaign_cleanup base_cleanup

end


function campaign = makeCampaign( ...
        base_config_file, speed_values)

campaign = struct();
campaign.schema_version = "1.0";
campaign.campaign_name = ...
    "campaign_validation_unit_test";
campaign.base_config = string(base_config_file);
campaign.output = struct( ...
    "directory", ...
    "outputs/campaigns");

campaign.sweep = struct( ...
    "path", ...
    "medium.cs_m_s", ...
    "values", ...
    speed_values);

end


function json_file = writeTemporaryJson(value)

json_file = string(tempname) + ".json";

file_id = fopen(json_file, "w");

if file_id < 0
    error("Could not create a temporary JSON file.");
end

cleanup = onCleanup(@() fclose(file_id));

fprintf(file_id, "%s", ...
    jsonencode(value, PrettyPrint=true));

clear cleanup

end


function deleteIfPresent(path)

if isfile(path)
    delete(path);
end

end
