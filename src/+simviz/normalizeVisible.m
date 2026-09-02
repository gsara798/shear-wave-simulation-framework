function value = normalizeVisible(value)
%NORMALIZEVISIBLE Convert logical/text visibility inputs to MATLAB on/off.

if islogical(value) || isnumeric(value)
    if ~isscalar(value)
        error("simviz:InvalidFigureVisibility", ...
            "Figure visibility must be a scalar logical or on/off text.");
    end
    if logical(value)
        value = "on";
    else
        value = "off";
    end
    return
end

value = lower(strip(string(value)));
if ~isscalar(value)
    error("simviz:InvalidFigureVisibility", ...
        "Figure visibility must be scalar.");
end

switch value
    case {"on","true","1"}
        value = "on";
    case {"off","false","0"}
        value = "off";
    otherwise
        error("simviz:InvalidFigureVisibility", ...
            "Figure visibility must resolve to 'on' or 'off'.");
end
end
