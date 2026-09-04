function report = run_campaign(options)
%RUN_CAMPAIGN Validate or execute the small 2D field-regime campaign.
arguments
    options.Execute (1,1) logical = false
    options.PlotRuns (1,1) logical = false
    options.GenerateReports (1,1) logical = false
end
exampleRoot=fileparts(mfilename("fullpath"));
repoRoot=fileparts(fileparts(fileparts(fileparts(exampleRoot))));
addpath(fullfile(repoRoot,"src"));
campaignFile=fullfile(exampleRoot,"campaign.json");
[runs,validation]=simcampaigns.validateCampaign(campaignFile);
printSummary(runs,validation,"2D synthetic field-regime campaign");
if ~options.Execute
    report=struct("runs",runs,"validation",validation);
    return
end
report=simcampaigns.runCampaign(campaignFile);
postprocess(report,options.PlotRuns,options.GenerateReports);
end

function postprocess(report,plotRuns,generateReports)
for i=1:numel(report.runs)
    status=string(report.runs(i).status);
    if status~="completed" && status~="skipped_completed", continue; end
    runDir=string(report.runs(i).run_directory);
    if plotRuns || generateReports, simviz.generateRunFigures(runDir); end
    if generateReports, simreport.generateRunPdf(runDir); end
end
if generateReports, simreport.generateCampaignPdf(report); end
end

function printSummary(runs,validation,titleText)
fprintf("\n%s\n",titleText); fprintf("Runs:   %d\n",numel(runs));
fprintf("Valid:  %d\n",validation.valid); fprintf("Failed: %d\n",validation.failed_count);
fprintf("\nRegime definitions:\n");
conditions=string({runs.condition_id})'; counts=arrayfun(@(r) r.config.directions.count,runs)';
for regime=["directional","intermediate","diffuse"]
    fprintf("  %-12s N = %d\n",regime,unique(counts(conditions==regime)));
end
end
