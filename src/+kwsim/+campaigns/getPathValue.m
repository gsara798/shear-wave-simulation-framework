function value = getPathValue(value, path_value)
%GETPATHVALUE Resolve one campaign path in an existing configuration.

arguments
    value
    path_value {mustBeTextScalar}
end

tokens = kwsim.campaigns.parseSweepPath(path_value);

for token_index = 1:numel(tokens)
    field_name = char(tokens(token_index).field);

    if ~isstruct(value) || ...
            ~isscalar(value) || ...
            ~isfield(value, field_name)
        unknownPath(path_value);
    end

    value = value.(field_name);

    element_index = tokens(token_index).index;

    if element_index > 0
        if element_index > numel(value)
            unknownPath(path_value);
        end

        value = value(element_index);
    end
end

end


function unknownPath(path_value)

error("kwsim:UnknownCampaignSweepPath", ...
    "Unknown sweep path '%s'.", path_value);

end
