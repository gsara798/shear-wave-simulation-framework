function tokens = parseSweepPath(path_value)
%PARSESWEEPPATH Parse dotted campaign paths with optional one-based indices.
%
% Examples:
%   medium.cs_m_s
%   geometry.objects[1].cs_m_s

arguments
    path_value {mustBeTextScalar}
end

parts = split(string(path_value), ".");

if any(strlength(parts) == 0)
    unknownPath(path_value);
end

tokens = repmat(struct( ...
    "field", "", ...
    "index", 0), ...
    numel(parts), ...
    1);

field_pattern = "^[A-Za-z][A-Za-z0-9_]*$";
indexed_pattern = ...
    "^([A-Za-z][A-Za-z0-9_]*)\[([1-9][0-9]*)\]$";

for part_index = 1:numel(parts)
    part = string(parts(part_index));

    indexed_match = regexp( ...
        char(part), ...
        char(indexed_pattern), ...
        "tokens", ...
        "once");

    if ~isempty(indexed_match)
        tokens(part_index).field = ...
            string(indexed_match{1});

        tokens(part_index).index = ...
            str2double(indexed_match{2});

        continue
    end

    if matches(part, regexpPattern(field_pattern))
        tokens(part_index).field = part;
        tokens(part_index).index = 0;
        continue
    end

    unknownPath(path_value);
end

end


function unknownPath(path_value)

error("kwsim:UnknownCampaignSweepPath", ...
    "Unknown sweep path '%s'.", ...
    path_value);

end
