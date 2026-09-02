function fig = plotPhase(sample, options)
%PLOTPHASE Plot complex phase using the shared blue-white-red palette.
arguments
    sample (1,1) struct
    options.Visible (1,1) string = "off"
end

[x,z,U,~,~] = simviz.displayPlane(sample);
fig = figure("Visible",char(options.Visible),"Color","w","Position",[100 100 760 620]);
ax = axes(fig);
imagesc(ax,x,z,angle(U));
axis(ax,"image");
set(ax,"YDir","normal");
xlabel(ax,"x [mm]");
ylabel(ax,"z [mm]");
clim(ax,[-pi pi]);
colormap(ax,simviz.divergingColormap(256));

cb = colorbar(ax);
ylabel(cb,"Phase [rad]");
cb.Ticks = [-pi, -pi/2, 0, pi/2, pi];
cb.TickLabels = {'-\pi','-\pi/2','0','\pi/2','\pi'};
cb.TickLabelInterpreter = "tex";

simviz.applyFigureStyle(fig);
end
