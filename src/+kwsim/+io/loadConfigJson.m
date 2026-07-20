function [cfg, metadata] = loadConfigJson(config_file)
%LOADCONFIGJSON Load a partial 2D or 3D configuration from JSON.
%
% The JSON file must contain:
%
%   "dimension": 2
%
% or:
%
%   "dimension": 3
%
% Only fields explicitly present in the JSON override the corresponding
% dimension-specific defaults. Unknown fields are rejected to prevent silent
% configuration errors caused by misspelled names.

arguments
    config_file {mustBeTextScalar}
end

config_file = string(config_file);

if ~isfile(config_file)
    error("kwsim:ConfigFileNotFound", ...
        "Configuration file does not exist: %s", ...
        config_file);
end

try
    json_text = fileread(config_file);
    overrides = jsondecode(json_text);
catch exception
    error("kwsim:InvalidConfigJson", ...
        "Could not decode configuration JSON '%s': %s", ...
        config_file, exception.message);
end

if ~isstruct(overrides) || ~isscalar(overrides)
    error("kwsim:InvalidConfigJson", ...
        "The top level of the configuration JSON must be one object.");
end

if ~isfield(overrides, "dimension")
    error("kwsim:MissingConfigDimension", ...
        "The configuration JSON must define dimension as 2 or 3.");
end

dimension = double(overrides.dimension);

if ~isscalar(dimension) || ...
        ~isfinite(dimension) || ...
        ~ismember(dimension, [2, 3])
    error("kwsim:InvalidConfigDimension", ...
        "Configuration dimension must be the numeric value 2 or 3.");
end

switch dimension
    case 2
        defaults = kwsim.two_d.defaultConfig();

    case 3
        defaults = kwsim.three_d.defaultConfig();
end

cfg = mergeKnownFields( ...
    defaults, ...
    overrides, ...
    "config");

% Keep dimension authoritative even if a future default changes.
cfg.dimension = dimension;

[status, attributes] = fileattrib(config_file);

if status
    absolute_config_file = string(attributes.Name);
else
    absolute_config_file = config_file;
end

metadata = struct();
metadata.config_file = absolute_config_file;
metadata.dimension = dimension;
metadata.json_text = string(json_text);
metadata.overrides = overrides;

end


function merged = mergeKnownFields(base, override, location)

merged = base;
field_names = fieldnames(override);

for index = 1:numel(field_names)
    field_name = field_names{index};

    if ~isfield(base, field_name)
        error("kwsim:UnknownConfigField", ...
            "Unknown configuration field '%s.%s'.", ...
            location, field_name);
    end

    base_value = base.(field_name);
    override_value = override.(field_name);

    % Scalar structures are merged recursively. Arrays of structures, such
    % as geometry objects or material lists, are replaced as complete units.
    if isstruct(base_value) && ...
            isscalar(base_value) && ...
            isstruct(override_value) && ...
            isscalar(override_value)

        merged.(field_name) = mergeKnownFields( ...
            base_value, ...
            override_value, ...
            location + "." + string(field_name));
    else
        merged.(field_name) = override_value;
    end
end

end
