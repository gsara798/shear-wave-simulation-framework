function report = run_campaign(campaignFile, options)
%RUN_CAMPAIGN Validate or execute any framework campaign JSON.
%
% Typical use:
%   setup_simulation_framework
%   report = run_campaign("path/to/campaign.json");
%
% Validate all expanded runs without executing solvers:
%   report = run_campaign("path/to/campaign.json", DryRun=true);

arguments
    campaignFile {mustBeTextScalar}
    options.DryRun (1,1) logical = false
    options.Resume (1,1) logical = true
    options.ContinueOnError (1,1) logical = true
    options.PlotFigures (1,1) logical = true
    options.FigureVisible = "off"
end

repositoryRoot = string(fileparts(mfilename("fullpath")));
sourceDirectory = fullfile(repositoryRoot,"src");
if ~contains(path,sourceDirectory)
    addpath(sourceDirectory);
end

campaignFile = resolveInputFile(repositoryRoot,string(campaignFile));

if options.DryRun
    [~,report] = simcampaigns.validateCampaign(campaignFile);
    fprintf("\n%s\n",report.summary);
    return
end

report = simcampaigns.runCampaign( ...
    campaignFile, ...
    Resume=options.Resume, ...
    ContinueOnError=options.ContinueOnError);

if options.PlotFigures
    visibility = simviz.normalizeVisible(options.FigureVisible);
    generateCampaignFigures(report,visibility);
end

fprintf("\n%s\n",report.summary);
fprintf("Output: %s\n",report.campaign_directory);
end

function campaignFile = resolveInputFile(repositoryRoot,campaignFile)
if isfile(campaignFile)
    campaignFile = absolutePath(campaignFile);
    return
end

if ~isAbsolutePath(campaignFile)
    repositoryRelative = fullfile(repositoryRoot,campaignFile);
    if isfile(repositoryRelative)
        campaignFile = absolutePath(repositoryRelative);
        return
    end
end

error("simulation:CampaignFileNotFound", ...
    "Campaign file not found: %s",campaignFile);
end

function generateCampaignFigures(report,visibility)
if ~isfield(report,"runs") || isempty(report.runs)
    return
end

for index = 1:numel(report.runs)
    status = string(report.runs(index).status);
    if ~ismember(status,["completed","skipped_completed"])
        continue
    end

    runDirectory = string(report.runs(index).run_directory);
    try
        simviz.generateRunFigures(runDirectory,Visible=visibility);
    catch exception
        warning("simulation:CampaignRunFiguresFailed", ...
            "Could not generate figures for %s: %s", ...
            runDirectory,exception.message);
    end
end
end

function value = absolutePath(value)
value = string(value);
if isAbsolutePath(value)
    return
end
value = string(char(java.io.File(char(fullfile(pwd,value))).getCanonicalPath()));
end

function tf = isAbsolutePath(value)
characters = char(string(value));
if ispc
    tf = ~isempty(regexp(characters,'^[A-Za-z]:[\\/]|^\\\\','once'));
else
    tf = startsWith(characters,filesep);
end
end
