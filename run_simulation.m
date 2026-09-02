function outcome = run_simulation(configFile, options)
%RUN_SIMULATION Run any framework JSON configuration from the repository root.
%
% Typical use:
%   setup
%   outcome = run_simulation("examples/kwave/2d/inclusion/config.json");
%
arguments
    configFile {mustBeTextScalar}
    options.Backend {mustBeTextScalar} = "auto"
    options.OutputRoot {mustBeTextScalar} = ""
    options.DryRun (1,1) logical = false
    options.PlotFigures (1,1) logical = true
    options.FigureVisible = "off"
    options.GeneratePdf (1,1) logical = false
end

repositoryRoot = string(fileparts(mfilename("fullpath")));
sourceDirectory = fullfile(repositoryRoot,"src");
if ~contains(path,sourceDirectory)
    addpath(sourceDirectory);
end

outcome = simrunner.runConfig( ...
    configFile, ...
    Backend=options.Backend, ...
    OutputRoot=options.OutputRoot, ...
    DryRun=options.DryRun, ...
    PlotFigures=options.PlotFigures, ...
    FigureVisible=options.FigureVisible, ...
    GeneratePdf=options.GeneratePdf);
end
