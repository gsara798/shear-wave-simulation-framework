function tests=test_swsynth_plane_wave_contribution_v2
tests=functiontests(localfunctions);
end

function testPlanarAnalyticalVectorPhasor(testCase)
req=fixture2D();
req.frequency_hz=500;
req.amplitude=2;
req.phase_rad=pi/3;
out=swsynth.propagation.plane_wave.computeContribution(req);
[X,~]=meshgrid(req.phase.x_m,req.phase.z_m);
expectedScalar=2*exp(1i*(2*pi*500*X/2+pi/3));
verifySize(testCase,out.U_xyz,[2 3 3]);
verifyEqual(testCase,out.U_xyz(:,:,3),expectedScalar, ...
    "AbsTol",2e-14);
verifyEqual(testCase,out.U_xyz(:,:,1:2),zeros(2,3,2));
verifyEqual(testCase,out.scalar_phasor,expectedScalar, ...
    "AbsTol",2e-14);
verifyEqual(testCase,out.output_convention, ...
    "U(z,x,component_xyz)");
verifyEqual(testCase,out.phase_sign,1);
end

function testPlanarAliasAndZeroAmplitude(testCase)
req=fixture2D();
req.geometry="planar2d";
req.amplitude=0;
out=swsynth.propagation.plane_wave.computeContribution(req);
verifyEqual(testCase,out.geometry,"2d");
verifyEqual(testCase,out.U_xyz,complex(zeros(2,3,3)));
verifyEqual(testCase,out.scalar_phasor,complex(zeros(2,3)));
end

function testVolumetricZeroAmplitudePreservesComplexOutput(testCase)
req=fixture2D();
req.geometry="volumetric3d";
req.phase.y_m=[0 .001];
req.amplitude=0;
out=swsynth.propagation.plane_wave.computeContribution(req);
verifyEqual(testCase,out.scalar_phasor,complex(zeros(2,2,3)));
verifyEqual(testCase,out.U_xyz,complex(zeros(2,2,3,3)));
end

function testProjected3DAnalyticalObliqueIncidence(testCase)
req=fixture2D();
req.geometry="projected3d";
req.direction_xyz=[1 1 0];
req.polarization=struct("policy","transverse_explicit", ...
    "explicit_polarization_xyz",[0 0 1]);
req.phase_rad=0;
out=swsynth.propagation.plane_wave.computeContribution(req);
[X,~]=meshgrid(req.phase.x_m,req.phase.z_m);
expected=exp(1i*2*pi*req.frequency_hz.*X/(2*sqrt(2)));
verifyEqual(testCase,out.U_xyz(:,:,3),expected,"AbsTol",1e-14);
verifyEqual(testCase,out.U_xyz(:,:,1:2),zeros(2,3,2));
verifySize(testCase,out.travel_time_s,[2 3]);
end

function testVolumetricAnalyticalAndSensorProjection(testCase)
req=fixture2D();
req.geometry="volumetric3d";
req.phase.y_m=[0 .003];
req.direction_xyz=[1 1 0];
req.polarization=struct("policy","transverse_explicit", ...
    "explicit_polarization_xyz",[0 0 1]);
req.amplitude=0.7;
out=swsynth.propagation.plane_wave.computeContribution(req);
[Z,Y,X]=ndgrid(req.phase.z_m,req.phase.y_m,req.phase.x_m); %#ok<ASGLU>
expected=0.7*exp(1i*2*pi*req.frequency_hz* ...
    (X+Y)/(sqrt(2)*req.phase.reference_cs_m_s));
verifySize(testCase,out.U_xyz,[2 2 3 3]);
verifyEqual(testCase,out.U_xyz(:,:,:,3),expected, ...
    "AbsTol",1e-14);
observed=swsynth.observation.projectComponent(out.U_xyz,[0 0 1]);
verifyEqual(testCase,observed,expected,"AbsTol",1e-14);
verifyEqual(testCase,out.output_convention, ...
    "U(z,y,x,component_xyz)");
end

function testVolumetricEikonalHomogeneousMatchesAnalytic(testCase)
req=fixture2D();
req.geometry="volumetric3d";
req.direction_xyz=[1 0 0];
req.phase.y_m=[0 .001];
req.phase.method="eikonal";
req.phase.cs_map_zyx=2*ones(2,2,3);
eik=swsynth.propagation.plane_wave.computeContribution(req);
req.phase.method="analytical";
ana=swsynth.propagation.plane_wave.computeContribution(req);
verifyEqual(testCase,eik.U_xyz,ana.U_xyz,"AbsTol",1e-12);
end

function testProjectedEikonalHomogeneousMatchesAnalytic(testCase)
req=fixture2D();
req.geometry="projected3d";
req.direction_xyz=[1 0 0];
req.phase.method="eikonal";
req.phase.cs_map_zx=2*ones(2,3);
eik=swsynth.propagation.plane_wave.computeContribution(req);
req.phase.method="analytical";
ana=swsynth.propagation.plane_wave.computeContribution(req);
verifyEqual(testCase,eik.U_xyz,ana.U_xyz,"AbsTol",1e-12);
end

function testDifferentPhasesGiveCoherentSign(testCase)
req=fixture2D();
a=swsynth.propagation.plane_wave.computeContribution(req);
req.phase_rad=pi;
b=swsynth.propagation.plane_wave.computeContribution(req);
verifyEqual(testCase,b.U_xyz,-a.U_xyz,"AbsTol",1e-14);
end

function testNoRandomnessForExplicitPolarization(testCase)
req=fixture2D();
state=rng;
swsynth.propagation.plane_wave.computeContribution(req);
verifyEqual(testCase,rng,state);
end

function testRandomPolarizationUsesExplicitStream(testCase)
req=fixture2D();
req.geometry="volumetric3d";
req.direction_xyz=[1 0 0];
req.phase.y_m=[0 .001];
req.polarization=struct("policy","transverse_random", ...
    "stream",RandStream("mt19937ar","Seed",53053));
state=rng;
a=swsynth.propagation.plane_wave.computeContribution(req);
verifyEqual(testCase,rng,state);
req.polarization.stream=RandStream("mt19937ar","Seed",53053);
b=swsynth.propagation.plane_wave.computeContribution(req);
verifyEqual(testCase,a.U_xyz,b.U_xyz);
verifyEqual(testCase,a.polarization_xyz,b.polarization_xyz);
end

function testRejectIncompatibleDirections(testCase)
req=fixture2D();
req.polarization.direction_xyz=[0 0 1];
verifyError(testCase, ...
    @() swsynth.propagation.plane_wave.computeContribution(req), ...
    "swsynth:PlaneContributionDirectionMismatch");
end

function testRejectIncompatibleGeometry(testCase)
req=fixture2D();
req.phase.geometry="volumetric3d";
verifyError(testCase, ...
    @() swsynth.propagation.plane_wave.computeContribution(req), ...
    "swsynth:PlaneContributionGeometryMismatch");
end

function testRejectNegativeAmplitude(testCase)
req=fixture2D();
req.amplitude=-1;
verifyError(testCase, ...
    @() swsynth.propagation.plane_wave.computeContribution(req), ...
    "swsynth:InvalidPlaneContributionAmplitude");
end

function testRejectOutOfPlaneDirection2D(testCase)
req=fixture2D();
req.direction_xyz=[0 1 0];
verifyError(testCase, ...
    @() swsynth.propagation.plane_wave.computeContribution(req), ...
    "swsynth:InvalidPlaneContributionDirection");
end

function testRejectNonTransversePolarization(testCase)
req=fixture2D();
req.polarization.explicit_polarization_xyz=[1 0 0];
verifyError(testCase, ...
    @() swsynth.propagation.plane_wave.computeContribution(req), ...
    "swsynth:NonTransversePolarization");
end

function testRejectNonmonotonicGrid(testCase)
req=fixture2D();
req.phase.x_m=[0 .001 .0005];
verifyError(testCase, ...
    @() swsynth.propagation.plane_wave.computeContribution(req), ...
    "swsynth:InvalidPlaneContributionGrid");
end

function testRejectUnsupportedPlanarEikonal(testCase)
req=fixture2D();
req.phase.method="eikonal";
verifyError(testCase, ...
    @() swsynth.propagation.plane_wave.computeContribution(req), ...
    "swsynth:PhaseRoutingUnsupported");
end

function req=fixture2D()
req=struct();
req.geometry="2d";
req.direction_xyz=[1 0 0];
req.frequency_hz=400;
req.amplitude=1;
req.phase_rad=0;
req.phase=struct("method","analytical", ...
    "reference_cs_m_s",2,"x_m",[0 .001 .002], ...
    "z_m",[0 .001]);
req.polarization=struct("policy","transverse_explicit", ...
    "explicit_polarization_xyz",[0 0 1]);
end
