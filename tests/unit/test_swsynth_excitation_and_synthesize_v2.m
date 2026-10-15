function tests=test_swsynth_excitation_and_synthesize_v2
tests=functiontests(localfunctions);
end

function testResolveOneSharedHarmonicDrive(testCase)
d=swsynth.excitation.resolve(struct("frequency_hz",500));
verifyEqual(testCase,d.frequency_hz,500);
verifyEqual(testCase,d.omega_rad_s,1000*pi,"AbsTol",1e-12);
verifyEqual(testCase,d.period_s,.002,"AbsTol",1e-14);
verifyEqual(testCase,d.quantity,"relative_motion");
verifyEqual(testCase,d.spatial_phase_sign,1);
end

function testLegacyDriveAdapter(testCase)
legacy=swsynth.defaultConfig3D();
legacy.wavefield.frequency_hz=225;
legacy.wavefield.quantity="velocity";
d=swsynth.excitation.fromLegacy(legacy);
verifyEqual(testCase,d.frequency_hz,225);
verifyEqual(testCase,d.quantity,"velocity");
end

function testDriveRejectsMultipleFrequencies(testCase)
verifyError(testCase,@() swsynth.excitation.resolve( ...
    struct("frequency_hz",[250 500])), ...
    "swsynth:InvalidHarmonicFrequency");
end

function testDriveRejectsUnsupportedQuantity(testCase)
verifyError(testCase,@() swsynth.excitation.resolve( ...
    struct("frequency_hz",500,"quantity","force")), ...
    "swsynth:InvalidHarmonicQuantity");
end

function testPlanarPlaneWaveMatchesIndividualContributions(testCase)
s=planeScenario();
s.incidence.direction_xyz=[1 0 0;0 0 1];
s.incidence.phase_rad=[0;pi/2];
s.propagation.normalization="sqrt_count";
o=swsynth.propagation.synthesize(s);
a=planeComponent(s,[1 0 0],0,1);
b=planeComponent(s,[0 0 1],pi/2,1);
verifyEqual(testCase,o.U_xyz,(a.U_xyz+b.U_xyz)/sqrt(2), ...
    "AbsTol",1e-13);
verifyEqual(testCase,o.field.component_count,2);
verifyEqual(testCase,o.geometry,"2d");
verifyEqual(testCase,o.excitation.frequency_hz,500);
verifyEqual(testCase,o.propagation.normalization,"sqrt_count");
verifyEqual(testCase,o.medium.cs_map_zx,2*ones(3,3));
verifyEqual(testCase,o.domain.spatial_size,[3 3]);
end

function testDefaultPlaneWavePhasesAndAmplitudes(testCase)
s=planeScenario();
s.incidence=rmfield(s.incidence, ...
    ["phase_rad","relative_amplitude"]);
o=swsynth.propagation.synthesize(s);
a=planeComponent(s,[1 0 0],0,1);
verifyEqual(testCase,o.U_xyz,a.U_xyz,"AbsTol",1e-14);
verifyEqual(testCase,o.incidence.phase_rad,0);
verifyEqual(testCase,o.incidence.relative_amplitude,1);
end

function testVolumetricPlaneWaveSynthesis(testCase)
s=planeScenario();
s.geometry="volumetric3d";
s.domain=struct("x_m",[.01 .02], ...
    "y_m",[0 .01 .02],"z_m",[.01 .02]);
s.incidence.direction_xyz=[1 1 0];
s.incidence.polarization=struct( ...
    "policy","transverse_explicit", ...
    "explicit_polarization_xyz",[0 0 1]);
o=swsynth.propagation.synthesize(s);
verifySize(testCase,o.U_xyz,[2 3 2 3]);
verifyEqual(testCase,o.domain.spatial_size,[2 3 2]);
verifyEqual(testCase,o.field.y_m,[0 .01 .02]);
verifyEqual(testCase,o.field.component_count,1);
end

function testProjected3DHomogeneousEikonal(testCase)
s=planeScenario();
s.geometry="projected3d";
s.incidence.direction_xyz=[1 0 0];
s.propagation.phase_method="eikonal";
eik=swsynth.propagation.synthesize(s);
s.propagation.phase_method="analytical";
ana=swsynth.propagation.synthesize(s);
verifyEqual(testCase,eik.U_xyz,ana.U_xyz,"AbsTol",1e-12);
end

function testSphericalSourcesMatchManualComposition(testCase)
s=sphericalScenario();
o=swsynth.propagation.synthesize(s);
bundle=swsynth.sources.prepare(s.sources);
r=struct("source_bundle",bundle,"source_id",1, ...
    "frequency_hz",500, ...
    "phase",struct("method","analytical", ...
        "reference_cs_m_s",2), ...
    "x_m",s.domain.x_m,"z_m",s.domain.z_m);
a=swsynth.propagation.spherical.point_source.computeContribution(r);
r.source_id=2;
b=swsynth.propagation.spherical.point_source.computeContribution(r);
verifyEqual(testCase,o.U_xyz,a.U_xyz+b.U_xyz,"AbsTol",1e-13);
verifyEqual(testCase,o.component_count,2);
verifyEqual(testCase,o.sources.count,2);
verifyEqual(testCase,o.excitation.frequency_hz,500);
end

function testSphericalVolumeDoesNotRequireObservationPlane(testCase)
s=sphericalScenario();
s.geometry="volumetric3d";
s.domain=struct("x_m",[.01 .02], ...
    "y_m",[.005 .015],"z_m",[.01 .02]);
s.sources.positions.position_xyz_m=[0 .03 0;.03 -.03 0];
s.sources.excitation=struct( ...
    "force_direction_xyz",[0 0 1;0 1 0], ...
    "relative_amplitude",[1;1],"phase_rad",[0;pi]);
o=swsynth.propagation.synthesize(s);
verifySize(testCase,o.U_xyz,[2 2 2 3]);
verifyFalse(testCase,isfield(o.domain,"observation_y_m"));
verifyEqual(testCase,o.sources.count,2);
end

function testCoherentApertureInSynthesize(testCase)
s=sphericalScenario();
s.sources.aperture=struct("model","line_segment", ...
    "span_m",.002,"axis_xyz",[1 0 0], ...
    "node_spacing_m",.001);
o=swsynth.propagation.synthesize(s);
verifyEqual(testCase,o.sources.aperture.node_count_per_source,[3;3]);
verifyEqual(testCase,o.field.component_count,2);
verifyEqual(testCase,o.sources.aperture.node_count,6);
end

function testProjectedSphericalWithNonzeroObservationPlane(testCase)
s=sphericalScenario();
s.geometry="projected3d";
s.domain.observation_y_m=.005;
s.sources.positions.position_xyz_m=[0 .03 0;.03 -.03 0];
s.sources.excitation=struct( ...
    "force_direction_xyz",[0 1 0;0 0 1], ...
    "relative_amplitude",[1;1],"phase_rad",[0;pi]);
o=swsynth.propagation.synthesize(s);
verifyEqual(testCase,o.field.observation_y_m,.005);
verifySize(testCase,o.U_xyz,[3 3 3]);
end

function testRejectHeterogeneousSphericalAnalytical(testCase)
s=sphericalScenario();
s.medium.objects={struct("type","circle", ...
    "center_xz_m",[.02 .02],"radius_m",.002, ...
    "cs_m_s",4,"edge_sigma_m",0)};
verifyError(testCase,@() swsynth.propagation.synthesize(s), ...
    "swsynth:SynthesisAnalyticalRequiresHomogeneousMedium");
end

function testRejectHeterogeneousPlanarAnalytical(testCase)
s=planeScenario();
s.medium.objects={struct("type","circle", ...
    "center_xz_m",[.02 .02],"radius_m",.002, ...
    "cs_m_s",4,"edge_sigma_m",0)};
verifyError(testCase,@() swsynth.propagation.synthesize(s), ...
    "swsynth:SynthesisAnalyticalRequiresHomogeneousMedium");
end

function testRejectUnsupportedPlanarEikonal(testCase)
s=planeScenario();
s.propagation.phase_method="eikonal";
verifyError(testCase,@() swsynth.propagation.synthesize(s), ...
    "swsynth:UnsupportedSynthesisPhase");
end

function testRejectUnsupportedSphericalEikonal(testCase)
s=sphericalScenario();
s.propagation.phase_method="eikonal";
verifyError(testCase,@() swsynth.propagation.synthesize(s), ...
    "swsynth:UnsupportedSynthesisPhase");
end

function testRejectDuplicateSourceFrequency(testCase)
s=sphericalScenario();
s.sources.excitation.frequency_hz=500;
verifyError(testCase,@() swsynth.propagation.synthesize(s), ...
    "swsynth:DuplicateSynthesisFrequency");
end

function testRejectSourceGeometryMismatch(testCase)
s=sphericalScenario();
s.sources.geometry="volumetric3d";
verifyError(testCase,@() swsynth.propagation.synthesize(s), ...
    "swsynth:SynthesisGeometryMismatch");
end

function testRejectExtraSourceForPlaneMode(testCase)
s=planeScenario();
s.sources=struct("count",1);
verifyError(testCase,@() swsynth.propagation.synthesize(s), ...
    "swsynth:InvalidSynthesisComponents");
end

function testRejectExtraIncidenceForSourceMode(testCase)
s=sphericalScenario();
s.incidence=struct("direction_xyz",[1 0 0]);
verifyError(testCase,@() swsynth.propagation.synthesize(s), ...
    "swsynth:InvalidSynthesisComponents");
end

function testRejectNonzeroProjectedPlaneObservationY(testCase)
s=planeScenario();
s.geometry="projected3d";
s.domain.observation_y_m=.005;
verifyError(testCase,@() swsynth.propagation.synthesize(s), ...
    "swsynth:ProjectedPlaneWaveRequiresYZero");
end

function testRejectUnsupportedMediumOnSynthesis(testCase)
s=planeScenario();
s.medium.viscosity_pa_s=2;
verifyError(testCase,@() swsynth.propagation.synthesize(s), ...
    "swsynth:UnsupportedMediumProperty");
end

function testRejectMismatchedIncidenceCounts(testCase)
s=planeScenario();
s.incidence.direction_xyz=[1 0 0;0 0 1];
s.incidence.relative_amplitude=[1;2;3];
verifyError(testCase,@() swsynth.propagation.synthesize(s), ...
    "swsynth:InvalidSynthesisIncidence");
end

function testNoUnexpectedRandomnessExplicitIncidence(testCase)
s=planeScenario();
before=rng;
swsynth.propagation.synthesize(s);
verifyEqual(testCase,rng,before);
end

function s=planeScenario()
s=struct();
s.geometry="2d";
s.domain=struct("x_m",[.01 .02 .03], ...
    "z_m",[.01 .02 .03],"observation_y_m",0);
s.medium=struct("cs_m_s",2);
s.excitation=struct("frequency_hz",500);
s.propagation=struct("model","plane_wave", ...
    "phase_method","analytical");
s.incidence=struct("direction_xyz",[1 0 0], ...
    "relative_amplitude",1,"phase_rad",0, ...
    "polarization",struct("policy","in_plane_sv"));
end

function s=sphericalScenario()
s=planeScenario();
s.propagation=struct("model","spherical_wave", ...
    "phase_method","analytical");
s=rmfield(s,"incidence");
src=struct();
src.count=2;
src.positions=struct("method","explicit", ...
    "position_xyz_m",[0 0 0;.04 0 0]);
src.excitation=struct("force_direction_xz",[1 0;0 1], ...
    "relative_amplitude",[1;2],"phase_rad",[0;pi/2]);
s.sources=src;
end

function a=planeComponent(s,direction,phase,amplitude)
req=struct("geometry",s.geometry,"direction_xyz",direction, ...
    "frequency_hz",s.excitation.frequency_hz, ...
    "phase_rad",phase,"amplitude",amplitude, ...
    "phase",struct("method","analytical", ...
        "reference_cs_m_s",2, ...
        "x_m",s.domain.x_m,"z_m",s.domain.z_m), ...
    "polarization",struct("policy","in_plane_sv"));
a=swsynth.propagation.plane_wave.computeContribution(req);
end
