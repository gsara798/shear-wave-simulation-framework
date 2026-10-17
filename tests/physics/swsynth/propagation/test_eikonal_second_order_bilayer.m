function tests=test_eikonal_second_order_bilayer
tests=functiontests(localfunctions);
end
function testBilayerNormalIncidenceAndMonotonicSpeed(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
% Layer interface x = 0.006 m; point source outside FOV at x=-0.004.
% Use a central x-axis line where exact Fermat first-arrival travel time
% crosses the interface normally. Non-axis pixels are not compared with
% this 1D formula (refraction gives oblique rays).
x=0:.001:.012;z=(0:.001:.012).';
src=[-.004 0 .006];interface=.006;
c1=2;c2=3;alpha=zeros(numel(z),numel(x));
medium=c1*ones(size(alpha));medium(:,x>=interface)=c2;
[~,iz]=min(abs(z-src(3)));
for order=1:2
    opts=struct("GridSpacingM",.001,"MaxGridCells",300000, ...
        "SpatialOrder",order,"MaximumIterations",200,"ToleranceS",1e-9);
    [t,~,d]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
        medium,alpha,x,z,src,0,opts);
    verifyTrue(tc,d.solver.converged);
    verifyTrue(tc,all(isfinite(t(:))));
    exact=min(x,interface)-src(1);
    exact=exact/c1+max(0,x-interface)/c2;
    measured=t(iz,:);
    relative=norm(measured-exact)/norm(exact);
    fprintf("bilayer order=%d axial relativeL2=%.6g\n",order,relative);
    verifyLessThan(tc,relative,.12, ...
        "Excessive error in the bilayer normal-incidence travel-time benchmark.");
    verifyTrue(tc,all(diff(measured)>-1e-10), ...
        "Arrival time should increase away from the source on axial line.");
end
end
function testHeterogeneityDoesNotBeatEverywhereFastReference(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
x=0:.001:.012;z=(0:.001:.012).';src=[-.004 0 .006];
speed=2*ones(numel(z),numel(x));speed(:,x>=.006)=3;
opts=struct("GridSpacingM",.0015,"MaxGridCells",200000, ...
    "SpatialOrder",2,"MaximumIterations",200,"ToleranceS",1e-9);
[t,~,~]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
    speed,zeros(size(speed)),x,z,src,0,opts);
[tfast,~,~]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
    3*ones(size(speed)),zeros(size(speed)),x,z,src,0,opts);
% No path through a material bounded by c<=3 can arrive earlier than
% Euclidean straight travel at c=3. Check physical lower bound.
verifyGreaterThanOrEqual(tc,t,tfast-3e-4);
end
