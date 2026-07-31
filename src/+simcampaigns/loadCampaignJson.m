function [campaign, metadata] = loadCampaignJson(campaign_file)
%LOADCAMPAIGNJSON Load and validate a simulation campaign JSON file.
%
% Supported contracts:
%
%   1.0  implicit kwsim backend, Cartesian sweep
%   1.1  explicit backend, Cartesian sweep
%   1.2  explicit backend, Cartesian sweep or explicit ordered runs
%
% Contract 1.2 requires exactly one of:
%
%   sweep
%   runs

arguments
    campaign_file {mustBeTextScalar}
end

campaign_file = string(campaign_file);

if ~isfile(campaign_file)
    error("simcampaigns:CampaignFileNotFound", ...
        "Campaign file does not exist: %s", ...
        campaign_file);
end

try
    json_text = fileread(campaign_file);
    requested = jsondecode(json_text);
catch exception
    error("simcampaigns:InvalidCampaignJson", ...
        "Could not decode campaign JSON '%s': %s", ...
        campaign_file, exception.message);
end

if ~isstruct(requested) || ~isscalar(requested)
    error("simcampaigns:InvalidCampaignJson", ...
        "The top level of the campaign JSON must be one object.");
end

if ~isfield(requested, "schema_version")
    error("simcampaigns:MissingCampaignField", ...
        "Missing required campaign field 'campaign.schema_version'.");
end

schema_version = string(requested.schema_version);

switch schema_version
    case "1.0"
        backend = "kwsim";

        required_fields = [ ...
            "schema_version", ...
            "campaign_name", ...
            "base_config", ...
            "sweep"];

        optional_fields = "output";

    case "1.1"
        backend = validateBackend(requested);

        required_fields = [ ...
            "schema_version", ...
            "backend", ...
            "campaign_name", ...
            "base_config", ...
            "sweep"];

        optional_fields = "output";

    case "1.2"
        backend = validateBackend(requested);

        required_fields = [ ...
            "schema_version", ...
            "backend", ...
            "campaign_name", ...
            "base_config"];

        optional_fields = [ ...
            "output", ...
            "sweep", ...
            "runs"];

    otherwise
        error("simcampaigns:UnsupportedCampaignSchema", ...
            "schema_version must be 1.0, 1.1, or 1.2.");
end

validateFields( ...
    requested, ...
    required_fields, ...
    optional_fields, ...
    "campaign");

if ~isTextScalar(requested.campaign_name)
    error("simcampaigns:InvalidCampaignName", ...
        "campaign_name must be a non-empty text scalar.");
end

campaign_name = string(requested.campaign_name);

if strlength(campaign_name) == 0 || ...
        isempty(regexp( ...
            char(campaign_name), ...
            '^[A-Za-z0-9_-]+$', ...
            'once'))
    error("simcampaigns:InvalidCampaignName", ...
        ["campaign_name must contain only letters, numbers, " ...
         "underscores, and hyphens."]);
end

if ~isTextScalar(requested.base_config) || ...
        strlength(string(requested.base_config)) == 0
    error("simcampaigns:InvalidCampaignBaseConfig", ...
        "base_config must be a non-empty path.");
end

repository_root = resolveRepositoryRoot();

base_config_file = resolveRelativePath( ...
    string(requested.base_config), ...
    repository_root);

if ~isfile(base_config_file)
    error("simcampaigns:CampaignBaseConfigNotFound", ...
        "Campaign base configuration does not exist: %s", ...
        base_config_file);
end

[base_config, base_metadata] = ...
    simcampaigns.backends.loadBaseConfig( ...
        base_config_file, backend);

output = validateOutput(requested);

has_sweep = isfield(requested, "sweep");
has_runs = isfield(requested, "runs");

if schema_version ~= "1.2"
    has_runs = false;
end

if schema_version == "1.2" && has_sweep == has_runs
    error("simcampaigns:InvalidCampaignMode", ...
        "Campaign schema 1.2 must define exactly one of sweep or runs.");
end

sweep = struct([]);
explicit_runs = struct([]);

parameter_count = 0;
value_counts = zeros(0,1);
expanded_run_count = 0;

if has_sweep
    [sweep, parameter_count, value_counts] = ...
        validateSweep(requested.sweep, base_config);

    mode = "cartesian_sweep";
    expanded_run_count = prod(value_counts);

else
    explicit_runs = ...
        validateExplicitRuns(requested.runs, base_config);

    mode = "explicit_runs";
    expanded_run_count = numel(explicit_runs);
end

campaign = struct();
campaign.schema_version = schema_version;
campaign.backend = backend;
campaign.campaign_name = campaign_name;
campaign.base_config = base_config_file;
campaign.output = output;
campaign.mode = mode;
campaign.sweep = sweep;
campaign.runs = explicit_runs;

metadata = struct();
metadata.campaign_file = absolutePath(campaign_file);
metadata.repository_root = repository_root;
metadata.base_config_file = base_config_file;
metadata.base_config = base_config;
metadata.base_config_metadata = base_metadata;
metadata.mode = mode;
metadata.parameter_count = parameter_count;
metadata.value_counts = value_counts;
metadata.expanded_run_count = expanded_run_count;
metadata.json_text = string(json_text);
metadata.requested = requested;

end


function backend = validateBackend(requested)

if ~isfield(requested, "backend")
    error("simcampaigns:MissingCampaignField", ...
        "Missing required campaign field 'campaign.backend'.");
end

backend = lower(string(requested.backend));

if ~ismember(backend, ["kwsim", "swsynth"])
    error("simcampaigns:UnsupportedBackend", ...
        "backend must be kwsim or swsynth.");
end

end


function [sweep, parameter_count, value_counts] = ...
        validateSweep(requested_sweep, base_config)

if ~isstruct(requested_sweep) || isempty(requested_sweep)
    error("simcampaigns:InvalidCampaignSweep", ...
        "sweep must be a non-empty array of parameter objects.");
end

sweep = requested_sweep;
parameter_count = numel(sweep);

paths = strings(parameter_count,1);
value_counts = zeros(parameter_count,1);

for index = 1:parameter_count
    parameter = sweep(index);

    if ~isscalar(parameter)
        error("simcampaigns:InvalidCampaignSweep", ...
            "Each sweep entry must be one object.");
    end

    validateFields( ...
        parameter, ...
        ["path", "values"], ...
        strings(0,1), ...
        "campaign.sweep");

    path_value = validateConfigPath( ...
        parameter.path, ...
        base_config);

    base_value = simcampaigns.getPathValue( ...
        base_config, ...
        path_value);

    value_counts(index) = countValues( ...
        parameter.values, ...
        base_value);

    if value_counts(index) == 0
        error("simcampaigns:EmptyCampaignSweepValues", ...
            "Sweep path '%s' must define at least one value.", ...
            path_value);
    end

    paths(index) = path_value;
    sweep(index).path = path_value;
end

if numel(unique(paths)) ~= numel(paths)
    error("simcampaigns:DuplicateCampaignSweepPath", ...
        "Each sweep path may appear only once.");
end

end


function explicit_runs = validateExplicitRuns( ...
        requested_runs, base_config)

if ~isstruct(requested_runs) || isempty(requested_runs)
    error("simcampaigns:InvalidExplicitRuns", ...
        "runs must be a non-empty array of run objects.");
end

explicit_runs = requested_runs;
run_count = numel(explicit_runs);
design_ids = strings(run_count,1);

for run_index = 1:run_count
    run_definition = explicit_runs(run_index);

    if ~isscalar(run_definition)
        error("simcampaigns:InvalidExplicitRuns", ...
            "Each runs entry must be one object.");
    end

    validateFields( ...
        run_definition, ...
        ["design_id", "overrides"], ...
        strings(0,1), ...
        "campaign.runs");

    if ~isTextScalar(run_definition.design_id)
        error("simcampaigns:InvalidDesignId", ...
            "design_id must be a non-empty text scalar.");
    end

    design_id = string(run_definition.design_id);

    if strlength(design_id) == 0 || ...
            isempty(regexp( ...
                char(design_id), ...
                '^[A-Za-z0-9_-]+$', ...
                'once'))
        error("simcampaigns:InvalidDesignId", ...
            ["design_id must contain only letters, numbers, " ...
             "underscores, and hyphens."]);
    end

    overrides = run_definition.overrides;

    if ~isstruct(overrides) || isempty(overrides)
        error("simcampaigns:InvalidRunOverrides", ...
            "Each explicit run must define non-empty overrides.");
    end

    override_paths = strings(numel(overrides),1);

    for override_index = 1:numel(overrides)
        override = overrides(override_index);

        if ~isscalar(override)
            error("simcampaigns:InvalidRunOverrides", ...
                "Each override must be one object.");
        end

        validateFields( ...
            override, ...
            ["path", "value"], ...
            strings(0,1), ...
            "campaign.runs.overrides");

        path_value = validateConfigPath( ...
            override.path, ...
            base_config);

        override_paths(override_index) = path_value;
        overrides(override_index).path = path_value;
    end

    if numel(unique(override_paths)) ~= numel(override_paths)
        error("simcampaigns:DuplicateRunOverridePath", ...
            ["Each override path may appear only once within " ...
             "one explicit run."]);
    end

    design_ids(run_index) = design_id;
    explicit_runs(run_index).design_id = design_id;
    explicit_runs(run_index).overrides = overrides;
end

if numel(unique(design_ids)) ~= numel(design_ids)
    error("simcampaigns:DuplicateDesignId", ...
        "Each explicit run must have a unique design_id.");
end

end


function path_value = validateConfigPath(path_value, base_config)

if ~isTextScalar(path_value) || ...
        strlength(string(path_value)) == 0
    error("simcampaigns:InvalidCampaignSweepPath", ...
        "Each configuration path must be a non-empty text scalar.");
end

path_value = string(path_value);

if path_value == "dimension"
    error("simcampaigns:ForbiddenCampaignSweepPath", ...
        "dimension cannot be modified by a campaign.");
end

if path_value == "output" || ...
        startsWith(path_value, "output.")
    error("simcampaigns:ForbiddenCampaignSweepPath", ...
        "Paths under output are controlled by the campaign runner.");
end

simcampaigns.getPathValue(base_config, path_value);

end


function output = validateOutput(requested)

output = struct();
output.directory = "outputs/campaigns";

if ~isfield(requested, "output")
    return
end

requested_output = requested.output;

if ~isstruct(requested_output) || ~isscalar(requested_output)
    error("simcampaigns:InvalidCampaignOutput", ...
        "campaign.output must be one object.");
end

validateFields( ...
    requested_output, ...
    strings(0,1), ...
    "directory", ...
    "campaign.output");

if isfield(requested_output, "directory")
    if ~isTextScalar(requested_output.directory) || ...
            strlength(string(requested_output.directory)) == 0
        error("simcampaigns:InvalidCampaignOutput", ...
            "campaign.output.directory must be a non-empty path.");
    end

    output.directory = string(requested_output.directory);
end

end


function validateFields(value, required, optional, location)

actual = string(fieldnames(value));
allowed = [required(:); optional(:)];

unknown = setdiff(actual, allowed);

if ~isempty(unknown)
    error("simcampaigns:UnknownCampaignField", ...
        "Unknown campaign field '%s.%s'.", ...
        location, unknown(1));
end

missing = setdiff(required(:), actual);

if ~isempty(missing)
    error("simcampaigns:MissingCampaignField", ...
        "Missing required campaign field '%s.%s'.", ...
        location, missing(1));
end

end


function count = countValues(values, base_value)

if ischar(values)
    count = double(~isempty(values));
    return
end

if isscalar(base_value)
    count = numel(values);
    return
end

if isrow(base_value) && ...
        ismatrix(values) && ...
        size(values,2) == size(base_value,2)

    count = size(values,1);
    return
end

if iscell(values)
    count = numel(values);
    return
end

error("simcampaigns:InvalidCampaignSweepValues", ...
    "Could not determine the number of structured sweep values.");

end


function tf = isTextScalar(value)

tf = (isstring(value) && isscalar(value)) || ...
    (ischar(value) && isrow(value));

end


function repository_root = resolveRepositoryRoot()

repository_root = fileparts( ...
    fileparts( ...
        fileparts(mfilename("fullpath"))));

repository_root = string(repository_root);

end


function path_value = resolveRelativePath( ...
        path_value, repository_root)

if ~isAbsolutePath(path_value)
    path_value = fullfile(repository_root, path_value);
end

path_value = absolutePath(path_value);

end


function path_value = absolutePath(path_value)

[status, attributes] = fileattrib(path_value);

if status
    path_value = string(attributes.Name);
else
    path_value = string(path_value);
end

end


function tf = isAbsolutePath(path_value)

characters = char(string(path_value));

if ispc
    tf = ~isempty(regexp( ...
        characters, ...
        '^[A-Za-z]:[\\/]|^\\\\', ...
        'once'));
else
    tf = startsWith(characters, filesep);
end

end
