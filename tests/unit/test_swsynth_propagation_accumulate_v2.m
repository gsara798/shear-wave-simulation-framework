function tests=test_swsynth_propagation_accumulate_v2
tests=functiontests(localfunctions);
end

function testConstructiveInterference2D(testCase)
request=fixture();
a=component(request,0,1);
b=component(request,0,1);
out=swsynth.propagation.accumulate({a,b});
verifyEqual(testCase,out.U_xyz,2*a.U_xyz,"AbsTol",1e-14);
verifyEqual(testCase,out.component_count,2);
verifyEqual(testCase,out.normalization,"none");
verifyEqual(testCase,out.normalization_factor,1);
verifyEqual(testCase,out.frequency_hz,500);
verifyEqual(testCase,out.x_m,request.phase.x_m);
verifyEqual(testCase,out.z_m,request.phase.z_m);
verifyEqual(testCase,out.output_convention,"U(z,x,component_xyz)");
end

function testDestructiveInterference2D(testCase)
request=fixture();
a=component(request,0,1);
b=component(request,pi,1);
out=swsynth.propagation.accumulate({a,b});
verifyLessThan(testCase,max(abs(out.U_xyz(:))),1e-14);
verifySize(testCase,out.U_xyz,[3 4 3]);
verifyFalse(testCase,isreal(out.U_xyz));
end

function testExplicitSqrtCountNormalization(testCase)
request=fixture();
a=component(request,0,1);
b=component(request,0,1);
out=swsynth.propagation.accumulate([a,b], ...
    struct("normalization","sqrt_count"));
verifyEqual(testCase,out.U_xyz,sqrt(2)*a.U_xyz, ...
    "AbsTol",1e-14);
verifyEqual(testCase,out.normalization_factor,1/sqrt(2));
verifyEqual(testCase,out.normalization,"sqrt_count");
end

function testSingleWavePassThrough(testCase)
a=component(fixture(),0,.75);
out=swsynth.propagation.accumulate(a, ...
    struct("normalization","sqrt_count"));
verifyEqual(testCase,out.U_xyz,a.U_xyz);
verifyEqual(testCase,out.component_count,1);
end

function testZeroAmplitudeRemainsComplex(testCase)
request=fixture();
a=component(request,0,0);
b=component(request,pi,0);
out=swsynth.propagation.accumulate({a,b});
verifyEqual(testCase,out.U_xyz,complex(zeros(3,4,3)));
verifyFalse(testCase,isreal(out.U_xyz));
end

function testVolumetricCoherentSum(testCase)
request=fixture();
request.geometry="volumetric3d";
request.phase.y_m=[0 .001 .002];
a=component(request,0,1);
b=component(request,pi/2,1);
out=swsynth.propagation.accumulate({a,b});
verifySize(testCase,out.U_xyz,[3 3 4 3]);
verifyEqual(testCase,out.U_xyz,a.U_xyz+b.U_xyz, ...
    "AbsTol",1e-14);
verifyEqual(testCase,out.y_m,request.phase.y_m);
verifyEqual(testCase,out.output_convention,"U(z,y,x,component_xyz)");
observed=swsynth.observation.projectComponent(out.U_xyz,[0 0 1]);
verifyEqual(testCase,observed,out.U_xyz(:,:,:,3),"AbsTol",1e-14);
end

function testProjected3DCoherentSum(testCase)
request=fixture();
request.geometry="projected3d";
request.direction_xyz=[1 1 0];
a=component(request,0,1);
b=component(request,pi/2,.5);
out=swsynth.propagation.accumulate({a,b});
verifyEqual(testCase,out.U_xyz,a.U_xyz+b.U_xyz, ...
    "AbsTol",1e-14);
verifyEqual(testCase,out.geometry,"projected3d");
verifySize(testCase,out.U_xyz,[3 4 3]);
end

function testDifferentPolarizationsStayVectorial(testCase)
request=fixture();
request.polarization.explicit_polarization_xyz=[0 1 0];
request.geometry="projected3d";
% In projected3d, Y polarization is allowed for X incidence.
a=component(request,0,1);
request.polarization.explicit_polarization_xyz=[0 0 1];
b=component(request,0,1);
out=swsynth.propagation.accumulate({a,b});
verifyEqual(testCase,out.U_xyz(:,:,2),a.U_xyz(:,:,2), ...
    "AbsTol",1e-14);
verifyEqual(testCase,out.U_xyz(:,:,3),b.U_xyz(:,:,3), ...
    "AbsTol",1e-14);
end

function testRejectSameSizedButDisplacedGrids(testCase)
a=component(fixture(),0,1);
b=a;
b.x_m=b.x_m+.01;
verifyError(testCase,@() swsynth.propagation.accumulate({a,b}), ...
    "swsynth:WaveContributionGridMismatch");
end

function testRejectFrequencyMismatch(testCase)
a=component(fixture(),0,1);
b=a;b.frequency_hz=700;
verifyError(testCase,@() swsynth.propagation.accumulate({a,b}), ...
    "swsynth:WaveContributionFrequencyMismatch");
end

function testRejectGeometryMismatch(testCase)
a=component(fixture(),0,1);
request=fixture();request.geometry="projected3d";
b=component(request,0,1);
verifyError(testCase,@() swsynth.propagation.accumulate({a,b}), ...
    "swsynth:WaveContributionGeometryMismatch");
end

function testRejectPhaseSignMismatch(testCase)
a=component(fixture(),0,1);
b=a;b.phase_sign=-1;
verifyError(testCase,@() swsynth.propagation.accumulate({a,b}), ...
    "swsynth:WaveContributionPhaseConventionMismatch");
end

function testRejectDifferentFieldSize(testCase)
a=component(fixture(),0,1);
b=a;
b.U_xyz=b.U_xyz(1:2,:,:);
verifyError(testCase,@() swsynth.propagation.accumulate({a,b}), ...
    "swsynth:InvalidWaveContributionField");
end

function testRejectUnsupportedNormalization(testCase)
a=component(fixture(),0,1);
verifyError(testCase, ...
    @() swsynth.propagation.accumulate(a, ...
    struct("normalization","auto")), ...
    "swsynth:InvalidWaveNormalization");
end

function testRejectEmptyContributions(testCase)
verifyError(testCase, ...
    @() swsynth.propagation.accumulate({}), ...
    "swsynth:EmptyWaveContributions");
end

function testRejectInvalidEntry(testCase)
a=component(fixture(),0,1);
verifyError(testCase, ...
    @() swsynth.propagation.accumulate({a,42}), ...
    "swsynth:InvalidWaveContribution");
end

function testNoRandomStateConsumed(testCase)
request=fixture();
a=component(request,0,1);
b=component(request,pi,1);
rngBefore=rng;
swsynth.propagation.accumulate({a,b});
verifyEqual(testCase,rng,rngBefore);
end

function a=component(request,phase,amplitude)
request.phase_rad=phase;
request.amplitude=amplitude;
a=swsynth.propagation.plane_wave.computeContribution(request);
end

function request=fixture()
request=struct();
request.geometry="2d";
request.direction_xyz=[1 0 0];
request.frequency_hz=500;
request.phase=struct("method","analytical", ...
    "reference_cs_m_s",2, ...
    "x_m",[0 .001 .002 .003], ...
    "z_m",[0 .001 .002]);
request.polarization=struct("policy","transverse_explicit", ...
    "explicit_polarization_xyz",[0 0 1]);
end
