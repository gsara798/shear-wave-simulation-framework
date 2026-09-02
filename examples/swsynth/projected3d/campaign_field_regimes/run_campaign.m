function report = run_campaign(options)
%RUN_CAMPAIGN Validate or execute the projected-3D inclusion field-regime campaign.
%
% The campaign compares three wavefield regimes while keeping the medium,
% frequency, projected-3D Eikonal propagation, and full-sphere angular
% support fixed:
%   directional  -> 1 direction
%   intermediate -> 16 directions
%   diffuse      -> 128 directions

arguments
    options.Execute (1,1) logical = false
end

example_root = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(fileparts(example_root))));
addpath(fullfile(repo_root, "src"));

campaign_file = fullfile(example_root, "campaign.json");

[runs, validation] = simcampaigns.validateCampaign(campaign_file);

fprintf("\nProjected-3D inclusion field-regime campaign\n");
fprintf("Runs:   %d\n", numel(runs));
fprintf("Valid:  %d\n", validation.valid);
fprintf("Failed: %d\n", validation.failed_count);

conditions = string({runs.condition_id})';
counts = arrayfun(@(run) run.config.directions.count, runs)';

fprintf("\nRegime definitions:\n");
for regime = ["directional", "intermediate", "diffuse"]
    mask = conditions == regime;
    fprintf("  %-12s N = %d, realizations = %d\n", ...
        regime, unique(counts(mask)), nnz(mask));
end

if ~options.Execute
    report = struct();
    report.runs = runs;
    report.validation = validation;
    return
end

report = simcampaigns.runCampaign(campaign_file);
end
