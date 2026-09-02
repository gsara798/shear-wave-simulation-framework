function fig = plotPhase(sample, options)
%PLOTPHASE Plot complex phase using the shared blue-white-red palette.
arguments
    sample (1,1) struct
    options.Title (1,1) string = "Wavefield phase"
    options.Visible (1,1) string = "off"
end
[x,z,U,~,description] = simviz.displayPlane(sample);
fig = figure("Visible",char(options.Visible),"Color","w","Position",[100 100 760 620]);
ax = axes(fig); imagesc(ax,x,z,angle(U)); axis(ax,"image"); set(ax,"YDir","normal");
xlabel(ax,"x [mm]"); ylabel(ax,"z [mm]"); title(ax,options.Title + " | " + description);
clim(ax,[-pi pi]); cb=colorbar(ax); ylabel(cb,"Phase [rad]");
colormap(ax,simviz.divergingColormap(256)); simviz.applyFigureStyle(fig);
end
