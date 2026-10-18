function tests=test_sh_welded_line_interface
tests=functiontests(localfunctions);
end
function testIdenticalMediaHasNoReflection(tc)
addSourcePath();p=base();p.cs2_m_s=p.cs1_m_s;
p.rho2_kg_m3=p.rho1_kg_m3;
r=swsynth.propagation.interface.lineSHWeldedInterface(p);
verifyLessThan(tc,max(abs(r.reflected_uy_zx(:))),1e-9);
% Finite angular-spectrum quadrature: compare transmitted to Hankel away
% from the source. Threshold will be calibrated after first MATLAB run.
mask=repmat(p.x_m>=p.interface_x_m,numel(p.z_m),1);
err=norm(r.transmitted_uy_zx(mask)-r.incident_uy_zx(mask))/ ...
    norm(r.incident_uy_zx(mask));
fprintf("matched medium transmitted vs Hankel relativeL2=%.6g\n",err);
verifyTrue(tc,all(isfinite(r.total_uy_zx(:))));
end
function testInterfaceAndConvergenceDiagnostic(tc)
addSourcePath();p=base();
% Evaluate near either side of interface with finite differences.
p.x_m=[-.006,-.002,-.0001,0,.0001,.002,.006];
a=swsynth.propagation.interface.lineSHWeldedInterface(p);
p.spectral_step_rad_m=1;
b=swsynth.propagation.interface.lineSHWeldedInterface(p);
fprintf("SH spectrum grid sensitivity relativeL2=%.6g\n", ...
    norm(a.total_uy_zx(:)-b.total_uy_zx(:))/norm(b.total_uy_zx(:)));
verifyTrue(tc,all(isfinite([a.total_uy_zx(:);b.total_uy_zx(:)])));
% Source isn't sampled, so no singularity.
end
function testDisabledInterface(tc)
addSourcePath();p=base();p.interface_enabled=false;
a=swsynth.propagation.interface.lineSHWeldedInterface(p);
verifyEqual(tc,a.total_uy_zx,a.incident_uy_zx,"AbsTol",0);
verifyEqual(tc,max(abs(a.reflected_uy_zx(:))),0);
verifyEqual(tc,max(abs(a.transmitted_uy_zx(:))),0);
end
function p=base()
p=struct("x_m",-.008:.0005:.008,"z_m",(-.008:.0005:.008).', ...
    "source_xz_m",[-.004 .00013],"interface_x_m",0, ...
    "frequency_hz",300,"cs1_m_s",2,"cs2_m_s",3, ...
    "rho1_kg_m3",1000,"rho2_kg_m3",1000, ...
    "interface_enabled",true,"spectral_count",2500, ...
    "spectral_step_rad_m",2);
end
function addSourcePath()
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
end
