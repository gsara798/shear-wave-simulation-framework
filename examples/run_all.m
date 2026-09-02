function results = run_all(options)
%RUN_ALL Run or dry-run the self-contained public examples.

arguments
    options.RunSwsynth (1,1) logical = true
    options.RunKWave (1,1) logical = false
end

examples_root = fileparts(mfilename("fullpath"));
repo_root = fileparts(examples_root);
addpath(fullfile(repo_root,"src"));

results = struct();

synthetic_names = ["homogeneous","inclusion","bilayer"];
for index = 1:numel(synthetic_names)
    name = synthetic_names(index);
    config_file = fullfile( ...
        examples_root,"swsynth",name,"config.json");
    results.swsynth.(name) = swsynth.cli.runConfig( ...
        config_file, DryRun=~options.RunSwsynth);
end

kwave_names = ["homogeneous_2d","homogeneous_3d"];
for index = 1:numel(kwave_names)
    name = kwave_names(index);
    config_file = fullfile( ...
        examples_root,"kwave",name,"config.json");
    results.kwave.(name) = kwsim.cli.runConfig( ...
        config_file, DryRun=~options.RunKWave);
end

campaign_file = fullfile( ...
    examples_root,"swsynth","campaign","campaign.json");
[~,results.campaign_validation] = ...
    simcampaigns.validateCampaign(campaign_file);
end
