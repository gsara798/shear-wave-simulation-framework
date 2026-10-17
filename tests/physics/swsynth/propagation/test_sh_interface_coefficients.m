function tests=test_sh_interface_coefficients
tests=functiontests(localfunctions);
end

function testMatchedMaterials(tc)
addSourcePath();
p=base(); p.incidence_angle_rad=pi/5;
r=swsynth.propagation.interface.shCoefficients(p);
verifyEqual(tc,r.reflection_displacement,0,"AbsTol",1e-12);
verifyEqual(tc,r.transmission_displacement,1,"AbsTol",1e-12);
verifyEqual(tc,r.reflection_energy_fraction+r.transmission_energy_fraction,1,"AbsTol",1e-12);
end

function testNormalIncidenceImpedance(tc)
addSourcePath();
p=base();p.mu2_pa=9000;
r=swsynth.propagation.interface.shCoefficients(p);
z1=sqrt(p.mu1_pa*p.rho1_kg_m3);
z2=sqrt(p.mu2_pa*p.rho2_kg_m3);
verifyEqual(tc,r.reflection_displacement,(z1-z2)/(z1+z2),"AbsTol",1e-12);
verifyEqual(tc,r.transmission_displacement,2*z1/(z1+z2),"AbsTol",1e-12);
checkBoundaryAndEnergy(tc,r);
end

function testObliqueSnellAndEnergy(tc)
addSourcePath();
p=base();p.mu2_pa=9000;p.incidence_angle_rad=pi/6;
r=swsynth.propagation.interface.shCoefficients(p);
theta2=asin(r.phase_speed_2_m_s/r.phase_speed_1_m_s*sin(p.incidence_angle_rad));
verifyEqual(tc,real(r.wavenumber_normal_2_rad_m), ...
    2*pi*p.frequency_hz/r.phase_speed_2_m_s*cos(theta2),"RelTol",1e-12);
checkBoundaryAndEnergy(tc,r);
verifyGreaterThan(tc,r.reflection_energy_fraction,0);
verifyGreaterThan(tc,r.transmission_energy_fraction,0);
end

function testTotalInternalReflection(tc)
addSourcePath();
p=base();p.mu1_pa=4000;p.mu2_pa=9000;
p.incidence_angle_rad=pi/3;
r=swsynth.propagation.interface.shCoefficients(p);
verifyTrue(tc,r.is_evanescent);
verifyEqual(tc,r.reflection_energy_fraction,1,"AbsTol",1e-12);
verifyEqual(tc,r.transmission_energy_fraction,0,"AbsTol",1e-12);
checkBoundaryAndEnergy(tc,r);
end

function testInvalidInputRejected(tc)
addSourcePath();
p=base();p.mu1_pa=-1;
verifyError(tc,@()swsynth.propagation.interface.shCoefficients(p), ...
    "swsynth:SHInterfaceInvalidParameter");
end

function checkBoundaryAndEnergy(tc,r)
verifyEqual(tc,r.displacement_continuity_residual,0,"AbsTol",1e-10);
verifyEqual(tc,r.traction_continuity_residual,0,"AbsTol",1e-7);
verifyEqual(tc,r.reflection_energy_fraction+r.transmission_energy_fraction, ...
    1,"AbsTol",1e-10);
end

function p=base()
p=struct("frequency_hz",500,"incidence_angle_rad",0, ...
    "mu1_pa",4000,"rho1_kg_m3",1000, ...
    "mu2_pa",4000,"rho2_kg_m3",1000);
end

function addSourcePath()
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
end
