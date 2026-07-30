function tests = test_simcampaigns_execution
%TEST_SIMCAMPAIGNS_EXECUTION Test swsynth execution and resume.

tests = functiontests(localfunctions);

end

function setupOnce(testCase)

repository_root = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repository_root, "src"));

testCase.TestData.repository_root = string(repository_root);

end

function testExecutesAndResumesSwsynthCampaign(testCase)

source_campaign = fullfile( ...
    testCase.TestData.repository_root, ...
    "configs", ...
    "campaigns", ...
    "swsynth", ...
    "smoke", ...
    "swsynth_homogeneous_smoke.json");

requested = jsondecode(fileread(source_campaign));

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

report = simcampaigns.runCampaign( ...
    temporary_campaign, ...
    Resume=true, ...
    ContinueOnError=false);

verifyTrue(testCase, report.success);
verifyEqual(testCase, report.completed_count, 4);
verifyEqual(testCase, report.failed_count, 0);

campaign_directory = fullfile( ...
    output_root, ...
    "swsynth_homogeneous_smoke");

verifyTrue(testCase, ...
    isfile(fullfile( ...
        campaign_directory, ...
        "campaign_summary.json")));

verifyTrue(testCase, ...
    isfile(fullfile( ...
        campaign_directory, ...
        "campaign_runs.csv")));

for index = 1:numel(report.runs)
    run_directory = string(report.runs(index).run_directory);

    verifyTrue(testCase, ...
        isfile(fullfile(run_directory, "campaign_run.json")));

    verifyTrue(testCase, ...
        isfile(fullfile( ...
            run_directory, ...
            "config", ...
            "resolved_config.json")));

    sample_path = fullfile( ...
        run_directory, ...
        "data", ...
        "wavefield_sample.mat");

    verifyTrue(testCase, isfile(sample_path));

    loaded = load(sample_path, "wavefield_sample");

    verifyEqual(testCase, ...
        loaded.wavefield_sample.schema_name, ...
        "wavefield_sample");
end

csv_options = detectImportOptions( ...
    fullfile(campaign_directory, "campaign_runs.csv"), ...
    Delimiter=",");

campaign_runs = readtable( ...
    fullfile(campaign_directory, "campaign_runs.csv"), ...
    csv_options);

verifyEqual(testCase, height(campaign_runs), 4);
verifyEqual(testCase, ...
    string(campaign_runs.backend), ...
    repmat("swsynth", 4, 1));

resumed = simcampaigns.runCampaign( ...
    temporary_campaign, ...
    Resume=true, ...
    ContinueOnError=false);

verifyTrue(testCase, resumed.success);
verifyEqual(testCase, resumed.completed_count, 0);
verifyEqual(testCase, resumed.skipped_count, 4);

clear cleanup

end

function cleanupPaths(temporary_campaign, output_root)

if isfile(temporary_campaign)
    delete(temporary_campaign);
end

if isfolder(output_root)
    rmdir(output_root, "s");
end

end
