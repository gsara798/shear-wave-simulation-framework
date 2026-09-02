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

fig=figure("Visible","off","Color","w","Position",[100 100 900 1150]);
cleanup=onCleanup(@() close(fig));
ax=axes(fig,"Position",[0.08 0.08 0.84 0.84]); axis(ax,"off");
lines=[
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
text(ax,0,1,strjoin(lines,newline),"VerticalAlignment","top","Interpreter","none", ...
    "FontName","Times New Roman","FontSize",14);
exportgraphics(fig,pdfFile,"ContentType","vector");
clear cleanup; close(fig);

if ~options.IncludeRepresentativeRuns || ~isfield(report,"runs") || isempty(report.runs), return; end
conditions=string({report.runs.condition_id});
if all(strlength(conditions)==0)
    selected=1:min(3,numel(report.runs));
else
    uniqueConditions=unique(conditions(strlength(conditions)>0),"stable");
    selected=zeros(1,numel(uniqueConditions));
    for i=1:numel(uniqueConditions)
        selected(i)=find(conditions==uniqueConditions(i),1,"first");
    end
end
for idx=selected
    runDir=string(report.runs(idx).run_directory);
    if ~isfolder(runDir), continue; end
    try
        simviz.generateRunFigures(runDir);
    catch exception
        warning("simreport:RepresentativeRunFiguresFailed","%s",exception.message);
        continue
    end
    figDir=fullfile(runDir,"figures");
    for name=["sws.png","wavefield_real.png","wavefield_phase.png","wavefield_amplitude.png","directions.png"]
        pathValue=fullfile(figDir,name);
        if isfile(pathValue), appendImagePage(pathValue,pdfFile); end
    end
end
end

function appendImagePage(imageFile,pdfFile)
img=imread(imageFile);
fig=figure("Visible","off","Color","w","Position",[100 100 900 1150]);
cleanup=onCleanup(@() close(fig));
ax=axes(fig,"Position",[0.03 0.03 0.94 0.94]); image(ax,img); axis(ax,"image"); axis(ax,"off");
exportgraphics(fig,pdfFile,"ContentType","image","Append",true,"Resolution",200);
clear cleanup; close(fig);
end
