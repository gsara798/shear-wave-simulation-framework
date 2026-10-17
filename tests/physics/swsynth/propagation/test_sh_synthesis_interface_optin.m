function tests=test_sh_synthesis_interface_optin
tests=functiontests(localfunctions);
end
function testEnabledSHInterfaceInSynthesis(tc)
addSourcePath();
s=scenario();
r=swsynth.propagation.synthesize(s);
verifyEqual(tc,size(r.U_xyz),[numel(r.domain.z_m),numel(r.domain.x_m),3]);
verifyEqual(tc,r.U_xyz(:,:,2),r.interface_components.total_uy_zx,"AbsTol",1e-11);
verifyEqual(tc,r.U_xyz(:,:,[1 3]),complex(zeros(numel(r.domain.z_m),numel(r.domain.x_m),2)),"AbsTol",0);
verifyEqual(tc,r.propagation.interface_enabled,true);
verifyTrue(tc,any(abs(r.interface_components.reflected_uy_zx(:))>0));
end
function testRejectUnsupportedPolarization(tc)
addSourcePath();s=scenario();
s.incidence.polarization.explicit_polarization_xyz=[0 0 1];
verifyError(tc,@()swsynth.propagation.synthesize(s), ...
    "swsynth:UnsupportedSHInterfacePolarization");
end
function s=scenario()
s=struct();
s.geometry="projected3d";
s.domain=struct("Lx_m",.024,"Lz_m",.024,"dx_m",.001, ...
    "dz_m",.001,"observation_y_m",0);
a=struct("model","kelvin_voigt","density_kg_m3",1000, ...
    "mu_pa",9000,"eta_pa_s",.35);
obj=struct("type","bilayer","normal_angle_rad",0, ...
    "offset_m",.012,"cs_m_s",3,"viscoelastic",a);
s.medium=struct("background_cs_m_s",2, ...
    "viscoelastic",struct("model","kelvin_voigt", ...
    "density_kg_m3",1000,"mu_pa",4000,"eta_pa_s",.12), ...
    "objects",{{obj}});
s.harmonic=struct("frequency_hz",500,"quantity","relative_motion");
s.propagation=struct("model","plane_wave", ...
    "phase_method","eikonal","normalization","none", ...
    "interface",struct("enabled",true,"reference_x_m",0));
s.incidence=struct("direction_xyz",[cos(pi/6) 0 sin(pi/6)], ...
    "relative_amplitude",1,"phase_rad",0, ...
    "polarization",struct("policy","transverse_explicit", ...
    "explicit_polarization_xyz",[0 1 0]));
end
function addSourcePath()
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
end
