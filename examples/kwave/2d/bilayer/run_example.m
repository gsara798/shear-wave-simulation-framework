function outcome = run_example(options)
%RUN_EXAMPLE Run the 2D k-Wave bilayer example.
arguments
    options.DryRun (1,1) logical = false
    options.PlotFigures (1,1) logical = true
    options.FigureVisible (1,1) string = "off"
end

example_dir = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(example_dir)));
addpath(fullfile(repo_root,"src"));

outcome = kwsim.cli.runConfig( ...
    fullfile(example_dir,"config.json"), ...
    DryRun=options.DryRun);

if ~options.DryRun && options.PlotFigures
    outcome.standard_figure_files = simviz.generateRunFigures( ...
        outcome.paths.run, Visible=options.FigureVisible);
end
end
