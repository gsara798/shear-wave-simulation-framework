function paths = createRunDirectory(cfg, options)
%CREATERUNDIRECTORY Create a standardized output tree for one simulation.
%
% Output structure:
%
%   run/
%     config/
%     data/
%     figures/
%
% New configurations may define:
%
%   cfg.output.directory
%   cfg.output.run_name
%   cfg.output.append_timestamp
%   cfg.output.overwrite
%
% Missing fields receive backward-compatible defaults.

arguments
    cfg struct
    options.Timestamp = datetime("now")
end

root_directory = string(getOutputValue( ...
    cfg, "directory", "outputs"));

if strlength(root_directory) == 0
    root_directory = "outputs";
end

run_name = string(getOutputValue( ...
    cfg, "run_name", ""));

if strlength(run_name) == 0
    if isfield(cfg, "scenario") && ...
            strlength(string(cfg.scenario)) > 0
        run_name = string(cfg.scenario);
    else
        run_name = "simulation";
    end
end

run_name = sanitizeName(run_name);

append_timestamp = logical(getOutputValue( ...
    cfg, "append_timestamp", true));

overwrite = logical(getOutputValue( ...
    cfg, "overwrite", false));

if append_timestamp
    timestamp_text = string(datetime( ...
        options.Timestamp, ...
        "Format", "yyyyMMdd_HHmmss"));

    directory_name = timestamp_text + "_" + run_name;
else
    directory_name = run_name;
end

run_directory = fullfile( ...
    root_directory, ...
    directory_name);

if isfolder(run_directory)
    if ~overwrite
        error("kwsim:OutputDirectoryExists", ...
            "Output directory already exists: %s", ...
            run_directory);
    end
else
    mkdir(run_directory);
end

config_directory = fullfile( ...
    run_directory, "config");

data_directory = fullfile( ...
    run_directory, "data");

figures_directory = fullfile( ...
    run_directory, "figures");

ensureDirectory(config_directory);
ensureDirectory(data_directory);
ensureDirectory(figures_directory);

paths = struct();

paths.root = string(root_directory);
paths.run = string(run_directory);
paths.config = string(config_directory);
paths.data = string(data_directory);
paths.figures = string(figures_directory);

paths.manifest = string(fullfile( ...
    run_directory, ...
    "manifest.txt"));

paths.run_name = run_name;
paths.directory_name = string(directory_name);

end


function value = getOutputValue(cfg, field_name, default_value)

if isfield(cfg, "output") && ...
        isfield(cfg.output, field_name)
    value = cfg.output.(field_name);
else
    value = default_value;
end

end


function clean_name = sanitizeName(name)

clean_name = lower(strtrim(string(name)));

clean_name = regexprep( ...
    clean_name, ...
    '[^a-zA-Z0-9_-]+', ...
    '_');

clean_name = regexprep( ...
    clean_name, ...
    '_+', ...
    '_');

clean_name = regexprep( ...
    clean_name, ...
    '^[_-]+|[_-]+$', ...
    '');

if strlength(clean_name) == 0
    clean_name = "simulation";
end

end


function ensureDirectory(directory)

if ~isfolder(directory)
    mkdir(directory);
end

end
