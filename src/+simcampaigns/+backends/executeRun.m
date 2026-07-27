function outcome = executeRun(config, backend, run_directory)
%EXECUTERUN Execute and save one backend-specific simulation run.

arguments
    config (1,1) struct
    backend {mustBeTextScalar}
    run_directory {mustBeTextScalar}
end

backend = lower(string(backend));
run_directory = string(run_directory);

switch backend
    case "kwsim"
        outcome = executeKwsim(config, run_directory);

    case "swsynth"
        outcome = executeSwsynth(config, run_directory);

    otherwise
        error("simcampaigns:UnsupportedBackend", ...
            "Unsupported simulation campaign backend: %s", backend);
end

end

function outcome = executeKwsim(config, run_directory)

configured = config;

campaign_directory = string(fileparts(run_directory));
[~, run_name] = fileparts(run_directory);

if ~isfield(configured, "output") || ...
        ~isstruct(configured.output) || ...
        ~isscalar(configured.output)
    configured.output = struct();
end

configured.output.enabled = true;
configured.output.directory = campaign_directory;
configured.output.run_name = string(run_name);
configured.output.append_timestamp = false;
configured.output.overwrite = false;

config_file = writeTemporaryConfig(configured);
cleanup = onCleanup(@() deleteIfPresent(config_file));

outcome = kwsim.cli.runConfig(config_file);

clear cleanup

end

function outcome = executeSwsynth(config, run_directory)

if isfolder(run_directory)
    error("simcampaigns:RunDirectoryExists", ...
        "Run directory already exists: %s", run_directory);
end

config_directory = fullfile(run_directory, "config");
data_directory = fullfile(run_directory, "data");

ensureDirectory(config_directory);
ensureDirectory(data_directory);

try
    [resolved, validation] = swsynth.validateConfig(config);

    start_time = tic;
    result = swsynth.run(resolved);
    elapsed_s = toc(start_time);

    resolved_config_path = fullfile( ...
        config_directory, ...
        "resolved_config.json");

    validation_path = fullfile( ...
        data_directory, ...
        "validation_report.json");

    summary_path = fullfile( ...
        data_directory, ...
        "run_summary.json");

    wavefield_sample_path = fullfile( ...
        data_directory, ...
        "wavefield_sample.mat");

    writeJsonAtomically( ...
        resolved_config_path, ...
        result.config);

    writeJsonAtomically( ...
        validation_path, ...
        result.validation);

    wavefield_sample = result.sample; %#ok<NASGU>
    save( ...
        wavefield_sample_path, ...
        "wavefield_sample", ...
        "-v7.3");

    summary = struct();
    summary.schema_version = "1.0";
    summary.backend = "swsynth";
    summary.status = "completed_valid";
    summary.scenario = string(result.config.scenario);
    summary.seed = double(result.config.seed);
    summary.frequency_hz = ...
        double(result.config.wavefield.frequency_hz);
    summary.background_cs_m_s = ...
        double(result.config.medium.background_cs_m_s);
    summary.medium_object_count = ...
        numel(result.config.medium.objects);
    summary.direction_count = ...
        double(result.config.directions.count);
    summary.propagation_model = ...
        string(result.config.propagation.model);
    summary.elapsed_solver_time_s = elapsed_s;
    summary.valid = logical(result.validation.valid);
    summary.wavefield_size_zx = ...
        size(result.sample.wavefield.data_zx);

    writeJsonAtomically(summary_path, summary);

    outcome = struct();
    outcome.status = "completed_valid";
    outcome.backend = "swsynth";
    outcome.valid = logical(result.validation.valid);

    outcome.paths = struct();
    outcome.paths.run = run_directory;
    outcome.paths.resolved_config = resolved_config_path;
    outcome.paths.validation_report = validation_path;
    outcome.paths.summary = summary_path;
    outcome.paths.wavefield_sample = wavefield_sample_path;

catch exception
    if isfolder(run_directory)
        rmdir(run_directory, "s");
    end
    rethrow(exception)
end

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

function writeJsonAtomically(path_value, value)

temporary_path = string(path_value) + ".tmp";
deleteIfPresent(temporary_path);

file_id = fopen(temporary_path, "w");

if file_id < 0
    error("simcampaigns:JsonWriteFailed", ...
        "Could not create file: %s", temporary_path);
end

cleanup = onCleanup(@() fclose(file_id));

fprintf(file_id, "%s", ...
    jsonencode(value, PrettyPrint=true));

clear cleanup

[moved, message] = movefile( ...
    temporary_path, ...
    path_value, ...
    "f");

if ~moved
    deleteIfPresent(temporary_path);
    error("simcampaigns:JsonWriteFailed", ...
        "Could not publish file '%s': %s", ...
        path_value, message);
end

end

function ensureDirectory(directory)

if ~isfolder(directory)
    [created, message] = mkdir(directory);

    if ~created
        error("simcampaigns:DirectoryCreateFailed", ...
            "Could not create directory '%s': %s", ...
            directory, message);
    end
end

end

function deleteIfPresent(path_value)

if isfile(path_value)
    delete(path_value);
end

end
