function pdfFile = generateCampaignPdf(report, options)
%GENERATECAMPAIGNPDF Build a summary PDF for a completed campaign.
arguments
    report (1,1) struct
    options.IncludeRepresentativeRuns (1,1) logical = true
end

campaignDir = string(report.campaign_directory);
reportDir = fullfile(campaignDir,"report");
if ~isfolder(reportDir), mkdir(reportDir); end
pdfFile = fullfile(reportDir,"campaign_report.pdf");
if isfile(pdfFile), delete(pdfFile); end

fig = figure("Visible","off","Color","w","Position",[100 100 900 1150]);
cleanup = onCleanup(@() closeIfValid(fig));
ax = axes(fig,"Position",[0.08 0.08 0.84 0.84]); axis(ax,"off");
lines = [
    "Simulation campaign report"
    ""
    "Campaign: " + string(report.campaign_name)
    "Backend: " + string(report.backend)
    "Runs: " + string(report.run_count)
    "Completed: " + string(report.completed_count)
    "Resumed: " + string(report.skipped_count)
    "Failed: " + string(report.failed_count)
    "Blocked: " + string(report.blocked_count)
    "Updated: " + string(report.updated)
];
text(ax,0,1,strjoin(lines,newline),"VerticalAlignment","top", ...
    "Interpreter","none","FontName","Times New Roman","FontSize",14);
exportgraphics(fig,pdfFile,"ContentType","vector");
clear cleanup
closeIfValid(fig);

if ~options.IncludeRepresentativeRuns || ~isfield(report,"runs") || isempty(report.runs), return; end
conditions = string({report.runs.condition_id});
if all(strlength(conditions)==0)
    selected = 1:min(3,numel(report.runs));
else
    uniqueConditions = unique(conditions(strlength(conditions)>0),"stable");
    selected = zeros(1,numel(uniqueConditions));
    for i=1:numel(uniqueConditions)
        selected(i)=find(conditions==uniqueConditions(i),1,"first");
    end
end

figureNames = [ ...
    "sws.png", ...
    "wavefield_real.png", ...
    "wavefield_phase.png", ...
    "wavefield_amplitude.png", ...
    "directions.png", ...
    "sws_crossplanes.png", ...
    "wavefield_real_crossplanes.png", ...
    "wavefield_phase_crossplanes.png", ...
    "wavefield_amplitude_crossplanes.png", ...
    "source_geometry.png"];

for idx=selected
    runDir=string(report.runs(idx).run_directory);
    if ~isfolder(runDir), continue; end
    try
        simviz.generateRunFigures(runDir);
    catch exception
        warning("simreport:RepresentativeRunFiguresFailed","%s",exception.message);
        continue
    end
    condition=string(report.runs(idx).condition_id);
    appendRunHeaderPage(report.runs(idx),condition,pdfFile);
    figDir=fullfile(runDir,"figures");
    for name=figureNames
        pathValue=fullfile(figDir,name);
        if isfile(pathValue), appendImagePage(pathValue,pdfFile); end
    end
end
end

function appendRunHeaderPage(run,condition,pdfFile)
fig=figure("Visible","off","Color","w","Position",[100 100 900 1150]);
cleanup=onCleanup(@() closeIfValid(fig));
ax=axes(fig,"Position",[0.08 0.08 0.84 0.84]); axis(ax,"off");
config=run.config;
lines=[
    upper(condition)
    ""
    "Run: " + string(run.run_id)
    "Realization: " + numberText(fieldNumber(run,"realization_id"))
    "Directions: " + numberText(nestedNumber(config,["directions","count"]))
    "In-plane directions: " + numberText(nestedNumber(config,["directions","in_plane_count"]))
    "Frequency: " + numberText(nestedNumber(config,["wavefield","frequency_hz"])) + " Hz"
    "Background SWS: " + numberText(nestedNumber(config,["medium","background_cs_m_s"])) + " m/s"
    "Direction space: " + nestedText(config,["directions","space"])
    "Propagation model: " + nestedText(config,["propagation","model"])
    "Phase model: " + nestedText(config,["propagation","phase_model"])
];
text(ax,0,1,strjoin(lines,newline),"VerticalAlignment","top", ...
    "Interpreter","none","FontName","Times New Roman","FontSize",14);
exportgraphics(fig,pdfFile,"ContentType","vector","Append",true);
clear cleanup
closeIfValid(fig);
end

function appendImagePage(imageFile,pdfFile)
img=imread(imageFile);
fig=figure("Visible","off","Color","w","Position",[100 100 900 1150]);
cleanup=onCleanup(@() closeIfValid(fig));
ax=axes(fig,"Position",[0.03 0.03 0.94 0.94]); image(ax,img); axis(ax,"image"); axis(ax,"off");
exportgraphics(fig,pdfFile,"ContentType","image","Append",true,"Resolution",200);
clear cleanup
closeIfValid(fig);
end

function closeIfValid(fig)
if isgraphics(fig,"figure"), close(fig); end
end
function value=nestedText(s,path)
value=""; current=s;
for p=path
    if ~isstruct(current)||~isfield(current,p), return; end
    current=current.(p);
end
if ischar(current)||isstring(current), value=string(current); end
end
function value=nestedNumber(s,path)
value=NaN; current=s;
for p=path
    if ~isstruct(current)||~isfield(current,p), return; end
    current=current.(p);
end
if (isnumeric(current)||islogical(current))&&isscalar(current), value=double(current); end
end
function value=fieldNumber(s,name)
value=NaN;
if isstruct(s)&&isfield(s,name)
    candidate=s.(name);
    if (isnumeric(candidate)||islogical(candidate))&&isscalar(candidate), value=double(candidate); end
end
end
function textValueOut=numberText(value)
if isfinite(value), textValueOut=string(sprintf("%.6g",value)); else, textValueOut="n/a"; end
end
