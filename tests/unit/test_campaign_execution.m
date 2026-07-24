function tests = test_campaign_execution
%TEST_CAMPAIGN_EXECUTION Test campaign orchestration without running k-Wave.

tests = functiontests(localfunctions);

end


function setupOnce(testCase)

repository_root = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repository_root, "src"));

testCase.TestData.repository_root = ...
    string(repository_root);

testCase.TestData.base_config_file = fullfile( ...
    repository_root, ...
    "configs", ...
    "two_d", ...
    "homogeneous_directional_cli.json");

end


function testExecutesRunsInDeterministicDirectories(testCase)

fixture = makeFixture( ...
    testCase, [2.0, 2.5], "campaign_execution");
cleanup = onCleanup(@() removeFixture(fixture));

report = kwsim.campaigns.runCampaign( ...
    fixture.campaign_file, ...
    Runner=@successfulRunner);

verifyTrue(testCase, report.success);
verifyEqual(testCase, report.run_count, 2);
verifyEqual(testCase, report.completed_count, 2);
verifyEqual(testCase, report.skipped_count, 0);
verifyEqual(testCase, report.failed_count, 0);
verifyEqual(testCase, report.blocked_count, 0);

verifyEqual(testCase, ...
    string({report.runs.status})', ...
    repmat("completed", 2, 1));

for index = 1:2
    verifyTrue(testCase, ...
        isfolder(report.runs(index).run_directory));

    verifyTrue(testCase, ...
        isfile(fullfile( ...
            report.runs(index).run_directory, ...
            "campaign_run.json")));
end

verifyTrue(testCase, ...
    isfile(fullfile( ...
        report.campaign_directory, ...
        "campaign_summary.json")));

csv_file = fullfile( ...
    report.campaign_directory, ...
    "campaign_runs.csv");

verifyTrue(testCase, isfile(csv_file));

campaign_runs = readtable( ...
    csv_file, ...
    Delimiter=",", ...
    TextType="string");

verifyEqual(testCase, height(campaign_runs), 2);

verifyEqual(testCase, ...
    campaign_runs.ordinal, ...
    [1; 2]);

verifyEqual(testCase, ...
    campaign_runs.status, ...
    repmat("completed", 2, 1));

verifyEqual(testCase, ...
    campaign_runs.outcome_status, ...
    repmat("completed_valid", 2, 1));

verifyEqual(testCase, ...
    campaign_runs.background_cs_m_s, ...
    [2.0; 2.5]);

verifyTrue(testCase, ...
    all(isnan(campaign_runs.solver_elapsed_s)));

clear cleanup

end


function testContinuesAfterRunnerFailure(testCase)

fixture = makeFixture( ...
    testCase, [2.0, 2.5, 3.0], ...
    "campaign_continue_after_failure");
cleanup = onCleanup(@() removeFixture(fixture));

report = kwsim.campaigns.runCampaign( ...
    fixture.campaign_file, ...
    Runner=@runnerFailingAtTwoPointFive);

verifyFalse(testCase, report.success);
verifyEqual(testCase, report.completed_count, 2);
verifyEqual(testCase, report.failed_count, 1);

verifyEqual(testCase, ...
    string({report.runs.status})', ...
    ["completed"; "failed"; "completed"]);

verifyEqual(testCase, ...
    report.runs(2).error_identifier, ...
    "kwsim:DeliberateCampaignTestFailure");

campaign_runs = readtable( ...
    fullfile( ...
        report.campaign_directory, ...
        "campaign_runs.csv"), ...
    Delimiter=",", ...
    TextType="string");

verifyEqual(testCase, ...
    campaign_runs.status, ...
    ["completed"; "failed"; "completed"]);

verifyEqual(testCase, ...
    campaign_runs.error_identifier(2), ...
    "kwsim:DeliberateCampaignTestFailure");

clear cleanup

end


function testResumeSkipsMatchingCompletedRuns(testCase)

fixture = makeFixture( ...
    testCase, [2.0, 2.5], "campaign_resume");
cleanup = onCleanup(@() removeFixture(fixture));

first_report = kwsim.campaigns.runCampaign( ...
    fixture.campaign_file, ...
    Runner=@successfulRunner);

verifyTrue(testCase, first_report.success);

second_report = kwsim.campaigns.runCampaign( ...
    fixture.campaign_file, ...
    Runner=@runnerThatMustNotBeCalled);

verifyTrue(testCase, second_report.success);
verifyEqual(testCase, second_report.completed_count, 0);
verifyEqual(testCase, second_report.skipped_count, 2);

verifyEqual(testCase, ...
    string({second_report.runs.status})', ...
    repmat("skipped_completed", 2, 1));

clear cleanup

end


function testIncompleteDirectoryIsBlocked(testCase)

fixture = makeFixture( ...
    testCase, 2.0, "campaign_incomplete");
cleanup = onCleanup(@() removeFixture(fixture));

[runs, ~] = ...
    kwsim.campaigns.expandCampaign( ...
        fixture.campaign_file);

campaign_directory = fullfile( ...
    fixture.output_root, ...
    "campaign_incomplete");

incomplete_directory = fullfile( ...
    campaign_directory, runs(1).run_id);

mkdir(incomplete_directory);

report = kwsim.campaigns.runCampaign( ...
    fixture.campaign_file, ...
    Runner=@runnerThatMustNotBeCalled);

verifyFalse(testCase, report.success);
verifyEqual(testCase, report.blocked_count, 1);
verifyEqual(testCase, ...
    report.runs(1).status, ...
    "blocked_existing");

verifyEqual(testCase, ...
    report.runs(1).error_identifier, ...
    "kwsim:CampaignRunDirectoryExists");

clear cleanup

end


function testInvalidCampaignCreatesNoOutput(testCase)

fixture = makeFixture( ...
    testCase, [2.0, -1.0], "campaign_invalid");
cleanup = onCleanup(@() removeFixture(fixture));

verifyError(testCase, ...
    @() kwsim.campaigns.runCampaign( ...
        fixture.campaign_file, ...
        Runner=@runnerThatMustNotBeCalled), ...
    "kwsim:CampaignValidationFailed");

verifyFalse(testCase, ...
    isfolder(fixture.output_root));

clear cleanup

end


function outcome = successfulRunner(config_file)

config = jsondecode(fileread(config_file));
run_directory = fullfile( ...
    config.output.directory, ...
    config.output.run_name);

mkdir(run_directory);

outcome = struct();
outcome.status = "completed_valid";
outcome.paths = struct( ...
    "run", string(run_directory));

end


function outcome = runnerFailingAtTwoPointFive( ...
        config_file)

config = jsondecode(fileread(config_file));

if config.medium.cs_m_s == 2.5
    error("kwsim:DeliberateCampaignTestFailure", ...
        "Deliberate runner failure.");
end

outcome = successfulRunner(config_file);

end


function outcome = runnerThatMustNotBeCalled(~)

error("kwsim:UnexpectedRunnerCall", ...
    "Runner should not have been called.");

outcome = struct(); %#ok<UNRCH>

end


function fixture = makeFixture( ...
        testCase, speed_values, campaign_name)

output_root = string(tempname);

campaign = struct();
campaign.schema_version = "1.0";
campaign.campaign_name = string(campaign_name);
campaign.base_config = ...
    testCase.TestData.base_config_file;
campaign.output = struct( ...
    "directory", output_root);
campaign.sweep = struct( ...
    "path", "medium.cs_m_s", ...
    "values", speed_values);

campaign_file = writeTemporaryJson(campaign);

fixture = struct();
fixture.campaign_file = campaign_file;
fixture.output_root = output_root;

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


function removeFixture(fixture)

if isfile(fixture.campaign_file)
    delete(fixture.campaign_file);
end

if isfolder(fixture.output_root)
    rmdir(fixture.output_root, "s");
end

end
