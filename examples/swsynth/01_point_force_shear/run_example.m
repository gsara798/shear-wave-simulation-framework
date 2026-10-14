%% Example 01: point-force far-field shear radiation (swsynth API).
% This is a radiation projector, NOT full elastodynamic Green / P waves.
here=string(fileparts(mfilename("fullpath")));
root=string(fileparts(fileparts(fileparts(here))));
addpath(fullfile(root,"src"));
cfgdir=fullfile(root,"configs","swsynth","validation","point_force_shear_radiation");
config_files=["source_x_uz.json","source_z_uz.json"];
labels=["force_x","force_z"];
fields=cell(1,2);
for j=1:2
    requested=jsondecode(fileread(fullfile(cfgdir,config_files(j))));
    [cfg,~]=swsynth.validateConfig(requested);
    result=swsynth.run(cfg);
    fields{j}=result.wavefield.U_zx;
    if j==1
        x=double(result.coordinates.x_m(:))*1e3;
        z=double(result.coordinates.z_m(:))*1e3;
    end
end
f=figure("Color","w","Position",[100 100 1150 470]);
tl=tiledlayout(f,1,2,"TileSpacing","compact");
maxval=max(cellfun(@(v) max(abs(v(:))),fields));
for j=1:2
    ax=nexttile(tl);
    imagesc(ax,x,z,real(double(fields{j}))/max(maxval,eps));
    axis(ax,"image");set(ax,"YDir","normal");colorbar(ax);
    colormap(ax,parula(256));clim(ax,[-1 1]);
    xlabel(ax,"x (mm)");ylabel(ax,"z (mm)");
    title(ax,labels(j)+" — real(U_z)");
end
title(tl,"Spherical shear radiation: point force; common scale");
outdir=fullfile(here,"outputs");if ~isfolder(outdir),mkdir(outdir);end
exportgraphics(f,fullfile(outdir,"point_force_radiation.png"),"Resolution",250);
close(f);
fprintf("Example 01 saved to %s\n",outdir);
