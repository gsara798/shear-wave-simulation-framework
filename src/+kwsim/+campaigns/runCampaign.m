function report = runCampaign(campaign_file, options)
%RUNCAMPAIGN Validate and execute every run in one simulation campaign.
%
%   report = kwsim.campaigns.runCampaign(campaign_file)
%
% The campaign is fully dry-run validated before any output is created.
% Each simulation is then delegated to kwsim.cli.runConfig and saved in:
%
%   <campaign output>/<campaign name>/<run_id>/
%
% Completed runs can be resumed safely. A directory without a matching
% completion marker is treated as incomplete and is never overwritten.

arguments
    campaign_file {mustBeTextScalar}
    options.Resume (1,1) logical = true
    options.ContinueOnError (1,1) logical = true
    options.Runner (1,1) function_handle = @kwsim.cli.runConfig
end

[runs, validation] = ...
    kwsim.campaigns.validateCampaign(campaign_file);

if ~validation.valid
    error("kwsim:CampaignValidationFailed", ...
        "Campaign execution aborted: %d of %d runs failed dry-run validation.", ...
        validation.failed_count, validation.run_count);
end

[~, expansion] = ...
    kwsim.campaigns.expandCampaign(campaign_file);

campaign_directory = resolveCampaignDirectory(expansion);

empty_record = struct();
empty_record.ordinal = 0;
empty_record.run_id = "";
empty_record.hash_sha256 = "";
empty_record.status = "pending";
empty_record.outcome_status = "";
empty_record.run_directory = "";
empty_record.error_identifier = "";
empty_record.error_message = "";

records = repmat(empty_record, expansion.run_count, 1);

for index = 1:expansion.run_count
    records(index).ordinal = runs(index).ordinal;
    records(index).run_id = runs(index).run_id;
    records(index).hash_sha256 = runs(index).hash_sha256;
    records(index).run_directory = fullfile( ...
        campaign_directory, runs(index).run_id);
end

ensureDirectory(campaign_directory);

report = buildReport( ...
    expansion, campaign_directory, records);
writeCampaignSummary(report);
kwsim.campaigns.writeCampaignRunsCsv(report, runs);

for index = 1:expansion.run_count
    run = runs(index);
    run_directory = string(records(index).run_directory);
    marker_file = fullfile( ...
        run_directory, "campaign_run.json");

    [existing_state, existing_message] = ...
        inspectExistingRun( ...
            run_directory, ...
            marker_file, ...
            run.hash_sha256);

    if existing_state == "completed" && options.Resume
        records(index).status = "skipped_completed";
        records(index).outcome_status = ...
            readOutcomeStatus(marker_file);

        report = buildReport( ...
            expansion, campaign_directory, records);
        writeCampaignSummary(report);
kwsim.campaigns.writeCampaignRunsCsv(report, runs);
        continue
    end

    if existing_state ~= "absent"
        records(index).status = "blocked_existing";
        records(index).error_identifier = ...
            "kwsim:CampaignRunDirectoryExists";
        records(index).error_message = existing_message;

        report = buildReport( ...
            expansion, campaign_directory, records);
        writeCampaignSummary(report);
kwsim.campaigns.writeCampaignRunsCsv(report, runs);

        if ~options.ContinueOnError
            error(records(index).error_identifier, ...
                "%s", records(index).error_message);
        end
        continue
    end

    records(index).status = "running";
    report = buildReport( ...
        expansion, campaign_directory, records);
    writeCampaignSummary(report);
kwsim.campaigns.writeCampaignRunsCsv(report, runs);

    config = configureRunOutput( ...
        run.config, ...
        campaign_directory, ...
        run.run_id);

    config_file = writeTemporaryConfig(config);
    cleanup = onCleanup( ...
        @() deleteIfPresent(config_file));

    try
        outcome = options.Runner(config_file);

        records(index).status = "completed";
        records(index).outcome_status = ...
            textField(outcome, "status", "completed");

        verifyRunnerOutput( ...
            outcome, ...
            run_directory);

        writeCompletionMarker( ...
            marker_file, ...
            run, ...
            records(index).outcome_status);

    catch exception
        records(index).status = "failed";
        records(index).error_identifier = ...
            exceptionIdentifier(exception);
        records(index).error_message = ...
            singleLine(exception.message);
    end

    clear cleanup

    report = buildReport( ...
        expansion, campaign_directory, records);
    writeCampaignSummary(report);
kwsim.campaigns.writeCampaignRunsCsv(report, runs);

    if records(index).status == "failed" && ...
            ~options.ContinueOnError
        error(records(index).error_identifier, ...
            "%s", records(index).error_message);
    end
end

report = buildReport( ...
    expansion, campaign_directory, records);
writeCampaignSummary(report);
kwsim.campaigns.writeCampaignRunsCsv(report, runs);

end


function config = configureRunOutput( ...
        config, campaign_directory, run_id)

if ~isfield(config, "output") || ...
        ~isstruct(config.output) || ...
        ~isscalar(config.output)
    config.output = struct();
end

config.output.enabled = true;
config.output.directory = string(campaign_directory);
config.output.run_name = string(run_id);
config.output.append_timestamp = false;
config.output.overwrite = false;

end


function directory = resolveCampaignDirectory(expansion)

root_directory = string( ...
    expansion.campaign.output.directory);

if ~isAbsolutePath(root_directory)
    root_directory = fullfile( ...
        expansion.repository_root, ...
        root_directory);
end

directory = string(fullfile( ...
    root_directory, ...
    expansion.campaign.campaign_name));

end


function tf = isAbsolutePath(path)

path = char(string(path));

if ispc
    tf = ~isempty(regexp( ...
        path, '^[A-Za-z]:[\\/]|^\\\\', 'once'));
else
    tf = startsWith(path, filesep);
end

end


function [state, message] = inspectExistingRun( ...
        run_directory, marker_file, expected_hash)

if ~isfolder(run_directory)
    state = "absent";
    message = "";
    return
end

if ~isfile(marker_file)
    state = "incomplete";
    message = "Run directory exists without a completion marker: " + ...
        string(run_directory);
    return
end

try
    marker = jsondecode(fileread(marker_file));
catch
    state = "invalid_marker";
    message = "Run completion marker is not valid JSON: " + ...
        string(marker_file);
    return
end

if ~isfield(marker, "hash_sha256") || ...
        string(marker.hash_sha256) ~= string(expected_hash)
    state = "identity_mismatch";
    message = "Run directory contains a marker for a different run identity: " + ...
        string(run_directory);
    return
end

if ~isfield(marker, "status") || ...
        string(marker.status) ~= "completed"
    state = "invalid_marker";
    message = "Run completion marker does not record completed status: " + ...
        string(marker_file);
    return
end

state = "completed";
message = "";

end


function verifyRunnerOutput(outcome, expected_directory)

if ~isstruct(outcome) || ...
        ~isfield(outcome, "paths") || ...
        ~isstruct(outcome.paths) || ...
        ~isfield(outcome.paths, "run")
    error("kwsim:CampaignRunnerDidNotSaveOutput", ...
        "The campaign runner returned no saved run directory.");
end

actual_directory = canonicalPath(outcome.paths.run);
expected_directory = canonicalPath(expected_directory);

if actual_directory ~= expected_directory
    error("kwsim:CampaignRunnerOutputMismatch", ...
        "Runner saved '%s'; expected '%s'.", ...
        actual_directory, expected_directory);
end

if ~isfolder(expected_directory)
    error("kwsim:CampaignRunnerDidNotSaveOutput", ...
        "Runner did not create the expected directory: %s", ...
        expected_directory);
end

end


function path = canonicalPath(path)

path = string(path);

if ~isAbsolutePath(path)
    path = fullfile(string(pwd), path);
end

path = string(char(java.io.File(char(path)).getCanonicalPath()));

end


function writeCompletionMarker( ...
        marker_file, run, outcome_status)

marker = struct();
marker.schema_version = "1.0";
marker.status = "completed";
marker.ordinal = run.ordinal;
marker.run_id = run.run_id;
marker.hash_sha256 = run.hash_sha256;
marker.outcome_status = string(outcome_status);
marker.completed = string(datetime( ...
    "now", ...
    "Format", "yyyy-MM-dd HH:mm:ss Z"));

writeJsonAtomically(marker_file, marker);

end


function status = readOutcomeStatus(marker_file)

status = "";

try
    marker = jsondecode(fileread(marker_file));

    if isfield(marker, "outcome_status")
        status = string(marker.outcome_status);
    end
catch
    % inspectExistingRun already validated the marker.
end

end


function report = buildReport( ...
        expansion, campaign_directory, records)

statuses = string({records.status})';

report = struct();
report.schema_version = "1.0";
report.campaign_file = expansion.campaign_file;
report.campaign_name = expansion.campaign.campaign_name;
report.campaign_directory = string(campaign_directory);
report.run_count = expansion.run_count;
report.completed_count = sum(statuses == "completed");
report.skipped_count = sum(statuses == "skipped_completed");
report.failed_count = sum(statuses == "failed");
report.blocked_count = sum(statuses == "blocked_existing");
report.pending_count = sum(statuses == "pending");
report.running_count = sum(statuses == "running");
report.success = ...
    report.failed_count == 0 && ...
    report.blocked_count == 0 && ...
    report.pending_count == 0 && ...
    report.running_count == 0;
report.runs = records;
report.updated = string(datetime( ...
    "now", ...
    "Format", "yyyy-MM-dd HH:mm:ss Z"));

report.summary = string(sprintf( ...
    ['Campaign: %d completed, %d resumed, ' ...
     '%d failed, %d blocked, %d pending.'], ...
    report.completed_count, ...
    report.skipped_count, ...
    report.failed_count, ...
    report.blocked_count, ...
    report.pending_count + report.running_count));

end


function writeCampaignSummary(report)

summary_file = fullfile( ...
    report.campaign_directory, ...
    "campaign_summary.json");

writeJsonAtomically(summary_file, report);

end


function writeJsonAtomically(path, value)

temporary_path = string(path) + ".tmp";
deleteIfPresent(temporary_path);

file_id = fopen(temporary_path, "w");

if file_id < 0
    error("kwsim:CampaignSummaryWriteFailed", ...
        "Could not create file: %s", ...
        temporary_path);
end

cleanup = onCleanup(@() fclose(file_id));
fprintf(file_id, "%s", ...
    jsonencode(value, PrettyPrint=true));
clear cleanup

[moved, message] = movefile( ...
    temporary_path, path, "f");

if ~moved
    deleteIfPresent(temporary_path);
    error("kwsim:CampaignSummaryWriteFailed", ...
        "Could not publish file '%s': %s", ...
        path, message);
end

end


function config_file = writeTemporaryConfig(config)

config_file = string(tempname) + ".json";

file_id = fopen(config_file, "w");

if file_id < 0
    error("kwsim:TemporaryCampaignConfigWriteFailed", ...
        "Could not create a temporary expanded configuration.");
end

cleanup = onCleanup(@() fclose(file_id));
fprintf(file_id, "%s", ...
    jsonencode(config, PrettyPrint=true));
clear cleanup

end


function value = textField(value_struct, field_name, default_value)

if isfield(value_struct, field_name)
    value = string(value_struct.(field_name));
else
    value = string(default_value);
end

end


function identifier = exceptionIdentifier(exception)

identifier = string(exception.identifier);

if strlength(identifier) == 0
    identifier = "unidentified_error";
end

end


function text = singleLine(text)

text = replace(string(text), newline, " ");

end


function ensureDirectory(directory)

if ~isfolder(directory)
    [created, message] = mkdir(directory);

    if ~created
        error("kwsim:CampaignDirectoryCreateFailed", ...
            "Could not create campaign directory '%s': %s", ...
            directory, message);
    end
end

end


function deleteIfPresent(path)

if isfile(path)
    delete(path);
end

end
