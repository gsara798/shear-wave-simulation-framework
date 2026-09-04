function outcome = validateRun(config, backend)
%VALIDATERUN Validate one resolved run without creating outputs.

arguments
    config (1,1) struct
    backend {mustBeTextScalar}
end

backend = lower(string(backend));

switch backend
    case "kwsim"
        config_file = writeTemporaryConfig(config);
        cleanup = onCleanup(@() deleteIfPresent(config_file));

        outcome = kwsim.cli.runConfig( ...
            config_file, ...
            DryRun=true);

        clear cleanup

    case "swsynth"
        if isVolumetricSwsynthConfig(config)
            [resolved, validation] = swsynth.validateConfig3D(config);
        else
            [resolved, validation] = swsynth.validateConfig(config);
        end

        outcome = struct();
        outcome.status = "dry_run_valid";
        outcome.backend = "swsynth";
        outcome.config_resolved = resolved;
        outcome.validation = validation;

    otherwise
        error("simcampaigns:UnsupportedBackend", ...
            "Unsupported simulation campaign backend: %s", ...
            backend);
end

end

function tf = isVolumetricSwsynthConfig(config)

tf = isfield(config, "domain") && ...
    isstruct(config.domain) && ...
    isfield(config.domain, "Ly_m") && ...
    isfield(config.domain, "dy_m");

end

function config_file = writeTemporaryConfig(config)

config_file = string(tempname) + ".json";

file_id = fopen(config_file, "w");

if file_id < 0
    error("simcampaigns:TemporaryConfigWriteFailed", ...
        "Could not create a temporary run configuration.");
end

cleanup = onCleanup(@() fclose(file_id));

fprintf(file_id, "%s", ...
    jsonencode(config, PrettyPrint=true));

clear cleanup

end

function deleteIfPresent(path_value)

if isfile(path_value)
    delete(path_value);
end

end
