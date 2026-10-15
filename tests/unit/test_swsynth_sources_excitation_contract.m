function tests=test_swsynth_sources_excitation_contract
tests=functiontests(localfunctions);
end
function testFixedForceAndComponents(testCase)
r=struct("count",2,"force_policy","fixed", ...
    "force_direction_xyz",[1 0 1], ...
    "relative_amplitude",[.5;2],"phase_rad",[0;pi]);
out=swsynth.sources.excitation.generate(r);
verifyEqual(testCase,out.force_direction_xyz, ...
    repmat([1 0 1]/sqrt(2),2,1),"AbsTol",1e-14);
verifyEqual(testCase,out.relative_amplitude,[.5;2]);
verifyEqual(testCase,out.phase_rad,[0;pi]);
end
function testIndependentRepeatableRandomExcitation(testCase)
r=struct("count",6,"force_policy","random_sphere", ...
    "amplitude_policy","random_normal","amplitude_jitter_fraction",.1, ...
    "phase_policy","random_uniform", ...
    "stream",RandStream("mt19937ar","Seed",12));
a=swsynth.sources.excitation.generate(r);
rng(99);
r.stream=RandStream("mt19937ar","Seed",12);
b=swsynth.sources.excitation.generate(r);
verifyEqual(testCase,a,b);
verifyEqual(testCase,vecnorm(a.force_direction_xyz,2,2), ...
    ones(6,1),"AbsTol",1e-14);
verifyGreaterThanOrEqual(testCase,min(a.relative_amplitude),0);
end
function testRejectNegativeAmplitude(testCase)
r=struct("count",1,"force_direction_xyz",[1 0 0], ...
    "relative_amplitude",-1,"phase_rad",0);
verifyError(testCase,@() swsynth.sources.excitation.generate(r), ...
    "swsynth:InvalidExcitationAmplitude");
end
function testInvalidForce(testCase)
r=struct("count",1,"force_direction_xyz",[0 0 0], ...
    "relative_amplitude",1,"phase_rad",0);
verifyError(testCase,@() swsynth.sources.excitation.generate(r), ...
    "swsynth:InvalidExcitationDirections");
end

function testPlanarXZForces(testCase)
r=struct("geometry","2d","count",3, ...
    "force_policy","fixed", ...
    "force_direction_xz",[1 0;0 1;1 1], ...
    "relative_amplitude",[1;1;2], ...
    "phase_rad",[0;pi;pi/2]);
out=swsynth.sources.excitation.generate(r);
expected=[1 0 0;0 0 1;1/sqrt(2) 0 1/sqrt(2)];
verifyEqual(testCase,out.force_direction_xyz,expected,"AbsTol",1e-14);
verifyEqual(testCase,out.phase_rad,[0;pi;pi/2]);
end

function testPlanarXYZWithYZero(testCase)
r=struct("geometry","planar2d","count",2, ...
    "force_direction_xyz",[1 0 1], ...
    "relative_amplitude",[1;1],"phase_rad",[0;0]);
out=swsynth.sources.excitation.generate(r);
verifyEqual(testCase,out.force_direction_xyz, ...
    repmat([1 0 1]/sqrt(2),2,1),"AbsTol",1e-14);
end

function testPlanarRejectsOutOfPlaneForce(testCase)
r=struct("geometry","2d","count",1, ...
    "force_direction_xyz",[0 1 0]);
verifyError(testCase,@() swsynth.sources.excitation.generate(r), ...
    "swsynth:PlanarForceOutsidePlane");
end

function testPlanarRandomCircleDeterministic(testCase)
r=struct("geometry","2d","count",20, ...
    "force_policy","random_circle", ...
    "phase_policy","random_uniform", ...
    "stream",RandStream("mt19937ar","Seed",53053));
rngBefore=rng;
a=swsynth.sources.excitation.generate(r);
verifyEqual(testCase,rng,rngBefore);
r.stream=RandStream("mt19937ar","Seed",53053);
b=swsynth.sources.excitation.generate(r);
verifyEqual(testCase,a,b);
verifyEqual(testCase,a.force_direction_xyz(:,2),zeros(20,1));
verifyEqual(testCase,vecnorm(a.force_direction_xyz,2,2), ...
    ones(20,1),"AbsTol",1e-14);
end

function test2DRejectsSphereSampling(testCase)
r=struct("geometry","2d","count",3, ...
    "force_policy","random_sphere");
verifyError(testCase,@() swsynth.sources.excitation.generate(r), ...
    "swsynth:ForceSphereRequires3D");
end

function testProjected3DStillAllowsOutOfPlaneForces(testCase)
r=struct("geometry","projected3d","count",1, ...
    "force_direction_xyz",[0 1 0]);
out=swsynth.sources.excitation.generate(r);
verifyEqual(testCase,out.force_direction_xyz,[0 1 0]);
end

function testXZRequires2D(testCase)
r=struct("geometry","volumetric3d","count",1, ...
    "force_direction_xz",[1 0]);
verifyError(testCase,@() swsynth.sources.excitation.generate(r), ...
    "swsynth:ForceXZRequires2D");
end

function testForceVectorInputsUnambiguous(testCase)
r=struct("geometry","2d","count",1, ...
    "force_direction_xz",[1 0], ...
    "force_direction_xyz",[1 0 0]);
verifyError(testCase,@() swsynth.sources.excitation.generate(r), ...
    "swsynth:AmbiguousForceDirection");
end
