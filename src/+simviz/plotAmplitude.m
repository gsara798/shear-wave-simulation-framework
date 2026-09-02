function fig = plotAmplitude(sample, options)
%PLOTAMPLITUDE Plot normalized wavefield amplitude in [0,1].

arguments
    sample (1,1) struct
    options.Visible (1,1) string = "off"
end

if double(sample.spatial_dimension) == 3
    fig = simviz.plotVolumetricAmplitudeSlices( ...
        sample, ...
        Visible=options.Visible);
    return
end

[x_mm, z_mm, U, ~, ~] = ...
    simviz.displayPlane(sample);

values = abs(U);

maximum_value = max( ...
    values, ...
    [], ...
    "all", ...
    "omitnan");

if isfinite(maximum_value) && maximum_value > 0
    values = values ./ maximum_value;
else
    values = zeros(size(values));
end

fig = figure( ...
    "Visible", char(options.Visible), ...
    "Color", "w", ...
    "Position", [100, 100, 760, 620]);

ax = axes(fig);

imagesc(ax, x_mm, z_mm, values);
axis(ax, "image");
set(ax, "YDir", "normal");

xlabel(ax, "x [mm]");
ylabel(ax, "z [mm]");

clim(ax, [0, 1]);

cb = colorbar(ax);
cb.Ticks = 0:0.2:1;
ylabel(cb, "Normalized |U|");

colormap(ax, simviz.colormapAmplitude(256));

simviz.applyFigureStyle(fig);

end
