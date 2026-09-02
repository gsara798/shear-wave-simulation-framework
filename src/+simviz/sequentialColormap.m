function map = sequentialColormap(role, n, options)
%SEQUENTIALCOLORMAP Sequential map using shared paper-theme main colors.
%
% By default the map runs from white to role.main, preserving the original
% API. Set EndRole to create a direct main-color to main-color gradient.
arguments
    role (1,1) string = "teal"
    n (1,1) double {mustBeInteger,mustBePositive} = 256
    options.EndRole (1,1) string = ""
end

theme = simviz.paperTheme();
if ~isfield(theme.rgb, role)
    error("simviz:UnknownColorRole", "Unknown theme role '%s'.", role);
end

if strlength(options.EndRole) == 0
    start = [1 1 1];
    finish = theme.rgb.(role).main;
else
    if ~isfield(theme.rgb, options.EndRole)
        error("simviz:UnknownColorRole", ...
            "Unknown theme role '%s'.", options.EndRole);
    end
    start = theme.rgb.(role).main;
    finish = theme.rgb.(options.EndRole).main;
end

t = linspace(0,1,n)';
map = (1-t).*start + t.*finish;
end
