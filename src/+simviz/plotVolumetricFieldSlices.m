function fig = plotVolumetricFieldSlices(sample, options)
%PLOTVOLUMETRICFIELDSLICES Plot normalized Re(U) on three orthogonal slices.

arguments
    sample (1,1) struct
    options.Visible (1,1) string = "off"
end

s = simviz.volumetricSlices(sample);

raw = real(double(sample.wavefield.data_zyx));

scale = max(abs(raw),[],"all","omitnan");

if ~(isfinite(scale) && scale > 0)
    scale = 1;
end

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
    mapSigned(real(s.xy.U),scale), ...
    "x [mm]", ...
    "y [mm]");

plotSlice( ...
    nexttile(tl), ...
    s.xz.x_mm, ...
    s.xz.z_mm, ...
    mapSigned(real(s.xz.U),scale), ...
    "x [mm]", ...
    "z [mm]");

plotSlice( ...
    nexttile(tl), ...
    s.yz.y_mm, ...
    s.yz.z_mm, ...
    mapSigned(real(s.yz.U),scale), ...
    "y [mm]", ...
    "z [mm]");

colormap(fig,simviz.colormapFieldReal(256));
simviz.applyFigureStyle(fig);

end


function values = mapSigned(values,scale)

values = values ./ scale;
values = max(min(values,1),-1);
values = 0.5 * (values + 1);

end


function plotSlice(ax,x,y,data,xLabel,yLabel)

imagesc(ax,x,y,data);
axis(ax,"image");
set(ax,"YDir","normal");

xlabel(ax,xLabel);
ylabel(ax,yLabel);

clim(ax,[0,1]);

cb = colorbar(ax);
cb.Ticks = [0,0.25,0.5,0.75,1];
ylabel(cb,"Normalized Re(U)");

end
