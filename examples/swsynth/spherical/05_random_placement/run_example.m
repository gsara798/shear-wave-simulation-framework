function outcome = run_example(options)
%RUN_EXAMPLE random sources on a spherical shell with per-source excitations.
arguments
    options.DryRun (1,1) logical = false
    options.PlotFigures (1,1) logical = true
    options.FigureVisible = "off"
    options.GeneratePdf (1,1) logical = false
end
exampleDir=string(fileparts(mfilename("fullpath")));
repositoryRoot=string(fileparts(fileparts(fileparts(fileparts(exampleDir)))));
addpath(repositoryRoot);
setup_simulation_framework(Quiet=true);
outcome=run_simulation(fullfile(exampleDir,"config.json"), ...
    DryRun=options.DryRun,PlotFigures=options.PlotFigures, ...
    FigureVisible=options.FigureVisible,GeneratePdf=options.GeneratePdf);
end
