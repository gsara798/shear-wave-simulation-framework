% Controlled SH plane-wave Kelvin-Voigt interface demonstration.
% This standalone example does not modify scenario synthesis or point sources.
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
req=struct("x_m",-.012:.0002:.012,"z_m",(-.012:.0002:.012).', ...
    "interface_x_m",0,"frequency_hz",500,"incidence_angle_rad",pi/6, ...
    "mu1_pa",4000,"eta1_pa_s",.12,"rho1_kg_m3",1000, ...
    "mu2_pa",9000,"eta2_pa_s",.35,"rho2_kg_m3",1000, ...
    "interface_enabled",true);
on=swsynth.propagation.interface.simulateSHPlaneInterface(req);
req.interface_enabled=false;
off=swsynth.propagation.interface.simulateSHPlaneInterface(req);
figure("Name","Controlled Kelvin-Voigt plane SH interface");
tiledlayout(2,2);
fields={on.incident_uy_zx,on.reflected_uy_zx, ...
    on.transmitted_uy_zx,on.total_uy_zx};
labels={"Incident (on)","Reflected (on)","Transmitted (on)","Total (on)"};
for j=1:4
    nexttile;
    imagesc(on.x_m*1000,on.z_m*1000,real(fields{j}));
    axis image;axis xy;colorbar;
    xline(on.interface_x_m*1000,"k--");
    xlabel("x (mm)");ylabel("z (mm)");
    title(labels{j});
end
figure("Name","Interface switch off: uninterrupted reference");
imagesc(off.x_m*1000,off.z_m*1000,real(off.total_uy_zx));
axis image;axis xy;colorbar;
xlabel("x (mm)");ylabel("z (mm)");
title("Interface OFF: incident wave everywhere");
fprintf("SH Kelvin-Voigt interface R=%g%+gi T=%g%+gi\n", ...
    real(on.coefficients.reflection_displacement), ...
    imag(on.coefficients.reflection_displacement), ...
    real(on.coefficients.transmission_displacement), ...
    imag(on.coefficients.transmission_displacement));
