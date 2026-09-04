function report = run_campaign(options)
%RUN_CAMPAIGN Validate or execute the projected-3D inclusion field-regime campaign.
arguments
    options.Execute (1,1) logical = true
    options.PlotRuns (1,1) logical = true
    options.GenerateReports (1,1) logical = false
    options.PlotComparison (1,1) logical = false
end
exampleRoot=fileparts(mfilename("fullpath"));
repoRoot=fileparts(fileparts(fileparts(fileparts(exampleRoot))));
addpath(fullfile(repoRoot,"src")); addpath(exampleRoot);
campaignFile=fullfile(exampleRoot,"campaign.json");
[runs,validation]=simcampaigns.validateCampaign(campaignFile);

fprintf("\nProjected-3D inclusion field-regime campaign\n");
fprintf("Runs:   %d\n",numel(runs)); fprintf("Valid:  %d\n",validation.valid);
fprintf("Failed: %d\n",validation.failed_count);
conditions=string({runs.condition_id})'; counts=arrayfun(@(r) r.config.directions.count,runs)';
fprintf("\nRegime definitions:\n");
for regime=["directional","intermediate","diffuse"]
    mask=conditions==regime;
    fprintf("  %-12s N = %d, realizations = %d\n",regime,unique(counts(mask)),nnz(mask));
end

if ~options.Execute
    report=struct("runs",runs,"validation",validation);
    return
end
report=simcampaigns.runCampaign(campaignFile);
for i=1:numel(report.runs)
    status=string(report.runs(i).status);
    if status~="completed" && status~="skipped_completed", continue; end
    runDir=string(report.runs(i).run_directory);
    if options.PlotRuns || options.GenerateReports, simviz.generateRunFigures(runDir); end
    if options.GenerateReports, simreport.generateRunPdf(runDir); end
end
if options.GenerateReports, simreport.generateCampaignPdf(report); end
if options.PlotComparison, plot_campaign(report); end
end
