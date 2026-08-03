function result = runCampaignSet(campaign_files, options)
%RUNCAMPAIGNSET Validate and execute multiple simulation campaigns.
%
% The input order is preserved. Each campaign is executed through
% simcampaigns.runCampaign, and a combined report is returned.
%
% This function does not combine campaign_runs.csv files. It reports the
% path produced by each campaign so downstream tools can accumulate them.

arguments
    campaign_files (:,1) string

    options.Resume (1,1) logical = true
    options.ContinueOnError (1,1) logical = false
    options.Executor = []
end

validate_campaign_files(campaign_files);

campaign_count = numel(campaign_files);

records = repmat(empty_campaign_record(), ...
    campaign_count, 1);

for index = 1:campaign_count
    campaign_file = campaign_files(index);

    fprintf("\n");
    fprintf("============================================================\n");
    fprintf("Campaign %d of %d\n", index, campaign_count);
    fprintf("File: %s\n", campaign_file);

    try
        if isempty(options.Executor)
            report = simcampaigns.runCampaign( ...
                campaign_file, ...
                Resume=options.Resume, ...
                ContinueOnError=options.ContinueOnError);
        else
            report = simcampaigns.runCampaign( ...
                campaign_file, ...
                Resume=options.Resume, ...
                ContinueOnError=options.ContinueOnError, ...
                Executor=options.Executor);
        end

        records(index) = record_from_report( ...
            campaign_file, report);

    catch exception
        records(index) = record_from_exception( ...
            campaign_file, exception);

        if ~options.ContinueOnError
            rethrow(exception);
        end
    end
end

result = struct();

result.schema_name = ...
    "simcampaigns_campaign_set_report";

result.schema_version = "1.0";

result.campaign_count = campaign_count;

result.run_count = sum([records.run_count]);
result.completed_count = sum([records.completed_count]);
result.skipped_count = sum([records.skipped_count]);
result.failed_count = sum([records.failed_count]);

result.campaign_error_count = ...
    nnz(strlength(string({records.error_identifier})') > 0);

result.success = ...
    result.failed_count == 0 && ...
    result.campaign_error_count == 0 && ...
    all([records.success]);

result.campaigns = records;

end


function validate_campaign_files(files)

if isempty(files)
    error("simcampaigns:EmptyCampaignSet", ...
        "At least one campaign file is required.");
end

if numel(unique(files)) ~= numel(files)
    error("simcampaigns:DuplicateCampaignSetFile", ...
        "Each campaign file may appear only once.");
end

for index = 1:numel(files)
    if strlength(files(index)) == 0
        error("simcampaigns:InvalidCampaignSetFile", ...
            "Campaign file paths must be non-empty.");
    end

    if ~isfile(files(index))
        error("simcampaigns:CampaignSetFileNotFound", ...
            "Campaign file was not found: %s", ...
            files(index));
    end
end

end


function record = record_from_report(campaign_file, report)

record = empty_campaign_record();

record.campaign_file = string(campaign_file);
record.campaign_name = string(report.campaign_name);
record.campaign_directory = ...
    string(report.campaign_directory);

record.campaign_runs_csv = fullfile( ...
    record.campaign_directory, ...
    "campaign_runs.csv");

record.run_count = double(report.run_count);
record.completed_count = double(report.completed_count);
record.skipped_count = double(report.skipped_count);
record.failed_count = double(report.failed_count);
record.success = logical(report.success);

end


function record = record_from_exception(campaign_file, exception)

record = empty_campaign_record();

record.campaign_file = string(campaign_file);
record.success = false;
record.failed_count = 1;
record.error_identifier = string(exception.identifier);
record.error_message = string(exception.message);

end


function record = empty_campaign_record()

record = struct( ...
    "campaign_file", "", ...
    "campaign_name", "", ...
    "campaign_directory", "", ...
    "campaign_runs_csv", "", ...
    "run_count", 0, ...
    "completed_count", 0, ...
    "skipped_count", 0, ...
    "failed_count", 0, ...
    "success", false, ...
    "error_identifier", "", ...
    "error_message", "");

end
