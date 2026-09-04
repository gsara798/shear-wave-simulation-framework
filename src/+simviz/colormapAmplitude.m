function cmap = colormapAmplitude(n)
%COLORMAPAMPLITUDE Sequential multicolor map for normalized amplitude.
%
% Dark purple -> purple -> blue -> red -> orange -> yellow.

arguments
    n (1,1) double {mustBeInteger,mustBePositive} = 256
end

theme = simviz.paperTheme();

anchors = [
    theme.rgb.gray.dark
    theme.rgb.purple.main
    theme.rgb.blue.main
    theme.rgb.red.main
    theme.rgb.orange.main
    theme.rgb.yellow.main
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
