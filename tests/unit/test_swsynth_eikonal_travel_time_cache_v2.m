function tests=test_swsynth_eikonal_travel_time_cache_v2
tests=functiontests(localfunctions);
end

function setupOnce(tc)
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
end

function testCacheMissHitAndPhysicsRejection(tc)
% Small, lossless off-plane inclusion; same travel time, any harmonic f.
x=0:.0004:.012;z=x';
[X,Z]=meshgrid(x,z);
speed=2*ones(size(X));
speed((X-.006).^2+(Z-.006).^2<=.0025^2)=3;
src=[-.004,-.003,.006];obsY=0;
opts=struct("GridSpacingM",.001,"MaxGridCells",100000, ...
    "MaximumIterations",150,"ToleranceS",1e-9);
dir=string(tempname);clean=onCleanup(@()cleanup(dir));
R=struct("directory",dir,"source_id",1, ...
    "x_m",x,"z_m",z,"speed_zx",speed);
[T1,loss1,d1]= ...
    swsynth.propagation.spherical.point_source.eikonal.cachedTravelTime( ...
    speed,zeros(size(speed)),x,z,src,obsY,opts,R);
verifyEqual(tc,string(d1.cache_status),"miss");
verifyTrue(tc,isfile(fullfile(dir,"source_001.mat")));
[T2,loss2,d2]= ...
    swsynth.propagation.spherical.point_source.eikonal.cachedTravelTime( ...
    speed,zeros(size(speed)),x,z,src,obsY,opts,R);
verifyEqual(tc,string(d2.cache_status),"hit");
verifyEqual(tc,T1,T2,"AbsTol",0);
verifyEqual(tc,loss1,loss2);
[T0,~,~]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
    speed,zeros(size(speed)),x,z,src,obsY,opts);
verifyEqual(tc,T1,T0,"AbsTol",1e-12);
% Sample at another observation resolution from identical physics.
xc=0:.0008:.012;zc=xc';
[Tc,~,dc]= ...
    swsynth.propagation.spherical.point_source.eikonal.cachedTravelTime( ...
    speed,zeros(size(speed)),xc,zc,src,obsY,opts,R);
verifyEqual(tc,string(dc.cache_status),"hit");
verifyEqual(tc,Tc,T1(1:2:end,1:2:end),"AbsTol",1e-12);
% A changed source/material can NEVER silently hit an old cache.
R.speed_zx(15,15)=R.speed_zx(15,15)+.5;
verifyError(tc,@() ...
    swsynth.propagation.spherical.point_source.eikonal.cachedTravelTime( ...
    speed,zeros(size(speed)),x,z,src,obsY,opts,R), ...
    "swsynth:EikonalCacheMismatch");
end

function cleanup(dir)
if isfolder(dir),rmdir(dir,"s");end
end
