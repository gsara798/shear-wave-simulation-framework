function fig = plotAmplitude(sample, options)
%PLOTAMPLITUDE Plot the wavefield amplitude.
arguments
    sample (1,1) struct
    options.Title (1,1) string = "Wavefield amplitude"
    options.Visible (1,1) string = "off"
end
[x,z,U,~,description] = simviz.displayPlane(sample);
fig = figure("Visible",char(options.Visible),"Color","w","Position",[100 100 760 620]);
ax = axes(fig); imagesc(ax,x,z,abs(U)); axis(ax,"image"); set(ax,"YDir","normal");
xlabel(ax,"x [mm]"); ylabel(ax,"z [mm]"); title(ax,options.Title + " | " + description);
cb=colorbar(ax); ylabel(cb,"|U|");
colormap(ax,simviz.sequentialColormap("teal",256)); simviz.applyFigureStyle(fig);
end
