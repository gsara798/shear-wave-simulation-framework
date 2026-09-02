function outcome = run_homogeneous_3d(options)
%RUN_HOMOGENEOUS_3D Run the public 3D homogeneous k-Wave example.

arguments
    options.DryRun (1,1) logical = false
    options.ShowValidationPlot (1,1) logical = true
end

repo_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(repo_root, "src"));
addpath(fullfile(repo_root, "examples"));

config_file = fullfile(repo_root, "configs", "kwsim", "three_d", ...
    "homogeneous_directional_cli.json");

outcome = kwsim.cli.runConfig(config_file, DryRun=options.DryRun);

if ~options.DryRun && options.ShowValidationPlot
    plot_validation_checks(outcome.report);
end
end
