function tests = test_campaign_expansion
%TEST_CAMPAIGN_EXPANSION Test deterministic Cartesian campaign expansion.

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

testCase.TestData.base_config = ...
    "configs/two_d/homogeneous_directional_cli.json";

end


function testExpandsExampleToTwelveRuns(testCase)

[runs, expansion] = ...
    kwsim.campaigns.expandCampaign( ...
        testCase.TestData.campaign_file);

verifyEqual(testCase, numel(runs), 12);
verifyEqual(testCase, expansion.run_count, 12);
verifyEqual(testCase, expansion.value_counts, [3; 2; 2]);

verifyEqual(testCase, ...
    [runs.ordinal]', ...
    (1:12)');

end


function testLastParameterVariesFastest(testCase)

runs = kwsim.campaigns.expandCampaign( ...
    testCase.TestData.campaign_file);

verifyRun(testCase, runs(1), ...
    [1; 1; 1], 2.0, 400, 1001);

verifyRun(testCase, runs(2), ...
    [1; 1; 2], 2.0, 400, 1002);

verifyRun(testCase, runs(3), ...
    [1; 2; 1], 2.0, 500, 1001);

verifyRun(testCase, runs(4), ...
    [1; 2; 2], 2.0, 500, 1002);

verifyRun(testCase, runs(5), ...
    [2; 1; 1], 2.5, 400, 1001);

verifyRun(testCase, runs(12), ...
    [3; 2; 2], 3.0, 500, 1002);

end


function testPreservesBaseConfiguration(testCase)

[~, metadata_before] = ...
    kwsim.campaigns.loadCampaignJson( ...
        testCase.TestData.campaign_file);

runs = kwsim.campaigns.expandCampaign( ...
    testCase.TestData.campaign_file);

[~, metadata_after] = ...
    kwsim.campaigns.loadCampaignJson( ...
        testCase.TestData.campaign_file);

verifyEqual(testCase, ...
    metadata_after.base_config, ...
    metadata_before.base_config);

verifyEqual(testCase, ...
    metadata_after.base_config.medium.cs_m_s, ...
    2.0);

verifyNotEqual(testCase, ...
    runs(12).config.medium.cs_m_s, ...
    metadata_after.base_config.medium.cs_m_s);

end


function testCreatesStableUniqueRunIdentifiers(testCase)

runs_first = kwsim.campaigns.expandCampaign( ...
    testCase.TestData.campaign_file);

runs_second = kwsim.campaigns.expandCampaign( ...
    testCase.TestData.campaign_file);

first_ids = string({runs_first.run_id})';
second_ids = string({runs_second.run_id})';
first_hashes = string({runs_first.hash_sha256})';
second_hashes = string({runs_second.hash_sha256})';

verifyEqual(testCase, first_ids, second_ids);
verifyEqual(testCase, first_hashes, second_hashes);
verifyEqual(testCase, numel(unique(first_ids)), 12);

verifyTrue(testCase, all(strlength(first_hashes) == 64));
verifyTrue(testCase, all(matches( ...
    first_ids, ...
    regexpPattern( ...
        "^run_[0-9]{6}_[0-9a-f]{12}$"))));

end


function testCampaignOutputLocationDoesNotChangeIdentity(testCase)

campaign_a = makeCampaign(testCase, "outputs/campaign_a");
campaign_b = makeCampaign(testCase, "elsewhere/campaign_b");

file_a = writeTemporaryJson(campaign_a);
file_b = writeTemporaryJson(campaign_b);

cleanup_a = onCleanup(@() deleteIfPresent(file_a));
cleanup_b = onCleanup(@() deleteIfPresent(file_b));

runs_a = kwsim.campaigns.expandCampaign(file_a);
runs_b = kwsim.campaigns.expandCampaign(file_b);

verifyEqual(testCase, ...
    string({runs_a.run_id})', ...
    string({runs_b.run_id})');

verifyEqual(testCase, ...
    string({runs_a.hash_sha256})', ...
    string({runs_b.hash_sha256})');

clear cleanup_b cleanup_a

end


function testRecordsSelectedValues(testCase)

runs = kwsim.campaigns.expandCampaign( ...
    testCase.TestData.campaign_file);

selection = runs(6).selection;

verifyEqual(testCase, ...
    string({selection.path})', ...
    ["medium.cs_m_s"; "source.f0_hz"; "seed"]);

verifyEqual(testCase, ...
    [selection.value_index]', ...
    [2; 1; 2]);

verifyEqual(testCase, selection(1).value, 2.5);
verifyEqual(testCase, selection(2).value, 400);
verifyEqual(testCase, selection(3).value, 1002);

end


function verifyRun( ...
        testCase, ...
        run, ...
        expected_indices, ...
        expected_speed, ...
        expected_frequency, ...
        expected_seed)

verifyEqual(testCase, ...
    run.value_indices, ...
    expected_indices);

verifyEqual(testCase, ...
    run.config.medium.cs_m_s, ...
    expected_speed);

verifyEqual(testCase, ...
    run.config.source.f0_hz, ...
    expected_frequency);

verifyEqual(testCase, ...
    run.config.seed, ...
    expected_seed);

end


function campaign = makeCampaign(testCase, output_directory)

campaign = struct();
campaign.schema_version = "1.0";
campaign.campaign_name = "expansion_unit_test";
campaign.base_config = testCase.TestData.base_config;
campaign.output = struct( ...
    "directory", output_directory);

campaign.sweep(1) = struct( ...
    "path", "medium.cs_m_s", ...
    "values", [2.0, 2.5]);

campaign.sweep(2) = struct( ...
    "path", "source.f0_hz", ...
    "values", [400, 500]);

end


function campaign_file = writeTemporaryJson(campaign)

campaign_file = string(tempname) + ".json";

file_id = fopen(campaign_file, "w");

if file_id < 0
    error("Could not create temporary campaign JSON file.");
end

cleanup = onCleanup(@() fclose(file_id));

fprintf(file_id, "%s", ...
    jsonencode(campaign, PrettyPrint=true));

clear cleanup

end


function deleteIfPresent(path)

if isfile(path)
    delete(path);
end

end
