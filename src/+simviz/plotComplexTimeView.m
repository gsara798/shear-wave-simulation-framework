function fig = plotComplexTimeView(sample, mode, options)
%PLOTCOMPLEXTIMEVIEW Visualize Im(U) or four real-time harmonic snapshots.
% Uses the complex measured wavefield from the shared sample contract.
% For volumetric3d, uses the central x-z (constant-y) slice.
arguments
    sample (1,1) struct
    mode (1,1) string {mustBeMember(mode,["imaginary","snapshots"])}
    options.Visible (1,1) string = "off"
end
[x_mm,z_mm,U,~,description]=simviz.displayPlane(sample);
scale=max(abs(U),[],"all","omitnan");
if ~isfinite(scale) || scale<=0
    scale=1;
end

if mode=="imaginary"
    fig=figure("Visible",char(options.Visible),"Color","w", ...
        "Position",[100 100 760 620]);
    ax=axes(fig);
    imagesc(ax,x_mm,z_mm,imag(U)/scale);
    axis(ax,"image");
    set(ax,"YDir","normal");
    xlabel(ax,"x [mm]");
    ylabel(ax,"z [mm]");
    title(ax,"Imaginary harmonic field — "+string(description));
    clim(ax,[-1 1]);
    cb=colorbar(ax);
    ylabel(cb,"Im(U) / max|U|");
    colormap(ax,simviz.colormapFieldReal(256));
else
    phases=[0 pi/2 pi 3*pi/2];
    names=["t = 0","t = T/4","t = T/2","t = 3T/4"];
    fig=figure("Visible",char(options.Visible),"Color","w", ...
        "Position",[100 100 1200 960]);
    tiles=tiledlayout(fig,2,2,"TileSpacing","compact");
    for j=1:4
        ax=nexttile(tiles);
        snapshot=real(U.*exp(1i*phases(j)))/scale;
        imagesc(ax,x_mm,z_mm,snapshot);
        axis(ax,"image");
        set(ax,"YDir","normal");
        clim(ax,[-1 1]);
        colormap(ax,simviz.colormapFieldReal(256));
        colorbar(ax);
        xlabel(ax,"x [mm]");
        ylabel(ax,"z [mm]");
        title(ax,names(j));
    end
    title(tiles,"Physical displacement: Re[U exp(i omega t)] — "+ ...
        string(description)+" (normalized by max|U|)");
end
simviz.applyFigureStyle(fig);
end
