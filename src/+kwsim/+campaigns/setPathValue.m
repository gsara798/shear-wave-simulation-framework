function value = setPathValue(value, path_value, replacement)
%SETPATHVALUE Replace one field addressed by a campaign sweep path.

arguments
    value
    path_value {mustBeTextScalar}
    replacement
end

tokens = kwsim.campaigns.parseSweepPath(path_value);

value = setNestedValue( ...
    value, ...
    tokens, ...
    1, ...
    replacement, ...
    string(path_value));

end


function value = setNestedValue( ...
        value, tokens, token_index, replacement, path_value)

field_name = char(tokens(token_index).field);

if ~isstruct(value) || ...
        ~isscalar(value) || ...
        ~isfield(value, field_name)
    unknownPath(path_value);
end

nested = value.(field_name);
element_index = tokens(token_index).index;
is_last = token_index == numel(tokens);

if element_index > 0
    if element_index > numel(nested)
        unknownPath(path_value);
    end

    if is_last
        nested(element_index) = replacement;
    else
        nested(element_index) = setNestedValue( ...
            nested(element_index), ...
            tokens, ...
            token_index + 1, ...
            replacement, ...
            path_value);
    end

    value.(field_name) = nested;
    return
end

if is_last
    value.(field_name) = replacement;
    return
end

nested = setNestedValue( ...
    nested, ...
    tokens, ...
    token_index + 1, ...
    replacement, ...
    path_value);

value.(field_name) = nested;

end


function unknownPath(path_value)

error("kwsim:UnknownCampaignSweepPath", ...
    "Unknown sweep path '%s'.", path_value);

end
