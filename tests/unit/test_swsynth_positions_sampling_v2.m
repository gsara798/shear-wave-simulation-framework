function tests=test_swsynth_positions_sampling_v2
%TEST_SWSYNTH_POSITIONS_SAMPLING_V2 Independent physical source placement.
tests=functiontests(localfunctions);
end

function testPlanarFibonacciPositions(testCase)
r=base("planar2d","fibonacci",8,[.025 .025]);
r.observation_y_m=.004;
r.center_xyz_m=[.02 .004 .03];
p=swsynth.sources.positions.generate(r);
verifySize(testCase,p,[8 3]);
verifyEqual(testCase,p(:,2),.004*ones(8,1));
verifyEqual(testCase,vecnorm(p-r.center_xyz_m,2,2), ...
    .025*ones(8,1),"AbsTol",1e-12);
% Even angular separation around the full circle.
theta=mod(atan2(p(:,3)-.03,p(:,1)-.02),2*pi);
verifyEqual(testCase,diff(sort(theta)),repmat(2*pi/8,7,1), ...
    "AbsTol",1e-12);
end

function testPublic2dAlias(testCase)
r=base("2d","fibonacci",5,[.025 .025]);
p=swsynth.sources.positions.generate(r);
verifyEqual(testCase,p(:,2),zeros(5,1));
end

function testProjectedFibonacciIsDeterministicSphere(testCase)
r=base("projected3d","fibonacci",21,[.025 .025]);
a=swsynth.sources.positions.generate(r);
rng(773);
b=swsynth.sources.positions.generate(r);
verifyEqual(testCase,a,b);
verifyEqual(testCase,vecnorm(a,2,2),.025*ones(21,1), ...
    "AbsTol",1e-12);
verifyGreaterThan(testCase,max(abs(a(:,2))),0);
end

function testVolumetricFibonacciRadialRange(testCase)
r=base("volumetric3d","fibonacci",5,[.02 .03]);
p=swsynth.sources.positions.generate(r);
u=((0:4)'+.5)/5;
expected=(.02^3+(.03^3-.02^3)*u).^(1/3);
verifyEqual(testCase,vecnorm(p,2,2),expected,"AbsTol",1e-12);
end

function testSame3DPositionsForSameSeedAcrossObservations(testCase)
r=base("projected3d","random",18,[.02 .03]);
r.stream=RandStream("mt19937ar","Seed",53053);
projected=swsynth.sources.positions.generate(r);
r.geometry="volumetric3d";
r.stream=RandStream("mt19937ar","Seed",53053);
volumetric=swsynth.sources.positions.generate(r);
verifyEqual(testCase,projected,volumetric);
end

function testRandomIndependentOfGlobalStream(testCase)
r=base("projected3d","random",10,[.02 .03]);
r.stream=RandStream("mt19937ar","Seed",23);
before=rng;
a=swsynth.sources.positions.generate(r);
after=rng;
verifyEqual(testCase,after,before);
r.stream=RandStream("mt19937ar","Seed",23);
b=swsynth.sources.positions.generate(r);
verifyEqual(testCase,a,b);
verifyGreaterThanOrEqual(testCase,min(vecnorm(a,2,2)),.02-1e-12);
verifyLessThanOrEqual(testCase,max(vecnorm(a,2,2)),.03+1e-12);
end

function testConePositioning3D(testCase)
r=base("projected3d","fibonacci",30,[.025 .025]);
r.support=struct("type","cone","axis_xyz",[1 0 0], ...
    "half_angle_deg",20);
p=swsynth.sources.positions.generate(r);
angle=acosd(max(-1,min(1,p(:,1)./vecnorm(p,2,2))));
verifyLessThanOrEqual(testCase,max(angle),20+1e-9);
end

function testConePositioningPlanar(testCase)
r=base("planar2d","fibonacci",16,[.025 .025]);
r.support=struct("type","cone","axis_xyz",[0 0 1], ...
    "half_angle_deg",30);
p=swsynth.sources.positions.generate(r);
angle=atan2(p(:,1),p(:,3));
verifyLessThanOrEqual(testCase,max(abs(rad2deg(angle))),30+1e-9);
verifyEqual(testCase,p(:,2),zeros(16,1));
end

function testExplicitCoordinatesAreExact(testCase)
r=struct("geometry","projected3d","method","explicit", ...
    "count",2,"position_xyz_m",[.01 -.02 .04;.02 .03 -.01]);
p=swsynth.sources.positions.generate(r);
verifyEqual(testCase,p,r.position_xyz_m);
end

function testRejectAmbiguousPositioning(testCase)
r=base("projected3d","random",3,[.02 .03]);
r.position_xyz_m=zeros(3,3);
verifyError(testCase,@() swsynth.sources.positions.generate(r), ...
    "swsynth:AmbiguousSourcePositions");
end

function testPlanarCenterMustBeInPlane(testCase)
r=base("planar2d","fibonacci",5,[.02 .02]);
r.center_xyz_m=[0 .01 0];
verifyError(testCase,@() swsynth.sources.positions.generate(r), ...
    "swsynth:PlanarSourceOutsidePlane");
end

function testInvalidGeometrySupport(testCase)
r=base("planar2d","random",5,[.02 .02]);
r.support=struct("type","full_sphere");
verifyError(testCase,@() swsynth.sources.positions.generate(r), ...
    "swsynth:InvalidPositionSupport");
end

function request=base(geometry,method,n,radial)
request=struct("geometry",geometry,"method",method,"count",n, ...
    "center_xyz_m",[0 0 0],"radius_range_m",radial);
end
