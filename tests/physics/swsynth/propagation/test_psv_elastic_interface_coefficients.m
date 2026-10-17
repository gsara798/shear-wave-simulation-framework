function tests=test_psv_elastic_interface_coefficients
tests=functiontests(localfunctions);
end
function testMatchedMedia(tc)
addSourcePath();p=base();p.cp2_m_s=p.cp1_m_s;p.cs2_m_s=p.cs1_m_s;
p.rho2_kg_m3=p.rho1_kg_m3;
p.incidence_angle_rad=pi/7;
r=swsynth.propagation.interface.psvElasticCoefficients(p);
verifyEqual(tc,r.reflection_P_displacement,0,"AbsTol",1e-10);
verifyEqual(tc,r.reflection_SV_displacement,0,"AbsTol",1e-10);
verifyEqual(tc,r.transmission_P_displacement,0,"AbsTol",1e-10);
verifyEqual(tc,r.transmission_SV_displacement,1,"AbsTol",1e-10);
checkBoundary(tc,r);
end
function testNormalIncidenceNoConversion(tc)
addSourcePath();p=base();p.incidence_angle_rad=0;
r=swsynth.propagation.interface.psvElasticCoefficients(p);
verifyEqual(tc,r.reflection_P_displacement,0,"AbsTol",1e-10);
verifyEqual(tc,r.transmission_P_displacement,0,"AbsTol",1e-10);
checkBoundary(tc,r);
end
function testObliqueConversionAndEnergy(tc)
addSourcePath();p=base();p.incidence_angle_rad=pi/9;
r=swsynth.propagation.interface.psvElasticCoefficients(p);
verifyGreaterThan(tc,abs(r.reflection_P_displacement)+ ...
    abs(r.transmission_P_displacement),1e-8);
checkBoundary(tc,r);
fractions=[r.reflected_P_energy_fraction,r.reflected_SV_energy_fraction, ...
    r.transmitted_P_energy_fraction,r.transmitted_SV_energy_fraction];
verifyGreaterThanOrEqual(tc,min(fractions),-1e-10);
verifyEqual(tc,sum(fractions),1,"AbsTol",1e-9);
end
function testCriticalEvanescentP(tc)
addSourcePath();p=base();p.incidence_angle_rad=pi/3;
r=swsynth.propagation.interface.psvElasticCoefficients(p);
checkBoundary(tc,r);
verifyTrue(tc,all(isfinite([r.reflection_P_displacement, ...
    r.reflection_SV_displacement,r.transmission_P_displacement, ...
    r.transmission_SV_displacement])));
end
function checkBoundary(tc,r)
verifyLessThan(tc,norm(r.boundary_residual), ...
    1e-10*max(1,norm(r.incident_state)));
end
function p=base()
p=struct("frequency_hz",500,"incidence_angle_rad",0, ...
    "cp1_m_s",5,"cs1_m_s",2,"rho1_kg_m3",1000, ...
    "cp2_m_s",7,"cs2_m_s",3,"rho2_kg_m3",1100);
end
function addSourcePath()
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
end
