function tests=test_sh_viscoelastic_interface_coefficients
tests=functiontests(localfunctions);
end

function testElasticLimitMatchesExistingModule(tc)
addSourcePath();
p=base();p.eta1_pa_s=0;p.eta2_pa_s=0;
for theta=[0 pi/9 pi/6]
    p.incidence_angle_rad=theta;
    v=swsynth.propagation.interface.shViscoelasticCoefficients(p);
    e=struct("frequency_hz",p.frequency_hz, ...
        "incidence_angle_rad",theta, ...
        "mu1_pa",p.mu1_pa,"mu2_pa",p.mu2_pa, ...
        "rho1_kg_m3",p.rho1_kg_m3,"rho2_kg_m3",p.rho2_kg_m3);
    r=swsynth.propagation.interface.shCoefficients(e);
    verifyEqual(tc,v.reflection_displacement,r.reflection_displacement,"AbsTol",1e-12);
    verifyEqual(tc,v.transmission_displacement,r.transmission_displacement,"AbsTol",1e-12);
    checkBoundary(tc,v);
end
end

function testIdenticalLossyMedia(tc)
addSourcePath();p=base();
p.mu2_pa=p.mu1_pa;p.eta2_pa_s=p.eta1_pa_s;
p.rho2_kg_m3=p.rho1_kg_m3;
p.incidence_angle_rad=pi/5;
r=swsynth.propagation.interface.shViscoelasticCoefficients(p);
verifyEqual(tc,r.reflection_displacement,0,"AbsTol",1e-12);
verifyEqual(tc,r.transmission_displacement,1,"AbsTol",1e-12);
checkBoundary(tc,r);
end

function testLossyObliqueBoundaryConditions(tc)
addSourcePath();p=base();p.incidence_angle_rad=pi/6;
r=swsynth.propagation.interface.shViscoelasticCoefficients(p);
verifyGreaterThan(tc,imag(r.wavenumber_1_rad_m),0);
verifyGreaterThan(tc,imag(r.wavenumber_2_rad_m),0);
verifyGreaterThanOrEqual(tc,imag(r.wavenumber_normal_2_rad_m),0);
verifyTrue(tc,isfinite(r.reflection_displacement));
verifyTrue(tc,isfinite(r.transmission_displacement));
checkBoundary(tc,r);
end

function testZeroViscosityEvanescentLimit(tc)
addSourcePath();p=base();
p.eta1_pa_s=0;p.eta2_pa_s=0;
p.incidence_angle_rad=pi/3;
r=swsynth.propagation.interface.shViscoelasticCoefficients(p);
verifyGreaterThan(tc,imag(r.wavenumber_normal_2_rad_m),0);
checkBoundary(tc,r);
end

function testNegativeViscosityRejected(tc)
addSourcePath();p=base();p.eta1_pa_s=-.1;
verifyError(tc,@()swsynth.propagation.interface.shViscoelasticCoefficients(p), ...
    "swsynth:SHViscoelasticInvalidParameter");
end

function checkBoundary(tc,r)
verifyEqual(tc,r.displacement_continuity_residual,0,"AbsTol",1e-10);
verifyLessThan(tc,abs(r.traction_continuity_residual), ...
    1e-10*max(1,abs(r.complex_modulus_1_pa*r.wavenumber_normal_1_rad_m)));
end

function p=base()
p=struct("frequency_hz",500,"incidence_angle_rad",0, ...
    "mu1_pa",4000,"eta1_pa_s",.12,"rho1_kg_m3",1000, ...
    "mu2_pa",9000,"eta2_pa_s",.35,"rho2_kg_m3",1000);
end

function addSourcePath()
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
end
