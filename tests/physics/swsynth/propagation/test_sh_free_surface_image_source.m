function tests=test_sh_free_surface_image_source
tests=functiontests(localfunctions);
end
function testMirrorSymmetryAndSwitch(tc)
addSourcePath();
p=base();a=swsynth.propagation.interface.pointSHFreeSurface(p);
p.reflection_enabled=false;b=swsynth.propagation.interface.pointSHFreeSurface(p);
verifyEqual(tc,b.total_uy_zx,b.incident_uy_zx,"AbsTol",0);
verifyEqual(tc,b.reflected_uy_zx,complex(zeros(size(b.incident_uy_zx))),"AbsTol",0);
verifyEqual(tc,a.total_uy_zx,a.incident_uy_zx+a.reflected_uy_zx,"AbsTol",1e-12);
verifyEqual(tc,a.image_source_xz_m,[.006 .00013],"AbsTol",1e-12);
% Exact traction-free Neumann boundary: even image symmetry at x=0.
z=p.z_m(:);h=1e-5;
p.x_m=[-h 0];c=swsynth.propagation.interface.pointSHFreeSurface(p);
% At the boundary, source and mirror distances agree exactly.
verifyEqual(tc,c.incident_uy_zx(:,2),c.reflected_uy_zx(:,2),"AbsTol",1e-12);
verifyTrue(tc,all(isfinite(a.total_uy_zx(:))));
end
function testBoundaryDerivativeNumerically(tc)
addSourcePath();p=base();h=1e-6;
p.x_m=[-2*h,-h,0];
r=swsynth.propagation.interface.pointSHFreeSurface(p);
% Second-order one-sided derivative at x=0 should be zero.
derivative=(3*r.total_uy_zx(:,3)-4*r.total_uy_zx(:,2)+ ...
    r.total_uy_zx(:,1))/(2*h);
verifyLessThan(tc,max(abs(derivative)),.03);
end
function p=base()
p=struct("x_m",-.012:.0002:0,"z_m",(-.010:.0002:.010).', ...
    "source_xz_m",[-.006 .00013],"interface_x_m",0, ...
    "frequency_hz",300,"cs_m_s",2,"reflection_enabled",true);
end
function addSourcePath()
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
end
