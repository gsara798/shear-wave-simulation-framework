function outcome = runConfig(configFile, options)
%RUNCONFIG Execute one swsynth JSON configuration.
%
% outcome = swsynth.cli.runConfig(configFile)
%
% Options:
%   OutputDirectory : explicit output directory
%   DryRun          : validate without executing
%   Overwrite       : allow replacing an existing output directory

arguments
    configFile {mustBeTextScalar}
    options.OutputDirectory {mustBeTextScalar} = ""
    options.DryRun (1,1) logical = false
    options.Overwrite (1,1) logical = false
end

configFile = string(configFile);

if ~isfile(configFile)
    error( ...
        "swsynth:ConfigFileNotFound", ...
        "Configuration file not found: %s", ...
        configFile);
end

requested = jsondecode(fileread(configFile));
[resolvedConfig, validationReport] = ...
    swsynth.validateConfig(requested);

if strlength(options.OutputDirectory) == 0
    [~, configName] = fileparts(configFile);

    timestamp = string(datetime( ...
        "now", ...
        "Format", "yyyyMMdd_HHmmss"));

    outputDirectory = fullfile( ...
        "outputs", ...
        "runs", ...
        "swsynth", ...
        configName + "_" + timestamp);
else
    outputDirectory = string(options.OutputDirectory);
end

if isfolder(outputDirectory)
    if ~options.Overwrite
        error( ...
            "swsynth:OutputDirectoryExists", ...
            ["Output directory already exists: %s. " + ...
             "Use Overwrite=true to replace it."], ...
            outputDirectory);
    end

    rmdir(outputDirectory, "s");
end

outcome = struct();
outcome.config_file = char(configFile);
outcome.output_directory = char(outputDirectory);
outcome.dry_run = options.DryRun;
outcome.validation = validationReport;

if options.DryRun
    outcome.completed = false;
    outcome.result = [];

    fprintf("\nSWSYNTH configuration validated successfully.\n");
    fprintf("Scenario: %s\n", resolvedConfig.scenario);
    fprintf("Model: %s\n", resolvedConfig.propagation.model);
    fprintf("Directions: %d\n", resolvedConfig.directions.count);
    fprintf("Solid angle: %.8g sr\n", ...
        resolvedConfig.directions.support.solid_angle_sr);
    fprintf("Dry run: no outputs were created.\n");

    return;
end

mkdir(outputDirectory);

writeJson( ...
    fullfile(outputDirectory, "resolved_config.json"), ...
    resolvedConfig);

writeJson( ...
    fullfile(outputDirectory, "validation_report.json"), ...
    validationReport);

timerHandle = tic;
result = swsynth.run(resolvedConfig);
runtimeS = toc(timerHandle);

wavefieldSample = result.sample; %#ok<NASGU>
save( ...
    fullfile(outputDirectory, "wavefield_sample.mat"), ...
    "wavefieldSample", ...
    "-v7.3");

runSummary = struct();
runSummary.backend = "swsynth";
runSummary.scenario = resolvedConfig.scenario;
runSummary.propagation_model = ...
    resolvedConfig.propagation.model;
runSummary.frequency_hz = ...
    resolvedConfig.wavefield.frequency_hz;
runSummary.requested_direction_count = ...
    resolvedConfig.directions.count;
runSummary.solid_angle_sr = ...
    resolvedConfig.directions.support.solid_angle_sr;
runSummary.in_plane_count = ...
    resolvedConfig.directions.in_plane_count;
runSummary.runtime_s = runtimeS;
runSummary.output_directory = char(outputDirectory);

if isfield(result.wavefield, "diagnostics")
    diagnostics = result.wavefield.diagnostics;

    if isfield(diagnostics, "retained_direction_count")
        runSummary.retained_direction_count = ...
            diagnostics.retained_direction_count;
    end

    if isfield(diagnostics, "rejected_direction_count")
        runSummary.rejected_direction_count = ...
            diagnostics.rejected_direction_count;
    end

    if isfield(diagnostics, "candidate_direction_count")
        runSummary.candidate_direction_count = ...
            diagnostics.candidate_direction_count;
    end

    if isfield(diagnostics, "eligible_candidate_count")
        runSummary.eligible_candidate_count = ...
            diagnostics.eligible_candidate_count;
    end

    if isfield(diagnostics, "rejected_candidate_count")
        runSummary.rejected_candidate_count = ...
            diagnostics.rejected_candidate_count;
    end

    if isfield(diagnostics, "selected_in_plane_count")
        runSummary.selected_in_plane_count = ...
            diagnostics.selected_in_plane_count;
    end
end

writeJson( ...
    fullfile(outputDirectory, "run_summary.json"), ...
    runSummary);

outcome.completed = true;
outcome.runtime_s = runtimeS;
outcome.result = result;

fprintf("\nSWSYNTH run completed successfully.\n");
fprintf("Scenario: %s\n", resolvedConfig.scenario);
fprintf("Model: %s\n", resolvedConfig.propagation.model);
fprintf("Runtime: %.3f s\n", runtimeS);
fprintf("Output: %s\n", outputDirectory);

end

function writeJson(path, value)

text = jsonencode(value, "PrettyPrint", true);

fileId = fopen(path, "w");

if fileId < 0
    error( ...
        "swsynth:CannotWriteJson", ...
        "Could not open JSON file for writing: %s", ...
        path);
end

cleanup = onCleanup(@() fclose(fileId));

fprintf(fileId, "%s\n", text);

end
