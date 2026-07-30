function tests = test_simcampaigns_csv_metadata
%TEST_SIMCAMPAIGNS_CSV_METADATA Test heterogeneous object metadata in CSV.

tests = functiontests(localfunctions);

end

function setupOnce(testCase)

repository_root = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repository_root, "src"));

testCase.TestData.repository_root = ...
    string(repository_root);

end

function testWritesPrimaryObjectMetadata(testCase)

source_campaign = fullfile( ...
    testCase.TestData.repository_root, ...
    "configs", ...
    "campaigns", ...
    "swsynth", ...
    "smoke", ...
    "swsynth_heterogeneous_circle_smoke.json");

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

csv_file = fullfile( ...
    output_root, ...
    "swsynth_heterogeneous_circle_smoke", ...
    "campaign_runs.csv");

options = detectImportOptions( ...
    csv_file, ...
    Delimiter=",");

campaign_runs = readtable(csv_file, options);

verifyEqual(testCase, height(campaign_runs), 8);

verifyEqual(testCase, ...
    string(campaign_runs.primary_object_type), ...
    repmat("circle", 8, 1));

verifyEqual(testCase, ...
    campaign_runs.primary_object_cs_m_s, ...
    [2.5; 2.5; 2.5; 2.5; 4.0; 4.0; 4.0; 4.0]);

verifyEqual(testCase, ...
    campaign_runs.primary_object_radius_m, ...
    repmat(0.010, 8, 1), ...
    AbsTol=1e-12);

verifyEqual(testCase, ...
    campaign_runs.frequency_hz, ...
    [400; 400; 500; 500; 400; 400; 500; 500]);

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
