function cmap = colormapFieldReal(n)
%COLORMAPFIELDREAL Signed displacement-field colormap without white.
%
% The displayed real field is mapped from signed [-1,1] to [0,1].
% 0.0 -> most negative displacement
% 0.5 -> zero displacement
% 1.0 -> most positive displacement
%
% The dark chromatic midpoint avoids the white zero-band common to
% conventional diverging colormaps.

arguments
    n (1,1) double {mustBeInteger,mustBePositive} = 256
end

theme = simviz.paperTheme();

anchors = [
    theme.rgb.blue.main
    theme.rgb.teal.main
    theme.rgb.gray.dark
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
