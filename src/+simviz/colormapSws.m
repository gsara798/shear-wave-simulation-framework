function cmap = colormapSws(n)
%COLORMAPSWS Continuous SWS colormap matching the REQ-ML paper palette.

arguments
    n (1,1) double {mustBeInteger,mustBePositive} = 256
end

theme = simviz.paperTheme();

anchors = [
    theme.rgb.blue.main
    theme.rgb.teal.main
    theme.rgb.green.light
    theme.rgb.orange.light
    theme.rgb.red.main
];

anchor_position = linspace(0, 1, size(anchors, 1));
query_position = linspace(0, 1, n);

cmap = interp1( ...
    anchor_position, ...
    anchors, ...
    query_position, ...
    "pchip");

cmap = min(max(cmap, 0), 1);

end
