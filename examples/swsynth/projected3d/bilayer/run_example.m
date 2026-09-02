function outcome = run_example(options)
%RUN_EXAMPLE Run the self-contained bilayer swsynth example.

arguments
    options.DryRun (1,1) logical = false
    options.ShowPlot (1,1) logical = true
    options.OutputDirectory {mustBeTextScalar} = ""
end

example_dir = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(example_dir)));
addpath(fullfile(repo_root,"src"));
addpath(fullfile(repo_root,"examples"));

config_file = fullfile(example_dir,"config.json");
outcome = swsynth.cli.runConfig( ...
    config_file, ...
    DryRun=options.DryRun, ...
    OutputDirectory=options.OutputDirectory);

if ~options.DryRun && options.ShowPlot
    plot_wavefield_sample( ...
        outcome.result.sample, ...
        "SWSYNTH bilayer example");
end
end
