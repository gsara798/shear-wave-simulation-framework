function fig = plotVolumetricPhaseSlices(sample, options)
%PLOTVOLUMETRICPHASESLICES Plot wrapped phase on XY, XZ, and YZ slices.

arguments
    sample (1,1) struct
    options.Visible (1,1) string = "off"
end

s = simviz.volumetricSlices(sample);

fig = figure( ...
    "Visible",char(options.Visible), ...
    "Color","w", ...
    "Position",[100,100,1500,520]);

tl = tiledlayout(fig,1,3, ...
    "TileSpacing","compact", ...
    "Padding","compact");

plotSlice( ...
    nexttile(tl), ...
    s.xy.x_mm, ...
    s.xy.y_mm, ...
    angle(s.xy.U), ...
    "x [mm]", ...
    "y [mm]");

plotSlice( ...
    nexttile(tl), ...
    s.xz.x_mm, ...
    s.xz.z_mm, ...
    angle(s.xz.U), ...
    "x [mm]", ...
    "z [mm]");

plotSlice( ...
    nexttile(tl), ...
    s.yz.y_mm, ...
    s.yz.z_mm, ...
    angle(s.yz.U), ...
    "y [mm]", ...
    "z [mm]");

colormap(fig,simviz.colormapPhase(256));
simviz.applyFigureStyle(fig);

end


function plotSlice(ax,x,y,data,xLabel,yLabel)

imagesc(ax,x,y,data);
axis(ax,"image");
set(ax,"YDir","normal");

xlabel(ax,xLabel);
ylabel(ax,yLabel);

clim(ax,[-pi,pi]);

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

ylabel(cb,"Phase [rad]");

end
