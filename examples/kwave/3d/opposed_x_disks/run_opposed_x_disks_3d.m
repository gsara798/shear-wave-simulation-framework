function out = run_opposed_x_disks_3d(config_file)
% 3D elastic k-Wave: two coherent sparse disks facing across x.
% Source motion is deliberately x-directed (normal to disks).
% Pilot saves center y-plane harmonic displacement, no REQ/REQ-ML.
arguments
 config_file (1,1) string
end
C=jsondecode(fileread(config_file));
assert(~C.attenuation_enabled,"This initial pilot is lossless.");
assert(isequal(C.source_polarization_xyz(:).',[1 0 0]), ...
 "Pilot assumes prescribed x velocity.");
dx=double(C.grid_spacing_m);
N=max(32,round(double(C.domain_size_m_xyz(:).')/dx)+1);
Nx=N(1);Ny=N(2);Nz=N(3);
x=((1:Nx)-(Nx+1)/2)*dx;
y=((1:Ny)-(Ny+1)/2)*dx;
z=((1:Nz)-(Nz+1)/2)*dx;
cfg=kwsim.three_d.defaultConfig();
cfg.grid.Nx=Nx;cfg.grid.Ny=Ny;cfg.grid.Nz=Nz;
cfg.grid.dx_m=dx;cfg.grid.dy_m=dx;cfg.grid.dz_m=dx;
cfg.source.contact_radius_m=C.disk_radius_m;
cfg.source.contact_node_spacing_points=C.source_node_spacing_points;
cfg.source.boundary_margin_m=C.source_plane_inset_m;
left_ix=1+round(C.source_plane_inset_m/dx);
right_ix=Nx-round(C.source_plane_inset_m/dx);
cy=round((Ny+1)/2);cz=round((Nz+1)/2);
left=kwsim.three_d.makeSparseDiskMaskOnFace(cfg,"x_min",[left_ix,cy,cz]);
right=kwsim.three_d.makeSparseDiskMaskOnFace(cfg,"x_max",[right_ix,cy,cz]);
assert(~any(left.mask_xyz & right.mask_xyz,"all"));
roi_ix=find(abs(x)<=C.roi_size_m_xz(1)/2);
roi_iz=find(abs(z)<=C.roi_size_m_xz(2)/2);
assert(min(roi_ix)>left_ix && max(roi_ix)<right_ix, ...
 "Sources must lie outside experimental-size FOV.");
fprintf("3D grid [%d %d %d], %.3f mm; FOV [%d %d] pixels\n", ...
 Nx,Ny,Nz,dx*1e3,numel(roi_ix),numel(roi_iz));
fprintf("Disks: %d and %d nodes; nominal cs=%g m/s\n", ...
 left.node_count,right.node_count,C.cs_m_s);
cp=C.cs_m_s*C.compressional_speed_factor;
kgrid=kWaveGrid(Nx,dx,Ny,dx,Nz,dx);
f=C.frequency_hz;
T=(C.settling_cycles+C.analysis_cycles)/f;
kgrid.makeTime(cp,C.cfl,T);
t=double(kgrid.t_array(:).');
drive=double(C.source_velocity_amplitude_m_s);
ramp_duration=3/f;
ramp=ones(size(t));
q=t<ramp_duration;
ramp(q)=0.5*(1-cos(pi*t(q)/ramp_duration));
left_wave=drive*ramp.*sin(2*pi*f*t);
right_wave=drive*ramp.*sin(2*pi*f*t+C.source_relative_phase_rad);
owner=zeros(Nx,Ny,Nz,"uint8");
owner(left.mask_xyz)=1;
owner(right.mask_xyz)=2;
src=struct();
src.u_mask=owner>0;
owner_rows=owner(src.u_mask);
src.ux=zeros(nnz(src.u_mask),numel(t),"single");
src.ux(owner_rows==1,:)=repmat(single(left_wave),nnz(owner_rows==1),1);
src.ux(owner_rows==2,:)=repmat(single(right_wave),nnz(owner_rows==2),1);
src.uy=zeros(size(src.ux),"single");
src.uz=zeros(size(src.ux),"single");
src.u_mode="dirichlet";
medium=struct();
medium.sound_speed_compression=single(cp)*ones(Nx,Ny,Nz,"single");
medium.sound_speed_shear=single(C.cs_m_s)*ones(Nx,Ny,Nz,"single");
medium.density=single(C.density_kg_m3)*ones(Nx,Ny,Nz,"single");
sensor=struct();
sensor.mask=false(Nx,Ny,Nz);
sensor.mask(:,cy,:)=true; % central x-z acquisition plane only
sensor.record={"u_split_field"};
recNt=min(numel(t),ceil(C.analysis_cycles/f/kgrid.dt)+1);
recStart=numel(t)-recNt+1;
sensor.record_start_index=recStart;
outdir=string(C.output_dir);
if ~isfolder(outdir),mkdir(outdir);end
runfile=fullfile(outdir,"run.mat");
assert(~isfile(runfile)||C.overwrite, ...
 "Result already exists; change output_dir or enable overwrite.");
fprintf("Running pstdElastic3D, dt=%.3g s, steps=%d, sensor points=%d\n", ...
 kgrid.dt,numel(t),nnz(sensor.mask));
args={"PMLInside",false,"PMLSize",double(C.pml_size_points(:).'), ...
 "PlotSim",false,"DataCast","single"};
tic
raw=pstdElastic3D(kgrid,medium,src,sensor,args{:});
elapsed=toc;
tt=t(recStart:end);
required=["ux_split_s","ux_split_p","uz_split_s","uz_split_p"];
for name=required
 assert(isfield(raw,name),"Missing k-Wave component: "+name);
end
% 3D solver records [sensor point,time], in find(mask) ordering.
% plane mask uses all x,z and fixed y, so reshape rows as [Nx,Nz].
H=struct();
for name=required
 v=raw.(name);
 assert(isequal(size(v),[Nx*Nz,numel(tt)]),"Unexpected sensor layout.");
 h=kwsim.three_d.extractHarmonicSensorData(v,tt,f,Method="least_squares");
 a=reshape(h,Nx,Nz).';
 H.(name)=a(roi_iz,roi_ix)/(1i*2*pi*f);
end
H.uz_total=H.uz_split_s+H.uz_split_p;
H.ux_total=H.ux_split_s+H.ux_split_p;
result=struct();
result.config=C;
result.axes=struct("x_m",x(roi_ix),"z_m",z(roi_iz),"y_m",y(cy), ...
 "dx_m",dx,"dz_m",dx);
result.fields=struct("axial_shear_displacement_zx",H.uz_split_s, ...
 "axial_compression_displacement_zx",H.uz_split_p, ...
 "axial_total_displacement_zx",H.uz_total, ...
 "lateral_shear_displacement_zx",H.ux_split_s, ...
 "lateral_total_displacement_zx",H.ux_total);
result.truth=struct("cs_m_s_zx",C.cs_m_s*ones(numel(roi_iz),numel(roi_ix)));
result.source=struct("left_center_index_xyz",left.center_index_xyz, ...
 "right_center_index_xyz",right.center_index_xyz, ...
 "left_node_count",left.node_count,"right_node_count",right.node_count, ...
 "left_mask_xyz",left.mask_xyz,"right_mask_xyz",right.mask_xyz, ...
 "velocity_direction_xyz",[1 0 0],"phase_offset_rad",C.source_relative_phase_rad);
result.provenance=struct("simulation_framework","kwsim", ...
 "solver","pstdElastic3D","runtime_seconds",elapsed, ...
 "time_steps",numel(t),"dt_s",kgrid.dt, ...
 "phasor_convention","real(U exp(iwt))", ...
 "note","x-driven disks excite compressional waves prominently; this is not transverse shear excitation.");
save(runfile,"result","-v7.3");
copyfile(config_file,fullfile(outdir,"resolved_input.json"));
fig=figure("Visible","off","Color","w","Position",[50 50 1500 900]);
tl=tiledlayout(fig,2,3,"TileSpacing","compact");
maps={abs(H.uz_total),angle(H.uz_total),abs(H.uz_split_s), ...
 abs(H.ux_split_s),abs(H.uz_split_p),abs(H.ux_total)};
titles=["Axial total amplitude |Uz|","Axial total phase", ...
 "Axial shear |Uz,s|","Lateral shear |Ux,s|", ...
 "Axial compression |Uz,p|","Lateral total |Ux|"];
for j=1:6
 ax=nexttile(tl);
 imagesc(ax,x(roi_ix)*1000,z(roi_iz)*1000,maps{j});
 set(ax,"YDir","normal");axis(ax,"image");colorbar(ax);
 xlabel(ax,"x [mm]");ylabel(ax,"z [mm]");title(ax,titles(j));
end
title(tl,sprintf("3D opposed x-driven disks | cs=%.2f m/s | f=%g Hz",C.cs_m_s,f));
exportgraphics(fig,fullfile(outdir,"central_xz_plane.png"),"Resolution",200);
close(fig);
out=struct("run_file",runfile,"figure_file", ...
 fullfile(outdir,"central_xz_plane.png"),"elapsed_s",elapsed);
end
