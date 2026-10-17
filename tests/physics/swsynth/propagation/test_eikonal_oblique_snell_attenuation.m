function tests=test_eikonal_oblique_snell_attenuation
% Independent Fermat reference for first-arrival refraction and loss.
tests=functiontests(localfunctions);
end

function testObliqueRefractionAndOpticalDepth(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
x=0:.001:.018;z=(0:.001:.018).';
xi=.008;
src=[-.006 0 .006];
c1=2;c2=3;a1=8;a2=35;
speed=c1*ones(numel(z),numel(x));
speed(:,x>=xi)=c2;
alpha=a1*ones(size(speed));alpha(:,x>=xi)=a2;
plane=struct("normal_xyz",[1 0 0],"offset_m",xi, ...
    "alpha_negative_np_m",a1,"alpha_positive_np_m",a2);
% Off-axis receiver points, all beyond interface; source and receivers y=0.
targets=[.012 0 .010;.014 0 .013;.016 0 .003;.018 0 .016];
hValues=[.002 .0015 .001];
ix=zeros(size(targets,1),1); iz=ix;
for j=1:size(targets,1)
    [~,ix(j)]=min(abs(x-targets(j,1)));
    [~,iz(j)]=min(abs(z-targets(j,3)));
end
for h=hValues
    opts=struct("SpatialOrder",2,"GridSpacingM",h, ...
        "MaxGridCells",400000,"MaximumIterations",200, ...
        "ToleranceS",1e-9,"AttenuationPlane",plane);
    [T,A,d]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
        speed,alpha,x,z,src,0,opts);
    verifyTrue(tc,d.solver.converged);
    eT=zeros(size(targets,1),1);
    eA=eT;
    for j=1:size(targets,1)
        q=targets(j,:);
        [tref,aref,theta1,theta2]=fermatTwoLayer(src,q,xi,c1,c2,a1,a2);
        % Use exact coordinates of grid-aligned observation targets.
        tnum=T(iz(j),ix(j));
        anum=A(iz(j),ix(j));
        eT(j)=abs(tnum-tref)/tref;
        eA(j)=abs(anum-aref)/aref;
        fprintf("h=%.4g target=[%.3f %.3f %.3f] angle1_deg=%.3f angle2_deg=%.3f timeError=%.6g opticalError=%.6g\n", ...
            h,q(1),q(2),q(3),rad2deg(theta1),rad2deg(theta2),eT(j),eA(j));
        verifyLessThan(tc,abs(sin(theta1)/c1-sin(theta2)/c2),1e-10, ...
            "Fermat reference must satisfy Snell's law.");
        verifyTrue(tc,all(isfinite([tnum anum])));
        verifyGreaterThanOrEqual(tc,anum,0);
    end
    fprintf("h=%.4g relative time errors=%s; relative optical errors=%s\n", ...
        h,mat2str(eT.',4),mat2str(eA.',4));
end
end

function [t,a,theta1,theta2]=fermatTwoLayer(src,q,xi,c1,c2,a1,a2)
% Two isotropic half-spaces with planar interface x=xi, same y coordinate.
% A crossing at [xi,0,zeta] minimizes L1/c1+L2/c2 (Fermat).
assert(abs(src(2)-q(2))<1e-12 && src(1)<xi && q(1)>xi)
% Solve the stationarity condition directly. Unlike minimizing a nearly
% flat travel-time curve, this gives a well-conditioned Snell residual.
d1=xi-src(1); d2=q(1)-xi;
stationarity=@(zc) (zc-src(3))./(c1*hypot(d1,zc-src(3))) + ...
    (zc-q(3))./(c2*hypot(d2,q(3)-zc));
lo=min(src(3),q(3));hi=max(src(3),q(3));
if hi==lo
    zc=lo;
else
    zc=fzero(stationarity,[lo hi],optimset("TolX",1e-13));
end
l1=hypot(xi-src(1),zc-src(3));
l2=hypot(q(1)-xi,q(3)-zc);
t=l1/c1+l2/c2;
a=a1*l1+a2*l2;
theta1=atan2(abs(zc-src(3)),xi-src(1));
theta2=atan2(abs(q(3)-zc),q(1)-xi);
end
