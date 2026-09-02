function report = run_campaign(options)
%RUN_CAMPAIGN Validate and execute the self-contained campaign example.

arguments
    options.Execute (1,1) logical = false
    options.Resume (1,1) logical = true
end

example_dir = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(example_dir)));
addpath(fullfile(repo_root,"src"));

campaign_file = fullfile(example_dir,"campaign.json");

[runs, validation] = simcampaigns.validateCampaign(campaign_file);

fprintf("Campaign validation\n");
fprintf("  Runs:   %d\n", numel(runs));
fprintf("  Valid:  %d\n", validation.valid);
fprintf("  Failed: %d\n", validation.failed_count);

if ~options.Execute
    report = struct();
    report.mode = "validation_only";
    report.runs = runs;
    report.validation = validation;
    fprintf("\nSet Execute=true to run the full campaign.\n");
    return
end

report = simcampaigns.runCampaign( ...
    campaign_file, ...
    Resume=options.Resume, ...
    ContinueOnError=false);

fprintf("\n%s\n", report.summary);
end
