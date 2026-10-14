%% Example 02: coherent finite line aperture (framework-native swsynth).
% Point, 4-mm and 8-mm coherent line aperture; NOT a rigid oscillating disk.
here=string(fileparts(mfilename("fullpath")));
root=string(fileparts(fileparts(fileparts(here))));
addpath(fullfile(root,"src"));
cfgdir=fullfile(root,"configs","swsynth","validation","finite_point_force_aperture");
configs=["source_x_point.json","source_x_aperture_4mm.json", ...
         "source_x_aperture_8mm.json"];
labels=["Point","4 mm line","8 mm line"];
fields=cell(1,3);
for j=1:3
    requested=jsondecode(fileread(fullfile(cfgdir,configs(j))));
    [cfg,~]=swsynth.validateConfig(requested);
    result=swsynth.run(cfg);
    fields{j}=double(result.wavefield.U_zx);
    if j==1
        x=double(result.coordinates.x_m(:))*1e3;
        z=double(result.coordinates.z_m(:))*1e3;
    end
end
f=figure("Color","w","Position",[60 60 1450 470]);
tl=tiledlayout(f,1,3,"TileSpacing","compact");
maxval=max(cellfun(@(v) max(abs(v(:))),fields));
for j=1:3
    ax=nexttile(tl);
    imagesc(ax,x,z,abs(fields{j})/max(maxval,eps));
    axis(ax,"image");set(ax,"YDir","normal");
    colormap(ax,parula(256));clim(ax,[0 1]);colorbar(ax);
    xlabel(ax,"x (mm)");ylabel(ax,"z (mm)");
    title(ax,labels(j)+" — |U_z|");
end
title(tl,"Coherent x-directed force: size-dependent shear radiation");
outdir=fullfile(here,"outputs");if ~isfolder(outdir),mkdir(outdir);end
exportgraphics(f,fullfile(outdir,"aperture_comparison.png"),"Resolution",250);
close(f);
fprintf("Example 02 saved to %s\n",outdir);
