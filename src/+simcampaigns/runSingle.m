function outcome = runSingle(config, backend, options)
%RUNSINGLE Execute one simulation with the campaign run-directory contract.
%
% outcome = simcampaigns.runSingle(config,"swsynth",OutputRoot="outputs")
%
% The saved layout matches campaign runs:
%   config/resolved_config.json
%   data/run_summary.json
%   data/wavefield_sample.mat
%   figures/
%   validation/validation_report.json
%
arguments
    config (1,1) struct
    backend {mustBeTextScalar}
    options.OutputRoot {mustBeTextScalar} = "outputs"
    options.RunName {mustBeTextScalar} = ""
    options.PlotFigures (1,1) logical = true
    options.FigureVisible (1,1) string = "off"
    options.GeneratePdf (1,1) logical = false
end

backend = lower(string(backend));
outputRoot = string(options.OutputRoot);
runName = string(options.RunName);
if strlength(runName) == 0
    if isfield(config,"scenario") && strlength(string(config.scenario)) > 0
        runName = string(config.scenario);
    else
        runName = backend + "_run";
    end
end

runName = sanitizeName(runName);
timestamp = string(datetime("now","Format","yyyyMMdd_HHmmss_SSS"));
runDirectory = fullfile(outputRoot,runName + "_" + timestamp);

outcome = simcampaigns.backends.executeRun(config,backend,runDirectory);
outcome.run_directory = string(outcome.paths.run);

if options.PlotFigures
    outcome.figure_files = simviz.generateRunFigures( ...
        outcome.paths.run, Visible=options.FigureVisible);
else
    outcome.figure_files = struct();
end

if options.GeneratePdf
    outcome.pdf_file = simreport.generateRunPdf(outcome.paths.run);
else
    outcome.pdf_file = "";
end
end

function value = sanitizeName(value)
value = regexprep(string(value),'[^A-Za-z0-9_-]+','_');
value = strip(value,'_');
if strlength(value) == 0
    value = "simulation_run";
end
end
