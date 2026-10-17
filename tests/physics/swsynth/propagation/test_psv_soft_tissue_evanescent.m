function tests=test_psv_soft_tissue_evanescent
tests=functiontests(localfunctions);
end
function testConvertedPDecayAndBoundary(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
p=struct("frequency_hz",500,"incidence_angle_rad",pi/9, ...
    "cp1_m_s",1540,"cs1_m_s",2,"rho1_kg_m3",1000, ...
    "cp2_m_s",1560,"cs2_m_s",3,"rho2_kg_m3",1050);
r=swsynth.propagation.interface.psvElasticCoefficients(p);
omega=2*pi*p.frequency_hz;kt=r.tangential_wavenumber_rad_m;
qr=-sqrt(complex((omega/p.cp1_m_s)^2-kt^2,0));
qt=sqrt(complex((omega/p.cp2_m_s)^2-kt^2,0));
verifyLessThan(tc,imag(qr),0);
verifyGreaterThan(tc,imag(qt),0);
% Both outgoing evanescent magnitudes must strictly decrease away from x=0.
depth=.004;
verifyLessThan(tc,abs(exp(1i*qr*(-depth))),1);
verifyLessThan(tc,abs(exp(1i*qt*(depth))),1);
verifyLessThan(tc,norm(r.boundary_residual), ...
    1e-9*max(1,norm(r.incident_state)));
f=[r.reflected_P_energy_fraction,r.reflected_SV_energy_fraction, ...
    r.transmitted_P_energy_fraction,r.transmitted_SV_energy_fraction];
verifyEqual(tc,f([1 3]),[0 0],"AbsTol",1e-9);
verifyEqual(tc,sum(f),1,"AbsTol",1e-9);
end
