function tests = test_simcampaigns_explicit_runs
%TEST_SIMCAMPAIGNS_EXPLICIT_RUNS Test campaign schema 1.2 explicit runs.

tests = functiontests(localfunctions);

end


function setupOnce(testCase)

repositoryRoot = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repositoryRoot, "src"));

testCase.TestData.repositoryRoot = ...
    string(repositoryRoot);

end


function testExplicitRunsPreserveDeclaredOrder(testCase)

campaignFile = writeCampaign( ...
    testCase, ...
    ["design_a", "design_b"], ...
    [300, 500], ...
    [101; 202]);

cleanup = onCleanup(@() deleteIfPresent(campaignFile));

[runs, expansion] = ...
    simcampaigns.expandCampaign(campaignFile);

verifyEqual(testCase, expansion.mode, "explicit_runs");
verifyEqual(testCase, expansion.run_count, 2);
verifyEqual(testCase, expansion.order, "explicit_json_run_order");

verifyEqual( ...
    testCase, ...
    string({runs.design_id})', ...
    ["design_a"; "design_b"]);

actualFrequencies = arrayfun( ...
    @(run) run.config.wavefield.frequency_hz, ...
    runs);

actualSeeds = arrayfun( ...
    @(run) run.config.seed, ...
    runs);

verifyEqual( ...
    testCase, ...
    actualFrequencies, ...
    [300; 500]);

verifyEqual( ...
    testCase, ...
    actualSeeds, ...
    [101; 202]);

clear cleanup

end


function testExpansionIsDeterministic(testCase)

campaignFile = writeCampaign( ...
    testCase, ...
    ["design_a", "design_b"], ...
    [300, 500], ...
    [101, 202]);

cleanup = onCleanup(@() deleteIfPresent(campaignFile));

[runsA, ~] = simcampaigns.expandCampaign(campaignFile);
[runsB, ~] = simcampaigns.expandCampaign(campaignFile);

verifyEqual( ...
    testCase, ...
    string({runsA.run_id})', ...
    string({runsB.run_id})');

verifyEqual( ...
    testCase, ...
    string({runsA.hash_sha256})', ...
    string({runsB.hash_sha256})');

clear cleanup

end


function testDifferentConfigurationsHaveDifferentHashes(testCase)

campaignFile = writeCampaign( ...
    testCase, ...
    ["design_a", "design_b"], ...
    [300, 500], ...
    [101, 101]);

cleanup = onCleanup(@() deleteIfPresent(campaignFile));

[runs, ~] = simcampaigns.expandCampaign(campaignFile);

verifyNotEqual( ...
    testCase, ...
    runs(1).hash_sha256, ...
    runs(2).hash_sha256);

clear cleanup

end



function testDesignIdPropagatesToExecutionArtifacts(testCase)

campaign = baseCampaign(testCase);

campaign.campaign_name = ...
    "explicit_runs_execution_unit_test";

campaign.output = struct( ...
    "directory", ...
    string(tempname));

campaign.runs = makeRuns( ...
    ["design_a", "design_b"], ...
    [300, 500], ...
    [101, 202]);

campaignFile = writeJson(campaign);

outputRoot = string(campaign.output.directory);

cleanup = onCleanup(@() cleanupPaths( ...
    campaignFile, ...
    outputRoot));

executor = @(config, backend, runDirectory) ...
    fakeExecutor(config, backend, runDirectory);

report = simcampaigns.runCampaign( ...
    campaignFile, ...
    Resume=true, ...
    ContinueOnError=false, ...
    Executor=executor);

verifyTrue(testCase, report.success);

verifyEqual( ...
    testCase, ...
    string({report.runs.design_id})', ...
    ["design_a"; "design_b"]);

csvFile = fullfile( ...
    outputRoot, ...
    campaign.campaign_name, ...
    "campaign_runs.csv");

campaignRuns = readtable( ...
    csvFile, ...
    Delimiter=",", ...
    TextType="string");

verifyEqual( ...
    testCase, ...
    campaignRuns.design_id, ...
    ["design_a"; "design_b"]);

for index = 1:2
    markerFile = fullfile( ...
        report.runs(index).run_directory, ...
        "campaign_run.json");

    marker = jsondecode(fileread(markerFile));

    verifyEqual( ...
        testCase, ...
        string(marker.design_id), ...
        "design_" + char('a' + index - 1));
end

clear cleanup

end


function testDuplicateDesignIdsAreRejected(testCase)

campaignFile = writeCampaign( ...
    testCase, ...
    ["duplicate", "duplicate"], ...
    [300, 500], ...
    [101, 202]);

cleanup = onCleanup(@() deleteIfPresent(campaignFile));

verifyError( ...
    testCase, ...
    @() simcampaigns.loadCampaignJson(campaignFile), ...
    "simcampaigns:DuplicateDesignId");

clear cleanup

end


function testSweepAndRunsCannotCoexist(testCase)

campaign = baseCampaign(testCase);

campaign.sweep = struct( ...
    "path", "seed", ...
    "values", [1, 2]);

campaign.runs = makeRuns( ...
    ["design_a", "design_b"], ...
    [300, 500], ...
    [101, 202]);

campaignFile = writeJson(campaign);

cleanup = onCleanup(@() deleteIfPresent(campaignFile));

verifyError( ...
    testCase, ...
    @() simcampaigns.loadCampaignJson(campaignFile), ...
    "simcampaigns:InvalidCampaignMode");

clear cleanup

end


function campaignFile = writeCampaign( ...
        testCase, designIds, frequencies, seeds)

campaign = baseCampaign(testCase);

campaign.runs = makeRuns( ...
    designIds, ...
    frequencies, ...
    seeds);

campaignFile = writeJson(campaign);

end


function campaign = baseCampaign(testCase)

sourceCampaign = fullfile( ...
    testCase.TestData.repositoryRoot, ...
    "configs", ...
    "campaigns", ...
    "swsynth", ...
    "smoke", ...
    "swsynth_heterogeneous_circle_smoke.json");

source = jsondecode(fileread(sourceCampaign));

campaign = struct();
campaign.schema_version = "1.2";
campaign.backend = "swsynth";
campaign.campaign_name = "explicit_runs_unit_test";
campaign.base_config = source.base_config;

end


function runs = makeRuns(designIds, frequencies, seeds)

runCount = numel(designIds);

runs = repmat(struct( ...
    "design_id", "", ...
    "overrides", struct([])), ...
    runCount, ...
    1);

for index = 1:runCount
    overrides(1) = struct( ...
        "path", "wavefield.frequency_hz", ...
        "value", frequencies(index));

    overrides(2) = struct( ...
        "path", "seed", ...
        "value", seeds(index));

    runs(index).design_id = designIds(index);
    runs(index).overrides = overrides;
end

end


function campaignFile = writeJson(campaign)

campaignFile = string(tempname) + ".json";

fileId = fopen(campaignFile, "w");
assert(fileId >= 0);

cleanup = onCleanup(@() fclose(fileId));

fprintf(fileId, "%s", ...
    jsonencode(campaign, PrettyPrint=true));

clear cleanup

end



function outcome = fakeExecutor(~, ~, runDirectory)

runDirectory = string(runDirectory);

mkdir(runDirectory);
mkdir(fullfile(runDirectory, "config"));
mkdir(fullfile(runDirectory, "data"));
mkdir(fullfile(runDirectory, "validation"));

writeText( ...
    fullfile(runDirectory, "config", "resolved_config.json"), ...
    "{}");

writeText( ...
    fullfile(runDirectory, "data", "run_summary.json"), ...
    "{}");

writeText( ...
    fullfile(runDirectory, "validation", "validation_report.json"), ...
    '{"valid":true}');

writeText( ...
    fullfile(runDirectory, "data", "wavefield_sample.mat"), ...
    "placeholder");

outcome = struct();
outcome.status = "completed";
outcome.paths = struct();
outcome.paths.run = runDirectory;

end


function writeText(pathValue, content)

fileId = fopen(pathValue, "w");
assert(fileId >= 0);

cleanup = onCleanup(@() fclose(fileId));
fprintf(fileId, "%s", content);

end


function cleanupPaths(campaignFile, outputRoot)

deleteIfPresent(campaignFile);

if isfolder(outputRoot)
    rmdir(outputRoot, "s");
end

end


function deleteIfPresent(pathValue)

if isfile(pathValue)
    delete(pathValue);
end

end
