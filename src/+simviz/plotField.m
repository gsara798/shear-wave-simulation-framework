function fig = plotField(sample, options)
%PLOTFIELD Plot the real part of the complex wavefield.
arguments
    sample (1,1) struct
    options.Visible (1,1) string = "off"
end

[x,z,U,~,~] = simviz.displayPlane(sample);
values = real(U);
limit = max(abs(values),[],"all");
if ~(isfinite(limit) && limit > 0)
    limit = 1;
end

fig = figure("Visible",char(options.Visible),"Color","w","Position",[100 100 760 620]);
ax = axes(fig);
imagesc(ax,x,z,values);
axis(ax,"image");
set(ax,"YDir","normal");
xlabel(ax,"x [mm]");
ylabel(ax,"z [mm]");
clim(ax,[-limit limit]);
colormap(ax,simviz.divergingColormap(256, ...
    NegativeRole="blue", PositiveRole="yellow"));

cb = colorbar(ax);
ylabel(cb,"Re(U)");

simviz.applyFigureStyle(fig);
end
