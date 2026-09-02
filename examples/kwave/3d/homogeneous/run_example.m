function outcome = run_example(options)
arguments
    options.DryRun (1,1) logical = false
    options.ShowValidationPlot (1,1) logical = true
end
example_dir = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(example_dir)));
addpath(fullfile(repo_root,"src"));
addpath(fullfile(repo_root,"examples"));
config_file = fullfile(example_dir,"config.json");
outcome = kwsim.cli.runConfig(config_file, DryRun=options.DryRun);
if ~options.DryRun && options.ShowValidationPlot
    plot_validation_checks(outcome.report);
end
end
