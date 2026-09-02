function map = sequentialColormap(role, n)
%SEQUENTIALCOLORMAP White-to-theme-color sequential map.
arguments
    role (1,1) string = "teal"
    n (1,1) double {mustBeInteger,mustBePositive} = 256
end
theme = simviz.paperTheme();
if ~isfield(theme.rgb,role)
    error("simviz:UnknownColorRole","Unknown theme role '%s'.",role);
end
start = [1 1 1];
finish = theme.rgb.(role).main;
t = linspace(0,1,n)';
map = (1-t).*start + t.*finish;
end
