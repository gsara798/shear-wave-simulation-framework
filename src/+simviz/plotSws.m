function fig = plotSws(sample, options)
%PLOTSWS Plot the ground-truth shear-wave-speed map or central 3D slice.
arguments
    sample (1,1) struct
    options.Title (1,1) string = "Ground-truth SWS"
    options.Visible (1,1) string = "off"
end
[x,z,~,cs,description] = simviz.displayPlane(sample);
theme = simviz.paperTheme();
fig = figure("Visible",char(options.Visible),"Color","w","Position",[100 100 760 620]);
ax = axes(fig);
imagesc(ax,x,z,cs); axis(ax,"image"); set(ax,"YDir","normal");
xlabel(ax,"x [mm]"); ylabel(ax,"z [mm]");
title(ax,options.Title + " | " + description);
cb = colorbar(ax); ylabel(cb,"SWS [m/s]");
colormap(ax,simviz.sequentialColormap("blue",256));
simviz.applyFigureStyle(fig,theme);
end
