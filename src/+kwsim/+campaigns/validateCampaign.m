function [runs, validation] = validateCampaign(campaign_file)
%VALIDATECAMPAIGN Dry-run every expanded configuration in one campaign.
%
%   [runs, validation] = ...
%       kwsim.campaigns.validateCampaign(campaign_file)
%
% Every expanded configuration is validated through
% kwsim.cli.runConfig(..., DryRun=true). All runs are checked even if one
% fails. No solver is executed and no simulation or campaign output
% directories are created.

arguments
    campaign_file {mustBeTextScalar}
end

[runs, expansion] = ...
    kwsim.campaigns.expandCampaign(campaign_file);

empty_run_validation = struct();
empty_run_validation.ordinal = 0;
empty_run_validation.run_id = "";
empty_run_validation.valid = false;
empty_run_validation.status = "";
empty_run_validation.error_identifier = "";
empty_run_validation.error_message = "";
empty_run_validation.outcome = struct();

run_validations = repmat( ...
    empty_run_validation, ...
    expansion.run_count, ...
    1);

for index = 1:expansion.run_count
    run = runs(index);

    run_validations(index).ordinal = run.ordinal;
    run_validations(index).run_id = run.run_id;

    try
        outcome = validateExpandedConfig(run.config);

        run_validations(index).outcome = outcome;
        run_validations(index).status = ...
            string(outcome.status);

        run_validations(index).valid = ...
            string(outcome.status) == "dry_run_valid";

        if ~run_validations(index).valid
            run_validations(index).error_identifier = ...
                "kwsim:UnexpectedCampaignDryRunStatus";

            run_validations(index).error_message = ...
                "Unexpected dry-run status: " + ...
                string(outcome.status);
        end

    catch exception
        run_validations(index).valid = false;
        run_validations(index).status = "dry_run_failed";

        error_identifier = string(exception.identifier);

        if strlength(error_identifier) == 0
            error_identifier = "unidentified_error";
        end

        run_validations(index).error_identifier = ...
            error_identifier;

        run_validations(index).error_message = ...
            replace( ...
                string(exception.message), ...
                newline, ...
                " ");
    end

end

valid_flags = [run_validations.valid]';
valid_count = sum(valid_flags);
failed_count = expansion.run_count - valid_count;

validation = struct();
validation.campaign_file = expansion.campaign_file;
validation.campaign_name = ...
    expansion.campaign.campaign_name;
validation.run_count = expansion.run_count;
validation.valid_count = valid_count;
validation.failed_count = failed_count;
validation.valid = failed_count == 0;
validation.runs = run_validations;

validation.summary = string(sprintf( ...
    "Campaign dry-run: %d/%d runs valid.", ...
    valid_count, ...
    expansion.run_count));

end


function outcome = validateExpandedConfig(config)

config_file = writeTemporaryConfig(config);
cleanup = onCleanup(@() deleteIfPresent(config_file));

outcome = kwsim.cli.runConfig( ...
    config_file, ...
    DryRun=true);

clear cleanup

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


function deleteIfPresent(path)

if strlength(string(path)) > 0 && isfile(path)
    delete(path);
end

end
