function fig = plotAmplitude(sample, options)
%PLOTAMPLITUDE Plot the wavefield amplitude.
arguments
    sample (1,1) struct
    options.Visible (1,1) string = "off"
end

[x,z,U,~,~] = simviz.displayPlane(sample);
values = abs(U);
maximum = max(values,[],"all");
if ~(isfinite(maximum) && maximum > 0)
    maximum = 1;
end

fig = figure("Visible",char(options.Visible),"Color","w","Position",[100 100 760 620]);
ax = axes(fig);
imagesc(ax,x,z,values);
axis(ax,"image");
set(ax,"YDir","normal");
xlabel(ax,"x [mm]");
ylabel(ax,"z [mm]");
clim(ax,[0 maximum]);
colormap(ax,simviz.sequentialColormap("blue",256,EndRole="yellow"));

cb = colorbar(ax);
ylabel(cb,"|U|");

simviz.applyFigureStyle(fig);
end
