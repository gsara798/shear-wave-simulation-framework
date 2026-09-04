function fig = plotPhase(sample, options)
%PLOTPHASE Plot wrapped complex phase.

arguments
    sample (1,1) struct
    options.Visible (1,1) string = "off"
end

if double(sample.spatial_dimension) == 3
    fig = simviz.plotVolumetricPhaseSlices( ...
        sample, ...
        Visible=options.Visible);
    return
end

[x_mm, z_mm, U, ~, ~] = ...
    simviz.displayPlane(sample);

fig = figure( ...
    "Visible", char(options.Visible), ...
    "Color", "w", ...
    "Position", [100, 100, 760, 620]);

ax = axes(fig);

imagesc(ax, x_mm, z_mm, angle(U));
axis(ax, "image");
set(ax, "YDir", "normal");

xlabel(ax, "x [mm]");
ylabel(ax, "z [mm]");

clim(ax, [-pi, pi]);

cb = colorbar(ax);
cb.Ticks = [
    -pi
    -pi/2
    0
    pi/2
    pi
];

cb.TickLabels = {
    '-\pi'
    '-\pi/2'
    '0'
    '\pi/2'
    '\pi'
};

cb.TickLabelInterpreter = "tex";

ylabel(cb, "Phase [rad]");

colormap(ax, simviz.colormapPhase(256));

simviz.applyFigureStyle(fig);

end
