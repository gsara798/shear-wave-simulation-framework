%% Generic explicit campaign example
%
% This example demonstrates the complete campaign-construction lifecycle:
%
%   scientific plan
%       -> makeExplicitRuns
%       -> writeCampaign
%       -> expandCampaign
%       -> validateCampaign
%
% It intentionally stops before running the simulations.

repo_root = string(fileparts(fileparts(fileparts(mfilename("fullpath")))));
addpath(fullfile(repo_root,"src"));

%% 1. Scientific run plan

plan = table( ...
    ["example_a";"example_b"], ...
    ["condition_a";"condition_b"], ...
    [1;1], ...
    [9101;9102], ...
    [300;500], ...
    [2.0;3.0], ...
    VariableNames=[ ...
        "design_id", ...
        "condition_id", ...
        "realization_id", ...
        "seed", ...
        "frequency_hz", ...
        "cs_m_s"]);

%% 2. Map plan columns to simulator configuration paths

mapping = [
    "seed"                       "seed"
    "wavefield.frequency_hz"     "frequency_hz"
    "medium.background_cs_m_s"   "cs_m_s"
];

%% 3. Build schema-1.2 explicit run definitions

definitions = simcampaigns.makeExplicitRuns( ...
    plan,mapping, ...
    ConditionIdColumn="condition_id", ...
    RealizationIdColumn="realization_id");

%% 4. Build the generic campaign struct

base_config = fullfile( ...
    repo_root, ...
    "configs","swsynth","scientific", ...
    "homogeneous_projected3d_clean_base.json");

output_root = fullfile( ...
    repo_root, ...
    "outputs","examples","explicit_campaign");

campaign_file = fullfile( ...
    output_root, ...
    "simulation_campaign.json");

campaign = struct();
campaign.schema_version = "1.2";
campaign.backend = "swsynth";
campaign.campaign_name = "explicit_campaign_example";
campaign.base_config = base_config;
campaign.runs = definitions;
campaign.output = struct( ...
    "directory", ...
    fullfile(output_root,"simulations"));

%% 5. Write and validate the campaign contract

result = simcampaigns.writeCampaign( ...
    campaign,campaign_file);

fprintf("Campaign written:\n%s\n\n",result.path);

%% 6. Expand the campaign

[runs,expansion] = ...
    simcampaigns.expandCampaign(campaign_file);

fprintf("Expanded runs: %d\n",numel(runs));
fprintf("Expansion mode: %s\n\n",expansion.order);

%% 7. Dry-run validation

[~,validation] = ...
    simcampaigns.validateCampaign(campaign_file);

fprintf("%s\n",validation.summary);

assert(validation.valid, ...
    "Example campaign did not pass dry-run validation.");

fprintf("\nExample completed successfully.\n");
fprintf("No simulations were executed.\n");
