function tests=test_eikonal_planar_speed_sampling_comparison
% A/B: identical Fermat/Snell problem, change only extended speed sampling.
tests=functiontests(localfunctions);
end

function testGeometryVersusNearestMap(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
x=0:.001:.018;z=(0:.001:.018).';
src=[-.006 0 .006]; xi=.008; c1=2;c2=3;a1=8;a2=35;
speed=c1*ones(numel(z),numel(x));speed(:,x>=xi)=c2;
alpha=a1*ones(size(speed));alpha(:,x>=xi)=a2;
lossPlane=struct("normal_xyz",[1 0 0],"offset_m",xi, ...
    "alpha_negative_np_m",a1,"alpha_positive_np_m",a2);
speedPlane=struct("normal_xyz",[1 0 0],"offset_m",xi, ...
    "speed_negative_m_s",c1,"speed_positive_m_s",c2);
targets=[.012 0 .010;.014 0 .013;.016 0 .003;.018 0 .016];
ix=zeros(4,1);iz=ix; tref=zeros(4,1);aref=tref;
for j=1:4
    [~,ix(j)]=min(abs(x-targets(j,1)));
    [~,iz(j)]=min(abs(z-targets(j,3)));
    [tref(j),aref(j)]=fermatReference(src,targets(j,:),xi,c1,c2,a1,a2);
end
fprintf("\nSpeed sampling A/B vs independent Fermat reference\n");
for h=[.002 .0015 .001 .00075]
    opts=struct("SpatialOrder",2,"GridSpacingM",h, ...
        "MaxGridCells",800000,"MaximumIterations",200, ...
        "ToleranceS",1e-9,"AttenuationPlane",lossPlane);
    [tn,an,dn]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
        speed,alpha,x,z,src,0,opts);
    opts.SpeedInterfacePlane=speedPlane;
    [tg,ag,dg]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
        speed,alpha,x,z,src,0,opts);
    en=zeros(4,1);eg=en;lan=en;lag=en;
    for j=1:4
        en(j)=abs(tn(iz(j),ix(j))-tref(j))/tref(j);
        eg(j)=abs(tg(iz(j),ix(j))-tref(j))/tref(j);
        lan(j)=abs(an(iz(j),ix(j))-aref(j))/aref(j);
        lag(j)=abs(ag(iz(j),ix(j))-aref(j))/aref(j);
    end
    fprintf("h=%.5g nearest time=%s planar time=%s\n",h,mat2str(en.',4),mat2str(eg.',4));
    fprintf("         nearest optical=%s planar optical=%s\n",mat2str(lan.',4),mat2str(lag.',4));
    fprintf("         mean time nearest=%.6g planar=%.6g; mean optical nearest=%.6g planar=%.6g\n", ...
        mean(en),mean(eg),mean(lan),mean(lag));
    verifyTrue(tc,dn.solver.converged && dg.solver.converged);
    verifyEqual(tc,string(dn.speed_sampling),"nearest_map");
    verifyEqual(tc,string(dg.speed_sampling),"exact_planar_geometry_nodes");
    verifyTrue(tc,all(isfinite([en;eg;lan;lag])));
end
end

function [t,a]=fermatReference(src,q,xi,c1,c2,a1,a2)
d1=xi-src(1);d2=q(1)-xi;
stationarity=@(zc) (zc-src(3))./(c1*hypot(d1,zc-src(3)))+ ...
    (zc-q(3))./(c2*hypot(d2,q(3)-zc));
lo=min(src(3),q(3));hi=max(src(3),q(3));
if lo==hi
    zc=lo;
else
    zc=fzero(stationarity,[lo hi],optimset("TolX",1e-13));
end
L1=hypot(d1,zc-src(3));L2=hypot(d2,q(3)-zc);
t=L1/c1+L2/c2;
a=a1*L1+a2*L2;
end
