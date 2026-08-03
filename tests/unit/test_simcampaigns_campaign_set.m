function tests = test_simcampaigns_campaign_set
%TEST_SIMCAMPAIGNS_CAMPAIGN_SET Test multi-campaign execution.

tests = functiontests(localfunctions);

end


function setupOnce(testCase)

repository_root = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repository_root, "src"));

testCase.TestData.repository_root = ...
    string(repository_root);

end


function testExecutesCampaignsInDeclaredOrder(testCase)

output_root = string(tempname);
mkdir(output_root);

campaign_a = make_campaign( ...
    testCase, ...
    output_root, ...
    "campaign_set_a", ...
    300, ...
    101);

campaign_b = make_campaign( ...
    testCase, ...
    output_root, ...
    "campaign_set_b", ...
    500, ...
    202);

cleanup = onCleanup(@() cleanup_paths( ...
    [campaign_a; campaign_b], ...
    output_root));

result = simcampaigns.runCampaignSet( ...
    [campaign_a; campaign_b], ...
    Resume=true, ...
    ContinueOnError=false, ...
    Executor=@fake_executor);

verifyTrue(testCase, result.success);
verifyEqual(testCase, result.campaign_count, 2);
verifyEqual(testCase, result.run_count, 2);
verifyEqual(testCase, result.completed_count, 2);
verifyEqual(testCase, result.skipped_count, 0);
verifyEqual(testCase, result.failed_count, 0);

verifyEqual(testCase, ...
    string({result.campaigns.campaign_name})', ...
    ["campaign_set_a"; "campaign_set_b"]);

verifyTrue(testCase, ...
    all(isfile( ...
        string({result.campaigns.campaign_runs_csv})')));

clear cleanup

end


function testResumeSkipsPreviouslyCompletedRuns(testCase)

output_root = string(tempname);
mkdir(output_root);

campaign_file = make_campaign( ...
    testCase, ...
    output_root, ...
    "campaign_set_resume", ...
    400, ...
    303);

cleanup = onCleanup(@() cleanup_paths( ...
    campaign_file, ...
    output_root));

first = simcampaigns.runCampaignSet( ...
    campaign_file, ...
    Resume=true, ...
    Executor=@fake_executor);

second = simcampaigns.runCampaignSet( ...
    campaign_file, ...
    Resume=true, ...
    Executor=@fake_executor);

verifyEqual(testCase, first.completed_count, 1);
verifyEqual(testCase, first.skipped_count, 0);

verifyEqual(testCase, second.completed_count, 0);
verifyEqual(testCase, second.skipped_count, 1);

clear cleanup

end


function testRejectsMissingCampaignFile(testCase)

verifyError(testCase, ...
    @() simcampaigns.runCampaignSet( ...
        "missing_campaign.json"), ...
    "simcampaigns:CampaignSetFileNotFound");

end


function campaign_file = make_campaign( ...
        testCase, output_root, campaign_name, frequency, seed)

source_campaign = fullfile( ...
    testCase.TestData.repository_root, ...
    "configs", ...
    "campaigns", ...
    "swsynth", ...
    "smoke", ...
    "swsynth_heterogeneous_circle_smoke.json");

source = jsondecode(fileread(source_campaign));

campaign = struct();

campaign.schema_version = "1.2";
campaign.backend = "swsynth";
campaign.campaign_name = campaign_name;
campaign.base_config = source.base_config;

campaign.output = struct( ...
    "directory", output_root);

overrides(1) = struct( ...
    "path", "wavefield.frequency_hz", ...
    "value", frequency);

overrides(2) = struct( ...
    "path", "seed", ...
    "value", seed);

campaign.runs = struct( ...
    "design_id", campaign_name + "_design", ...
    "condition_id", campaign_name + "_condition", ...
    "realization_id", 1, ...
    "overrides", overrides);

campaign_file = string(tempname) + ".json";

file_id = fopen(campaign_file, "w");
assert(file_id >= 0);

file_cleanup = onCleanup(@() fclose(file_id));

fprintf(file_id, "%s", ...
    jsonencode(campaign, PrettyPrint=true));

clear file_cleanup

end


function outcome = fake_executor(~, ~, run_directory)

run_directory = string(run_directory);

mkdir(run_directory);
mkdir(fullfile(run_directory, "config"));
mkdir(fullfile(run_directory, "data"));
mkdir(fullfile(run_directory, "validation"));

write_text( ...
    fullfile(run_directory, "config", ...
        "resolved_config.json"), ...
    "{}");

write_text( ...
    fullfile(run_directory, "data", ...
        "run_summary.json"), ...
    "{}");

write_text( ...
    fullfile(run_directory, "validation", ...
        "validation_report.json"), ...
    '{"valid":true}');

write_text( ...
    fullfile(run_directory, "data", ...
        "wavefield_sample.mat"), ...
    "placeholder");

outcome = struct();
outcome.status = "completed";
outcome.paths = struct();
outcome.paths.run = run_directory;

end


function write_text(path_value, content)

file_id = fopen(path_value, "w");
assert(file_id >= 0);

cleanup = onCleanup(@() fclose(file_id));
fprintf(file_id, "%s", content);

end


function cleanup_paths(campaign_files, output_root)

for file = campaign_files.'
    if isfile(file)
        delete(file);
    end
end

if isfolder(output_root)
    rmdir(output_root, "s");
end

end
