function fig = plotSws(sample, options)
%PLOTSWS Plot the ground-truth shear-wave-speed map.

arguments
    sample (1,1) struct
    options.Visible (1,1) string = "off"
end

if double(sample.spatial_dimension) == 3
    fig = simviz.plotVolumetricSwsSlices( ...
        sample, ...
        Visible=options.Visible);
    return
end

[x_mm, z_mm, ~, cs, ~] = ...
    simviz.displayPlane(sample);

theme = simviz.paperTheme();

fig = figure( ...
    "Visible", char(options.Visible), ...
    "Color", "w", ...
    "Position", [100, 100, 760, 620]);

ax = axes(fig);

imagesc(ax, x_mm, z_mm, cs);
axis(ax, "image");
set(ax, "YDir", "normal");

xlabel(ax, "x [mm]");
ylabel(ax, "z [mm]");

cb = colorbar(ax);
ylabel(cb, "SWS [m/s]");

colormap(ax, simviz.colormapSws(256));

simviz.applyFigureStyle(fig, theme);

end
