function tests = test_simcampaigns_configuration
%TEST_SIMCAMPAIGNS_CONFIGURATION Test generic campaign loading and expansion.

tests = functiontests(localfunctions);

end

function setupOnce(testCase)

repository_root = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repository_root, "src"));

testCase.TestData.repository_root = ...
    string(repository_root);

end

function testLegacyCampaignDefaultsToKwsim(testCase)

campaign_file = fullfile( ...
    testCase.TestData.repository_root, ...
    "configs", ...
    "campaigns", ...
    "kwsim", ...
    "smoke", ...
    "homogeneous_partial_3d_n8_p2_smoke.json");

[campaign, metadata] = ...
    simcampaigns.loadCampaignJson(campaign_file);

verifyEqual(testCase, ...
    campaign.schema_version, ...
    "1.0");

verifyEqual(testCase, ...
    campaign.backend, ...
    "kwsim");

verifyEqual(testCase, ...
    metadata.expanded_run_count, ...
    2);

verifyEqual(testCase, ...
    metadata.base_config.dimension, ...
    3);

end

function testLoadsSwsynthCampaign(testCase)

campaign_file = fullfile( ...
    testCase.TestData.repository_root, ...
    "configs", ...
    "campaigns", ...
    "swsynth", ...
    "smoke", ...
    "swsynth_v2_homogeneous_smoke.json");

[campaign, metadata] = ...
    simcampaigns.loadCampaignJson(campaign_file);

verifyEqual(testCase, ...
    campaign.schema_version, ...
    "1.1");

verifyEqual(testCase, ...
    campaign.backend, ...
    "swsynth");

verifyEqual(testCase, ...
    metadata.expanded_run_count, ...
    4);

verifyTrue(testCase, ...
    string(metadata.base_config.schema_version)=="2.0");

end

function testResolvesCampaignLocalBaseConfig(testCase)

source_campaign = fullfile( ...
    testCase.TestData.repository_root, ...
    "configs", "campaigns", "swsynth", "smoke", ...
    "swsynth_v2_homogeneous_smoke.json");

requested = jsondecode(fileread(source_campaign));
source_base = fullfile( ...
    testCase.TestData.repository_root, ...
    string(requested.base_config));

temporary_directory = string(tempname);
mkdir(temporary_directory);
cleanup = onCleanup(@() rmdir(temporary_directory, "s"));

local_base = fullfile(temporary_directory, "base_config.json");
copyfile(source_base, local_base);

requested.base_config = "base_config.json";
campaign_file = fullfile(temporary_directory, "campaign.json");
writeJson(campaign_file, requested);

[campaign, metadata] = simcampaigns.loadCampaignJson(campaign_file);

verifyEqual(testCase, campaign.base_config, local_base);
verifyEqual(testCase, metadata.base_config_file, local_base);

clear cleanup

end

function testFallsBackToRepositoryRootBaseConfig(testCase)

campaign_file = fullfile( ...
    testCase.TestData.repository_root, ...
    "configs", "campaigns", "swsynth", "smoke", ...
    "swsynth_v2_homogeneous_smoke.json");

requested = jsondecode(fileread(campaign_file));

temporary_campaign = string(tempname) + ".json";
cleanup = onCleanup(@() cleanupFiles(temporary_campaign));
writeJson(temporary_campaign, requested);

[campaign, metadata] = ...
    simcampaigns.loadCampaignJson(temporary_campaign);

[~, attributes] = fileattrib(fullfile( ...
    testCase.TestData.repository_root, ...
    string(requested.base_config)));
expected = string(attributes.Name);

verifyEqual(testCase, campaign.base_config, expected);
verifyEqual(testCase, metadata.base_config_file, expected);

clear cleanup

end

function testSupportsAbsoluteBaseConfig(testCase)

source_campaign = fullfile( ...
    testCase.TestData.repository_root, ...
    "configs", "campaigns", "swsynth", "smoke", ...
    "swsynth_v2_homogeneous_smoke.json");

requested = jsondecode(fileread(source_campaign));
requested.base_config = fullfile( ...
    testCase.TestData.repository_root, ...
    string(requested.base_config));

temporary_campaign = string(tempname) + ".json";
cleanup = onCleanup(@() cleanupFiles(temporary_campaign));
writeJson(temporary_campaign, requested);

[campaign, metadata] = ...
    simcampaigns.loadCampaignJson(temporary_campaign);

[~, attributes] = fileattrib(requested.base_config);
expected = string(attributes.Name);
verifyEqual(testCase, campaign.base_config, expected);
verifyEqual(testCase, metadata.base_config_file, expected);

clear cleanup

end

function testExpandsSwsynthCartesianSweep(testCase)

campaign_file = fullfile( ...
    testCase.TestData.repository_root, ...
    "configs", ...
    "campaigns", ...
    "swsynth", ...
    "smoke", ...
    "swsynth_v2_homogeneous_smoke.json");

[runs, expansion] = ...
    simcampaigns.expandCampaign(campaign_file);

verifyEqual(testCase, ...
    expansion.backend, ...
    "swsynth");

verifyEqual(testCase, ...
    expansion.run_count, ...
    4);

verifyEqual(testCase, ...
    string({runs.backend})', ...
    repmat("swsynth", 4, 1));

verifyTrue(testCase,all(arrayfun(@(run) ... 
    run.config.seed==53053,runs)));
values = arrayfun(@(run) run.config.medium.cs_m_s,runs);
verifyEqual(testCase,sort(values(:)),[2;2;3;3]);
frequencies=arrayfun(@(run) ...
    run.config.excitation.frequency_hz,runs);
verifyEqual(testCase,sort(frequencies(:)),[400;400;500;500]);

verifyEqual(testCase, ...
    numel(unique(string({runs.run_id}))), ...
    4);

end

function testGetsIndexedCellObjectProperty(testCase)

config = struct();
config.medium = struct();
config.medium.objects = {
    struct( ...
        "type", "circle", ...
        "cs_m_s", 2.5, ...
        "radius_m", 0.01)
    };

value = simcampaigns.getPathValue( ...
    config, ...
    "medium.objects[1].cs_m_s");

verifyEqual(testCase, value, 2.5);

end

function testSetsIndexedCellObjectProperty(testCase)

config = struct();
config.medium = struct();
config.medium.objects = {
    struct( ...
        "type", "circle", ...
        "cs_m_s", 2.5, ...
        "radius_m", 0.01)
    };

updated = simcampaigns.setPathValue( ...
    config, ...
    "medium.objects[1].cs_m_s", ...
    4.0);

verifyEqual(testCase, ...
    updated.medium.objects{1}.cs_m_s, ...
    4.0);

verifyEqual(testCase, ...
    updated.medium.objects{1}.radius_m, ...
    0.01);

verifyEqual(testCase, ...
    updated.medium.objects{1}.type, ...
    "circle");

verifyEqual(testCase, ...
    config.medium.objects{1}.cs_m_s, ...
    2.5);

end

function testExpandsStructuredRowSweepValues(testCase)

base_file_source=fullfile(testCase.TestData.repository_root, ...
    "configs","swsynth","v2","homogeneous_plane_base.json");
base_config=jsondecode(fileread(base_file_source));
base_config.incidence.direction_xyz=[1 0 0];
base_config.incidence.relative_amplitude=1;
base_config.incidence.phase_rad=0;

base_file = string(tempname) + ".json";
campaign_file = string(tempname) + ".json";

cleanup = onCleanup(@() cleanupFiles( ...
    [base_file, campaign_file]));

writeJson(base_file, base_config);

campaign = struct();
campaign.schema_version = "1.1";
campaign.backend = "swsynth";
campaign.campaign_name = "structured_row_sweep_test";
campaign.base_config = base_file;
campaign.sweep = struct( ...
    "path", "incidence.direction_xyz", ...
    "values", [ ...
        1, 0, 0; ...
        0, 0, 1; ...
        2^(-0.5), 0, 2^(-0.5)]);

writeJson(campaign_file, campaign);

[runs, expansion] = ...
    simcampaigns.expandCampaign(campaign_file);

verifyEqual(testCase, expansion.run_count, 3);

actual = vertcat(runs.config);
actual = vertcat(actual.incidence);
actual = vertcat(actual.direction_xyz);

expected = [ ...
    1, 0, 0; ...
    0, 0, 1; ...
    2^(-0.5), 0, 2^(-0.5)];

verifyEqual(testCase, actual, expected, AbsTol=1e-14);

clear cleanup

end

function writeJson(path_value, value)

file_id = fopen(path_value, "w");

if file_id < 0
    error("test:FileWriteFailed", ...
        "Could not create temporary JSON file.");
end

cleanup = onCleanup(@() fclose(file_id));

fprintf(file_id, "%s", ...
    jsonencode(value, PrettyPrint=true));

clear cleanup

end

function cleanupFiles(paths)

for path_value = string(paths)
    if isfile(path_value)
        delete(path_value);
    end
end

end
