function tests=test_controlled_sh_plane_interface
tests=functiontests(localfunctions);
end
function testDisabledReference(tc)
addSourcePath();p=base();p.interface_enabled=false;
r=swsynth.propagation.interface.simulateSHPlaneInterface(p);
verifyEqual(tc,r.total_uy_zx,r.incident_uy_zx,"AbsTol",0);
verifyEqual(tc,r.reflected_uy_zx,zeros(size(r.reflected_uy_zx)),"AbsTol",0);
verifyEqual(tc,r.transmitted_uy_zx,zeros(size(r.transmitted_uy_zx)),"AbsTol",0);
end
function testWeldedInterfaceContinuity(tc)
addSourcePath();p=base();p.interface_enabled=true;
r=swsynth.propagation.interface.simulateSHPlaneInterface(p);
xi=p.interface_x_m;z=p.z_m(:);
coeff=r.coefficients;
uLeft=(1+coeff.reflection_displacement)*exp(1i*coeff.wavenumber_tangential_rad_m*z);
uRight=coeff.transmission_displacement*exp(1i*coeff.wavenumber_tangential_rad_m*z);
verifyEqual(tc,uLeft,uRight,"AbsTol",1e-10);
verifyEqual(tc,r.total_uy_zx, ...
    r.incident_uy_zx+r.reflected_uy_zx+r.transmitted_uy_zx,"AbsTol",1e-12);
verifyGreaterThan(tc,nnz(abs(r.reflected_uy_zx)>0),0);
verifyGreaterThan(tc,nnz(abs(r.transmitted_uy_zx)>0),0);
verifyEqual(tc,coeff.displacement_continuity_residual,0,"AbsTol",1e-11);
verifyLessThan(tc,abs(coeff.traction_continuity_residual), ...
    1e-10*max(1,abs(coeff.complex_modulus_1_pa*coeff.wavenumber_normal_1_rad_m)));
verifyTrue(tc,any(abs(uLeft-uRight)<1e-10));
verifyTrue(tc,xi>min(p.x_m)&&xi<max(p.x_m));
end
function p=base()
p=struct("x_m",-.01:.00025:.01,"z_m",(-.01:.00025:.01).', ...
    "interface_x_m",0,"frequency_hz",500,"incidence_angle_rad",pi/8, ...
    "mu1_pa",4000,"eta1_pa_s",.12,"rho1_kg_m3",1000, ...
    "mu2_pa",9000,"eta2_pa_s",.35,"rho2_kg_m3",1000);
end
function addSourcePath()
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
end
