function outcome = runConfig(configFile, options)
%RUNCONFIG Execute one swsynth JSON configuration.
%
% outcome = swsynth.cli.runConfig(configFile)
%
% Options:
%   OutputDirectory : complete output directory for this run
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

requestedConfig = jsondecode(fileread(configFile));

[resolvedConfig, validationReport] = ...
    swsynth.validateConfig(requestedConfig);

outcome = struct();
outcome.config_file = char(configFile);
outcome.dry_run = options.DryRun;
outcome.validation = validationReport;
outcome.paths = struct();

if options.DryRun
    outcome.status = "dry_run_valid";
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

paths = swsynth.io.createRunDirectory( ...
    resolvedConfig, ...
    OutputDirectory=options.OutputDirectory, ...
    Overwrite=options.Overwrite);

writeJson(paths.requested_config, requestedConfig);
writeJson(paths.resolved_config, resolvedConfig);
writeJson(paths.validation_report, validationReport);

timerHandle = tic;
result = swsynth.run(resolvedConfig);
runtimeS = toc(timerHandle);

wavefieldSample = result.sample; %#ok<NASGU>

save( ...
    paths.wavefield_sample, ...
    "wavefieldSample", ...
    "-v7.3");

runSummary = buildRunSummary( ...
    result, ...
    resolvedConfig, ...
    runtimeS, ...
    paths);

writeJson(paths.run_summary, runSummary);

writeManifest( ...
    paths.manifest, ...
    configFile, ...
    resolvedConfig, ...
    runSummary, ...
    paths);

outcome.status = "completed";
outcome.completed = true;
outcome.runtime_s = runtimeS;
outcome.output_directory = char(paths.run);
outcome.result = result;
outcome.paths = paths;

fprintf("\nSWSYNTH run completed successfully.\n");
fprintf("Scenario: %s\n", resolvedConfig.scenario);
fprintf("Model: %s\n", resolvedConfig.propagation.model);
fprintf("Runtime: %.3f s\n", runtimeS);
fprintf("Output:\n%s\n", paths.run);

end

function runSummary = buildRunSummary( ...
    result, resolvedConfig, runtimeS, paths)

runSummary = struct();

runSummary.schema_name = "swsynth_run_summary";
runSummary.schema_version = 1;
runSummary.backend = "swsynth";
runSummary.scenario = resolvedConfig.scenario;
runSummary.seed = resolvedConfig.seed;

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
runSummary.output_directory = char(paths.run);

runSummary.files = struct();
runSummary.files.requested_config = ...
    relativePath(paths.requested_config, paths.run);
runSummary.files.resolved_config = ...
    relativePath(paths.resolved_config, paths.run);
runSummary.files.wavefield_sample = ...
    relativePath(paths.wavefield_sample, paths.run);
runSummary.files.validation_report = ...
    relativePath(paths.validation_report, paths.run);
runSummary.files.manifest = ...
    relativePath(paths.manifest, paths.run);

if isfield(result.wavefield, "diagnostics")
    diagnostics = result.wavefield.diagnostics;

    fieldsToCopy = [
        "retained_direction_count"
        "rejected_direction_count"
        "candidate_direction_count"
        "eligible_candidate_count"
        "rejected_candidate_count"
        "selected_in_plane_count"];

    for fieldIndex = 1:numel(fieldsToCopy)
        fieldName = fieldsToCopy(fieldIndex);

        if isfield(diagnostics, fieldName)
            runSummary.(fieldName) = diagnostics.(fieldName);
        end
    end
end

end

function writeManifest( ...
    manifestPath, configFile, resolvedConfig, runSummary, paths)

gitCommit = resolveGitCommit();

fileId = fopen(manifestPath, "w");

if fileId < 0
    error( ...
        "swsynth:CannotWriteManifest", ...
        "Could not open manifest file: %s", ...
        manifestPath);
end

cleanup = onCleanup(@() fclose(fileId));

fprintf(fileId, "schema_name=swsynth_run_manifest\n");
fprintf(fileId, "schema_version=1\n");
fprintf(fileId, "created_at=%s\n", ...
    string(datetime("now", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ssXXX")));
fprintf(fileId, "backend=swsynth\n");
fprintf(fileId, "scenario=%s\n", resolvedConfig.scenario);
fprintf(fileId, "seed=%d\n", resolvedConfig.seed);
fprintf(fileId, "propagation_model=%s\n", ...
    resolvedConfig.propagation.model);
fprintf(fileId, "frequency_hz=%.17g\n", ...
    resolvedConfig.wavefield.frequency_hz);
fprintf(fileId, "requested_direction_count=%d\n", ...
    resolvedConfig.directions.count);
fprintf(fileId, "runtime_s=%.17g\n", runSummary.runtime_s);
fprintf(fileId, "git_commit=%s\n", gitCommit);
fprintf(fileId, "source_config=%s\n", configFile);
fprintf(fileId, "run_directory=%s\n", paths.run);
fprintf(fileId, "requested_config=config/requested_config.json\n");
fprintf(fileId, "resolved_config=config/resolved_config.json\n");
fprintf(fileId, "wavefield_sample=data/wavefield_sample.mat\n");
fprintf(fileId, ...
    "validation_report=validation/validation_report.json\n");
fprintf(fileId, "run_summary=run_summary.json\n");

end

function commit = resolveGitCommit()

[status, output] = system("git rev-parse HEAD");

if status == 0
    commit = strtrim(string(output));
else
    commit = "unknown";
end

end

function relative = relativePath(path, root)

path = string(path);
root = string(root);

prefix = root + filesep;

if startsWith(path, prefix)
    relative = extractAfter(path, strlength(prefix));
else
    relative = path;
end

relative = replace(relative, "\", "/");

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
