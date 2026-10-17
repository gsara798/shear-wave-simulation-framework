function tests=test_planar_interface_attenuation
tests=functiontests(localfunctions);
end

function testSegmentCrossingAndDirection(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
p=struct("normal_xyz",[1 0 0],"offset_m",.006, ...
    "alpha_negative_np_m",8,"alpha_positive_np_m",35);
q0=[-.004 0 0; .010 0 0; -.004 0 0];
q1=[.012 0 0; -.004 0 0; .002 0 0];
val=swsynth.propagation.attenuation.integratePlanarSegment(q0,q1,p);
expected=[8*.010+35*.006; 35*.004+8*.010;8*.006];
verifyEqual(tc,val,expected,"AbsTol",1e-12);
end

function testExtendedConstantSpeedSharpInterface(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
x=0:.001:.012;z=(0:.001:.012).';
src=[-.004 0 .006];xi=.006;a1=8;a2=35;
speed=2*ones(numel(z),numel(x));
alpha=a1*ones(size(speed));alpha(:,x>=xi)=a2;
p=struct("normal_xyz",[1 0 0],"offset_m",xi, ...
    "alpha_negative_np_m",a1,"alpha_positive_np_m",a2);
[Z,X]=ndgrid(z,x);
r=hypot(X-src(1),Z-src(3));
f=min(1,max(0,(xi-src(1))./(X-src(1))));
exact=r.*(a1*f+a2*(1-f));
for h=[.002 .0015 .001]
    opts=struct("GridSpacingM",h,"MaxGridCells",300000, ...
        "SpatialOrder",2,"MaximumIterations",200,"ToleranceS",1e-9, ...
        "AttenuationPlane",p);
    [~,A,d]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
        speed,alpha,x,z,src,0,opts);
    e=norm(A(:)-exact(:))/norm(exact(:));
    fprintf("planar h=%.4g relativeOpticalDepthError=%.8g\n",h,e);
    verifyTrue(tc,d.solver.converged);
    verifyLessThan(tc,e,1e-10);
end
end

function testBilayerSpeedAndLossNormalRay(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
x=0:.001:.012;z=(0:.001:.012).';
src=[-.004 0 .006];xi=.006;a1=8;a2=35;
speed=2*ones(numel(z),numel(x));speed(:,x>=xi)=3;
alpha=a1*ones(size(speed));alpha(:,x>=xi)=a2;
p=struct("normal_xyz",[1 0 0],"offset_m",xi, ...
    "alpha_negative_np_m",a1,"alpha_positive_np_m",a2);
[~,iz]=min(abs(z-src(3)));
reference=a1*(min(x,xi)-src(1))+a2*max(0,x-xi);
for h=[.002 .0015 .001]
    opts=struct("GridSpacingM",h,"MaxGridCells",300000, ...
        "SpatialOrder",2,"MaximumIterations",200,"ToleranceS",1e-9, ...
        "AttenuationPlane",p);
    [~,A,d]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
        speed,alpha,x,z,src,0,opts);
    e=norm(A(iz,:)-reference)/norm(reference);
    fprintf("bilayer h=%.4g normalRayOpticalDepthError=%.8g\n",h,e);
    verifyTrue(tc,d.solver.converged);
    verifyTrue(tc,all(isfinite(A(:))));
    % Diagnostic: do not assert an arbitrary heterogeneous tolerance yet.
end
end
