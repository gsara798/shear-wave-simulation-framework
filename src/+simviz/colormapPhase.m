function cmap = colormapPhase(n)
%COLORMAPPHASE Blue-white-red colormap for wrapped phase.

arguments
    n (1,1) double {mustBeInteger,mustBePositive} = 256
end

theme = simviz.paperTheme();

blue = theme.rgb.blue.main;
white = [1, 1, 1];
red = theme.rgb.red.main;

left_count = ceil(n / 2);
right_count = n - left_count + 1;

left = interpolate(blue, white, left_count);
right = interpolate(white, red, right_count);

cmap = [
    left
    right(2:end, :)
];

end


function values = interpolate(a, b, n)

t = linspace(0, 1, n)';
values = (1 - t) .* a + t .* b;

end
