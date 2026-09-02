function map = divergingColormap(n, options)
%DIVERGINGCOLORMAP Theme-color to white to theme-color diverging map.
arguments
    n (1,1) double {mustBeInteger,mustBePositive} = 256
    options.NegativeRole (1,1) string = "blue"
    options.PositiveRole (1,1) string = "red"
end

theme = simviz.paperTheme();
negative = mainColor(theme, options.NegativeRole);
positive = mainColor(theme, options.PositiveRole);
white = [1 1 1];

leftCount = ceil(n/2);
rightCount = n-leftCount+1;
left = interpolate(negative, white, leftCount);
right = interpolate(white, positive, rightCount);
map = [left; right(2:end,:)];
end

function color = mainColor(theme, role)
if ~isfield(theme.rgb, role)
    error("simviz:UnknownColorRole", "Unknown theme role '%s'.", role);
end
color = theme.rgb.(role).main;
end

function values = interpolate(a,b,n)
t = linspace(0,1,n)';
values = (1-t).*a + t.*b;
end
