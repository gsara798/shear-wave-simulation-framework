function tests=test_elastic_mixed_shear_coefficients
tests=functiontests(localfunctions);
end
function testPureSH(tc)
addSourcePath();p=base();p.shear_polarization_xyz=[0 1 0];
r=swsynth.propagation.interface.elasticMixedShearCoefficients(p);
verifyEqual(tc,r.incident_SH_amplitude,1,"AbsTol",1e-12);
verifyEqual(tc,r.incident_SV_amplitude,0,"AbsTol",1e-12);
verifyEqual(tc,[r.reflected_P_amplitude,r.transmitted_P_amplitude],[0 0],"AbsTol",1e-12);
end
function testPureSV(tc)
addSourcePath();p=base();theta=p.incidence_angle_rad;
p.shear_polarization_xyz=[-sin(theta),0,cos(theta)];
r=swsynth.propagation.interface.elasticMixedShearCoefficients(p);
verifyEqual(tc,r.incident_SH_amplitude,0,"AbsTol",1e-12);
verifyEqual(tc,r.incident_SV_amplitude,1,"AbsTol",1e-12);
verifyEqual(tc,r.reflected_SH_amplitude,0,"AbsTol",1e-12);
end
function testMixedSuperposition(tc)
addSourcePath();p=base();theta=p.incidence_angle_rad;
p.shear_polarization_xyz=([0 1 0]+[-sin(theta) 0 cos(theta)])/sqrt(2);
r=swsynth.propagation.interface.elasticMixedShearCoefficients(p);
verifyEqual(tc,[r.incident_SH_amplitude,r.incident_SV_amplitude], ...
    [1 1]/sqrt(2),"AbsTol",1e-12);
verifyEqual(tc,r.reflected_P_amplitude, ...
    r.incident_SV_amplitude*r.PSV.reflection_P_displacement,"AbsTol",1e-12);
end
function testNontransverseRejected(tc)
addSourcePath();p=base();p.shear_polarization_xyz=[1 0 0];
verifyError(tc,@()swsynth.propagation.interface.elasticMixedShearCoefficients(p), ...
    "swsynth:MixedShearNontransverse");
end
function p=base()
p=struct("frequency_hz",500,"incidence_angle_rad",pi/9, ...
    "cp1_m_s",1540,"cs1_m_s",2,"rho1_kg_m3",1000, ...
    "cp2_m_s",1560,"cs2_m_s",3,"rho2_kg_m3",1050);
end
function addSourcePath()
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
end
