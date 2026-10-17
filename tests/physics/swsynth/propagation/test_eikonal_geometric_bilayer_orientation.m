function tests=test_eikonal_geometric_bilayer_orientation
% Regression for inclined planes and truly off-plane external sources.
tests=functiontests(localfunctions);
end

function testInclinedOffPlaneWithHomogeneousSpeed(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
x=0:.001:.012;z=(0:.001:.012).';
src=[-.004 .005 .006];obsY=0;
angle=pi/6;normal=[cos(angle),0,sin(angle)];offset=.007;
plane=struct("normal_xyz",normal,"offset_m",offset, ...
    "alpha_negative_np_m",8,"alpha_positive_np_m",35);
speedPlane=struct("normal_xyz",normal,"offset_m",offset, ...
    "speed_negative_m_s",2,"speed_positive_m_s",2);
[Z,X]=ndgrid(z,x);
signed=X*normal(1)+Z*normal(3)-offset;
speed=2*ones(size(X));
loss=8*ones(size(X));loss(signed>0)=35;
opts=struct("GridSpacingM",.001,"SpatialOrder",2, ...
    "MaxGridCells",400000,"MaximumIterations",200, ...
    "ToleranceS",1e-9,"AttenuationPlane",plane, ...
    "SpeedInterfacePlane",speedPlane);
[T,A,d]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
    speed,loss,x,z,src,obsY,opts);
verifyTrue(tc,d.solver.converged);
verifyEqual(tc,string(d.speed_sampling),"exact_planar_geometry_nodes");
targets=[X(:),obsY*ones(numel(X),1),Z(:)];
starts=repmat(src,numel(X),1);
expected=swsynth.propagation.attenuation.integratePlanarSegment(starts,targets,plane);
verifyEqual(tc,A(:),expected,"AbsTol",1e-11);
verifyTrue(tc,all(isfinite(T(:))));
end

function testInclinedOffPlaneRefractedTravelTimes(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
x=0:.001:.012;z=(0:.001:.012).';
src=[-.004 .004 .003];obsY=0;
angle=pi/6;n=[cos(angle),0,sin(angle)];offset=.007;
[Z,X]=ndgrid(z,x);
signed=X*n(1)+Z*n(3)-offset;
speed=2*ones(size(X));speed(signed>0)=3;
loss=8*ones(size(X));loss(signed>0)=35;
speedPlane=struct("normal_xyz",n,"offset_m",offset, ...
    "speed_negative_m_s",2,"speed_positive_m_s",3);
lossPlane=struct("normal_xyz",n,"offset_m",offset, ...
    "alpha_negative_np_m",8,"alpha_positive_np_m",35);
opts=struct("GridSpacingM",.001,"SpatialOrder",2, ...
    "MaxGridCells",400000,"MaximumIterations",200, ...
    "ToleranceS",1e-9,"SpeedInterfacePlane",speedPlane, ...
    "AttenuationPlane",lossPlane);
[T,A,d]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
    speed,loss,x,z,src,obsY,opts);
verifyTrue(tc,d.solver.converged);
targets=[.009 0 .008;.011 0 .009];
for j=1:size(targets,1)
    q=targets(j,:);
    [tr,ar]=fermatPlane(src,q,n,offset,2,3,8,35);
    [~,ix]=min(abs(x-q(1)));[~,iz]=min(abs(z-q(3)));
    fprintf("inclined offplane receiver=%d timeError=%.6g opticalError=%.6g\n", ...
        j,abs(T(iz,ix)-tr)/tr,abs(A(iz,ix)-ar)/ar);
    verifyTrue(tc,all(isfinite([tr ar T(iz,ix) A(iz,ix)])));
end
end

function [t,a]=fermatPlane(src,q,n,offset,c1,c2,a1,a2)
% Rotate the plane into normal/tangential coordinates. By translational
% invariance, the minimizing crossing lies along the tangential separation.
v=q-src;
s0=dot(src,n)-offset;
s1=dot(q,n)-offset;
assert(s0<0 && s1>0);
tangent=v-dot(v,n)*n;
D=norm(tangent);
d1=-s0;d2=s1;
fun=@(u) u/(c1*hypot(d1,u))-(D-u)/(c2*hypot(d2,D-u));
if D==0;u=0;else;u=fzero(fun,[0 D]);end
L1=hypot(d1,u);L2=hypot(d2,D-u);
t=L1/c1+L2/c2;
a=a1*L1+a2*L2;
end
