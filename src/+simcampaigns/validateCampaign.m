function [runs, validation] = validateCampaign(campaign_file)
%VALIDATECAMPAIGN Dry-run every expanded backend-neutral configuration.
%
% All expanded runs are checked before campaign execution creates outputs.

arguments
    campaign_file {mustBeTextScalar}
end

[runs, expansion] = simcampaigns.expandCampaign(campaign_file);

empty_validation = struct();
empty_validation.ordinal = 0;
empty_validation.run_id = "";
empty_validation.backend = expansion.backend;
empty_validation.valid = false;
empty_validation.status = "";
empty_validation.error_identifier = "";
empty_validation.error_message = "";
empty_validation.outcome = struct();

run_validations = repmat( ...
    empty_validation, ...
    expansion.run_count, ...
    1);

for index = 1:expansion.run_count
    run = runs(index);

    run_validations(index).ordinal = run.ordinal;
    run_validations(index).run_id = run.run_id;
    run_validations(index).backend = run.backend;

    try
        outcome = simcampaigns.backends.validateRun( ...
            run.config, ...
            run.backend);

        run_validations(index).outcome = outcome;
        run_validations(index).status = string(outcome.status);
        run_validations(index).valid = ...
            string(outcome.status) == "dry_run_valid";

        if ~run_validations(index).valid
            run_validations(index).error_identifier = ...
                "simcampaigns:UnexpectedDryRunStatus";
            run_validations(index).error_message = ...
                "Unexpected dry-run status: " + ...
                string(outcome.status);
        end

    catch exception
        run_validations(index).valid = false;
        run_validations(index).status = "dry_run_failed";
        run_validations(index).error_identifier = ...
            exceptionIdentifier(exception);
        run_validations(index).error_message = ...
            singleLine(exception.message);
    end
end

valid_flags = [run_validations.valid]';

validation = struct();
validation.schema_version = "1.0";
validation.campaign_file = expansion.campaign_file;
validation.campaign_name = expansion.campaign.campaign_name;
validation.backend = expansion.backend;
validation.run_count = expansion.run_count;
validation.valid_count = sum(valid_flags);
validation.failed_count = ...
    expansion.run_count - validation.valid_count;
validation.valid = validation.failed_count == 0;
validation.runs = run_validations;

validation.summary = string(sprintf( ...
    "Campaign dry-run: %d/%d %s runs valid.", ...
    validation.valid_count, ...
    validation.run_count, ...
    expansion.backend));

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
