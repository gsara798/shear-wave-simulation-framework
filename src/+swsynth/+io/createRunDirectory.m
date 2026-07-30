function paths = createRunDirectory(cfg, options)
%CREATERUNDIRECTORY Create the standardized output tree for one swsynth run.
%
% Structure:
%
%   run/
%     config/
%     data/
%     figures/
%     validation/
%     run_summary.json
%     manifest.txt
%
% OutputDirectory, when provided, is interpreted as the complete run
% directory. Otherwise, cfg.output.directory is used as the root and the
% run directory is generated from cfg.output.run_name or cfg.scenario.

arguments
    cfg struct
    options.OutputDirectory {mustBeTextScalar} = ""
    options.Overwrite (1,1) logical = false
    options.Timestamp = datetime("now")
end

explicitRunDirectory = string(options.OutputDirectory);

if strlength(explicitRunDirectory) > 0
    runDirectory = explicitRunDirectory;
    rootDirectory = string(fileparts(runDirectory));

    if strlength(rootDirectory) == 0
        rootDirectory = ".";
    end

    [~, directoryName] = fileparts(runDirectory);
    runName = string(directoryName);

else
    rootDirectory = string(getOutputValue( ...
        cfg, ...
        "directory", ...
        fullfile("outputs", "runs", "swsynth")));

    runName = string(getOutputValue( ...
        cfg, ...
        "run_name", ...
        ""));

    if strlength(runName) == 0
        if isfield(cfg, "scenario") && ...
                strlength(string(cfg.scenario)) > 0
            runName = string(cfg.scenario);
        else
            runName = "simulation";
        end
    end

    runName = sanitizeName(runName);

    appendTimestamp = logical(getOutputValue( ...
        cfg, ...
        "append_timestamp", ...
        true));

    if appendTimestamp
        timestampText = string(datetime( ...
            options.Timestamp, ...
            "Format", ...
            "yyyyMMdd_HHmmss"));

        directoryName = timestampText + "_" + runName;
    else
        directoryName = runName;
    end

    runDirectory = fullfile(rootDirectory, directoryName);
end

overwrite = options.Overwrite || logical(getOutputValue( ...
    cfg, ...
    "overwrite", ...
    false));

if isfolder(runDirectory)
    if ~overwrite
        error( ...
            "swsynth:OutputDirectoryExists", ...
            ["Output directory already exists: %s. " + ...
             "Enable overwrite or choose another directory."], ...
            runDirectory);
    end

    rmdir(runDirectory, "s");
end

configDirectory = fullfile(runDirectory, "config");
dataDirectory = fullfile(runDirectory, "data");
figuresDirectory = fullfile(runDirectory, "figures");
validationDirectory = fullfile(runDirectory, "validation");

ensureDirectory(configDirectory);
ensureDirectory(dataDirectory);
ensureDirectory(figuresDirectory);
ensureDirectory(validationDirectory);

paths = struct();

paths.root = string(rootDirectory);
paths.run = string(runDirectory);
paths.config = string(configDirectory);
paths.data = string(dataDirectory);
paths.figures = string(figuresDirectory);
paths.validation = string(validationDirectory);

paths.requested_config = string(fullfile( ...
    configDirectory, ...
    "requested_config.json"));

paths.resolved_config = string(fullfile( ...
    configDirectory, ...
    "resolved_config.json"));

paths.wavefield_sample = string(fullfile( ...
    dataDirectory, ...
    "wavefield_sample.mat"));

paths.validation_report = string(fullfile( ...
    validationDirectory, ...
    "validation_report.json"));

paths.run_summary = string(fullfile( ...
    runDirectory, ...
    "run_summary.json"));

paths.manifest = string(fullfile( ...
    runDirectory, ...
    "manifest.txt"));

paths.run_name = runName;
paths.directory_name = string(directoryName);

end

function value = getOutputValue(cfg, fieldName, defaultValue)

if isfield(cfg, "output") && ...
        isfield(cfg.output, fieldName) && ...
        ~isempty(cfg.output.(fieldName))
    value = cfg.output.(fieldName);
else
    value = defaultValue;
end

end

function cleanName = sanitizeName(name)

cleanName = lower(strtrim(string(name)));

cleanName = regexprep( ...
    cleanName, ...
    '[^a-zA-Z0-9_-]+', ...
    '_');

cleanName = regexprep( ...
    cleanName, ...
    '_+', ...
    '_');

cleanName = regexprep( ...
    cleanName, ...
    '^[_-]+|[_-]+$', ...
    '');

if strlength(cleanName) == 0
    cleanName = "simulation";
end

end

function ensureDirectory(directory)

if ~isfolder(directory)
    mkdir(directory);
end

end
