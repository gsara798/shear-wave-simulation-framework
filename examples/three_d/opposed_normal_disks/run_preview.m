%% Opposed x-normal disks: framework-native 3D pilot (no REQ-ML).
here=string(fileparts(mfilename("fullpath")));
framework_root=string(fileparts(fileparts(fileparts(here))));
addpath(fullfile(framework_root,"src"));
config_file=fullfile(here,"base_config.json");
[cfg,meta]=kwsim.io.loadConfigJson(config_file);
[cfg_check,preflight]=kwsim.three_d.validateConfig(cfg);
disp(preflight.memory);
fprintf("Source pair: %s, %d contacts\n",cfg_check.source.bank_name, ...
 cfg_check.source.vibrator_count);
% Run through framework solver, grid, source and harmonics.
result=kwsim.three_d.run(cfg);
% The normal-x drive includes compressional waves; generic shear-only
% validation scenarios are intentionally NOT used for this pilot.
paths=kwsim.io.saveSimulationResult(result);
sample=kwsim.samples.buildWavefieldSample(result,Quantity="displacement");
sample_path=kwsim.samples.saveWavefieldSample(sample,paths);
fprintf("Saved field sample: %s\n",sample_path);
% Two-dimensional acquisition plane has [Nz,1,Nx] in the public output.
x=1000*double(result.axes.x_m);
z=1000*double(result.axes.z_m);
D=result.fields.displacement;
extract=@(v) squeeze(v(:,1,:));
Uz=extract(D.z_total_zyx);
UzS=extract(D.z_shear_zyx);
UzP=extract(D.z_compression_zyx);
Ux=extract(D.x_total_zyx);
amps={abs(Uz),angle(Uz),abs(UzS),abs(UzP),abs(Ux),abs(UzS)./max(abs(Ux),eps)};
names=["Axial total amplitude","Axial total phase","Axial shear amplitude", ...
 "Axial compression amplitude","Lateral total amplitude","Shear axial / lateral ratio"];
fig=figure("Visible","off","Color","w","Position",[60 60 1380 850]);
tl=tiledlayout(fig,2,3,"TileSpacing","compact");
for j=1:6
 ax=nexttile(tl);
 imagesc(ax,x,z,amps{j});
 axis(ax,"image");set(ax,"YDir","normal");colorbar(ax);
 xlabel(ax,"x [mm]");ylabel(ax,"z [mm]");title(ax,names(j));
end
title(tl,"Opposed x-normal disks: central acquisition plane");
if ~isfolder(paths.figures),mkdir(paths.figures);end
exportgraphics(fig,fullfile(paths.figures,"opposed_disks_field_components.png"), ...
 "Resolution",200);
close(fig);
fprintf("Saved simulation and figures to: %s\n",paths.run);
