function outcome = run_example(options)
%RUN_EXAMPLE Run the volumetric inclusion example through the unified runner.
arguments
    options.DryRun (1,1) logical = false
    options.PlotFigures (1,1) logical = true
    options.FigureVisible = "off"
    options.GeneratePdf (1,1) logical = false
end

exampleDir = string(fileparts(mfilename("fullpath")));
repositoryRoot = fileparts(fileparts(fileparts(fileparts(exampleDir))));
addpath(repositoryRoot);
setup(Quiet=true);

outcome = run_simulation( ...
    fullfile(exampleDir,"config.json"), ...
    DryRun=options.DryRun, ...
    PlotFigures=options.PlotFigures, ...
    FigureVisible=options.FigureVisible, ...
    GeneratePdf=options.GeneratePdf);
end
