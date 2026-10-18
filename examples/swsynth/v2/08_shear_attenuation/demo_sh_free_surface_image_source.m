% Exact 2D SH line-source reflection at a stress-free planar boundary.
% The x=0 boundary is traction-free; the image source lies outside x<=0.
root=fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
p=struct("x_m",-.012:.00015:0,"z_m",(-.010:.00015:.010).', ...
    "source_xz_m",[-.006 .00013],"interface_x_m",0, ...
    "frequency_hz",300,"cs_m_s",2,"reflection_enabled",true);
on=swsynth.propagation.interface.pointSHFreeSurface(p);
p.reflection_enabled=false;
off=swsynth.propagation.interface.pointSHFreeSurface(p);
fields={on.incident_uy_zx,on.reflected_uy_zx, ...
    on.total_uy_zx,off.total_uy_zx};
labels={"Incident SH","Reflected SH (image source)", ...
    "Total: free-surface reflection ON","Incident only: reflection OFF"};
figure("Name","Exact 2D SH line-source free-surface image solution");
tiledlayout(2,2);
for j=1:4
    nexttile;
    imagesc(on.x_m*1000,on.z_m*1000,real(fields{j}));
    axis image;axis xy;colorbar;hold on;xline(0,"k--");
    title(labels{j});xlabel("x (mm)");ylabel("z (mm)");
end
fprintf("Free-surface x=%.4g m, real incident/reflected SH Green fields\n", ...
    on.x_m(end));
