function [campaign, metadata] = loadCampaignJson(campaign_file)
%LOADCAMPAIGNJSON Load and validate a simulation campaign JSON file.
%
% Contract v1 defines an ordered Cartesian sweep over one existing
% single-run configuration. This loader validates only campaign structure
% and sweep paths; expansion and execution are handled separately.

arguments
    campaign_file {mustBeTextScalar}
end

campaign_file = string(campaign_file);

if ~isfile(campaign_file)
    error("kwsim:CampaignFileNotFound", ...
        "Campaign file does not exist: %s", ...
        campaign_file);
end

try
    json_text = fileread(campaign_file);
    requested = jsondecode(json_text);
catch exception
    error("kwsim:InvalidCampaignJson", ...
        "Could not decode campaign JSON '%s': %s", ...
        campaign_file, exception.message);
end

if ~isstruct(requested) || ~isscalar(requested)
    error("kwsim:InvalidCampaignJson", ...
        "The top level of the campaign JSON must be one object.");
end

required_fields = [ ...
    "schema_version", ...
    "campaign_name", ...
    "base_config", ...
    "sweep"];

optional_fields = "output";

validateFields( ...
    requested, ...
    required_fields, ...
    optional_fields, ...
    "campaign");

if ~isTextScalar(requested.schema_version) || ...
        string(requested.schema_version) ~= "1.0"
    error("kwsim:UnsupportedCampaignSchema", ...
        "Campaign schema_version must be the string '1.0'.");
end

if ~isTextScalar(requested.campaign_name)
    error("kwsim:InvalidCampaignName", ...
        "campaign_name must be a non-empty text scalar.");
end

campaign_name = string(requested.campaign_name);

if strlength(campaign_name) == 0 || ...
        isempty(regexp( ...
            char(campaign_name), ...
            '^[A-Za-z0-9_-]+$', ...
            'once'))
    error("kwsim:InvalidCampaignName", ...
        ["campaign_name must contain only letters, numbers, " ...
         "underscores, and hyphens."]);
end

if ~isTextScalar(requested.base_config) || ...
        strlength(string(requested.base_config)) == 0
    error("kwsim:InvalidCampaignBaseConfig", ...
        "base_config must be a non-empty path.");
end

repository_root = resolveRepositoryRoot();

base_config_file = resolveRelativePath( ...
    string(requested.base_config), ...
    repository_root);

if ~isfile(base_config_file)
    error("kwsim:CampaignBaseConfigNotFound", ...
        "Campaign base configuration does not exist: %s", ...
        base_config_file);
end

[base_config, base_metadata] = ...
    kwsim.io.loadConfigJson(base_config_file);

output = validateOutput(requested);

if ~isstruct(requested.sweep) || isempty(requested.sweep)
    error("kwsim:InvalidCampaignSweep", ...
        "sweep must be a non-empty array of parameter objects.");
end

sweep = requested.sweep;
parameter_count = numel(sweep);
paths = strings(parameter_count, 1);
value_counts = zeros(parameter_count, 1);

for index = 1:parameter_count
    parameter = sweep(index);

    if ~isscalar(parameter)
        error("kwsim:InvalidCampaignSweep", ...
            "Each sweep entry must be one object.");
    end

    validateFields( ...
        parameter, ...
        ["path", "values"], ...
        strings(0, 1), ...
        "campaign.sweep");

    if ~isTextScalar(parameter.path) || ...
            strlength(string(parameter.path)) == 0
        error("kwsim:InvalidCampaignSweepPath", ...
            "Each sweep path must be a non-empty text scalar.");
    end

    path_value = string(parameter.path);

    if path_value == "dimension"
        error("kwsim:ForbiddenCampaignSweepPath", ...
            "dimension cannot be swept in campaign contract v1.");
    end

    if path_value == "output" || ...
            startsWith(path_value, "output.")
        error("kwsim:ForbiddenCampaignSweepPath", ...
            "Paths under output are controlled by the campaign runner.");
    end

    validateSweepPath(base_config, path_value);

    paths(index) = path_value;
    value_counts(index) = countValues(parameter.values);

    if value_counts(index) == 0
        error("kwsim:EmptyCampaignSweepValues", ...
            "Sweep path '%s' must define at least one value.", ...
            path_value);
    end

    sweep(index).path = path_value;
end

if numel(unique(paths)) ~= numel(paths)
    error("kwsim:DuplicateCampaignSweepPath", ...
        "Each sweep path may appear only once.");
end

campaign = struct();
campaign.schema_version = "1.0";
campaign.campaign_name = campaign_name;
campaign.base_config = base_config_file;
campaign.output = output;
campaign.sweep = sweep;

metadata = struct();
metadata.campaign_file = absolutePath(campaign_file);
metadata.repository_root = repository_root;
metadata.base_config_file = base_config_file;
metadata.base_config = base_config;
metadata.base_config_metadata = base_metadata;
metadata.parameter_count = parameter_count;
metadata.value_counts = value_counts;
metadata.expanded_run_count = prod(value_counts);
metadata.json_text = string(json_text);
metadata.requested = requested;

end


function output = validateOutput(requested)

output = struct();
output.directory = "outputs/campaigns";

if ~isfield(requested, "output")
    return
end

requested_output = requested.output;

if ~isstruct(requested_output) || ~isscalar(requested_output)
    error("kwsim:InvalidCampaignOutput", ...
        "campaign.output must be one object.");
end

validateFields( ...
    requested_output, ...
    strings(0, 1), ...
    "directory", ...
    "campaign.output");

if isfield(requested_output, "directory")
    if ~isTextScalar(requested_output.directory) || ...
            strlength(string(requested_output.directory)) == 0
        error("kwsim:InvalidCampaignOutput", ...
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
    error("kwsim:UnknownCampaignField", ...
        "Unknown campaign field '%s.%s'.", ...
        location, unknown(1));
end

missing = setdiff(required(:), actual);

if ~isempty(missing)
    error("kwsim:MissingCampaignField", ...
        "Missing required campaign field '%s.%s'.", ...
        location, missing(1));
end

end


function validateSweepPath(base_config, path_value)

kwsim.campaigns.getPathValue( ...
    base_config, ...
    path_value);

end


function count = countValues(values)

if ischar(values)
    count = double(~isempty(values));
else
    count = numel(values);
end

end


function tf = isTextScalar(value)

tf = (isstring(value) && isscalar(value)) || ...
    (ischar(value) && isrow(value));

end


function repository_root = resolveRepositoryRoot()

% Current file:
%   repository/src/+kwsim/+campaigns/loadCampaignJson.m

repository_root = fileparts( ...
    fileparts( ...
    fileparts( ...
    fileparts(mfilename("fullpath")))));

repository_root = string(repository_root);

end


function path_value = resolveRelativePath(path_value, repository_root)

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
