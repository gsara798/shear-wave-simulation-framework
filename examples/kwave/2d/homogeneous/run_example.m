function outcome = run_example(options)
%RUN_EXAMPLE Run the self-contained 2D homogeneous k-Wave example.
arguments
    options.DryRun (1,1) logical = false
    options.PlotFigures (1,1) logical = true
    options.FigureVisible (1,1) string = "off"
    options.ShowValidationPlot (1,1) logical = false
end

example_dir = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(example_dir)));
addpath(fullfile(repo_root,"src"));
addpath(fullfile(repo_root,"examples"));

config_file = fullfile(example_dir,"config.json");
outcome = kwsim.cli.runConfig(config_file, DryRun=options.DryRun);

if ~options.DryRun && options.PlotFigures
    outcome.standard_figure_files = simviz.generateRunFigures( ...
        outcome.paths.run, Visible=options.FigureVisible);
end
if ~options.DryRun && options.ShowValidationPlot
    plot_validation_checks(outcome.report);
end
end
