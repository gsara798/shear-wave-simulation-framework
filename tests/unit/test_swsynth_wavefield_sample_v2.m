function tests=test_swsynth_wavefield_sample_v2
tests=functiontests(localfunctions);
end

function testPlanarDirectionalSamplePassesSharedValidator(testCase)
s=planeScenario();
result=swsynth.propagation.synthesize(s);
sample=swsynth.io.buildWavefieldSampleV2(result,s, ...
    struct("scenario_name","v2_plane","seed",53053, ...
           "commit","testcommit"));
info=wavefield.validateSample(sample);
verifyEqual(testCase,info.spatial_dimension,2);
verifyEqual(testCase,sample.schema_version,"1.0");
verifyEqual(testCase,sample.schema_name,"wavefield_sample");
verifyEqual(testCase,sample.generator.backend,"fast_synthetic_v2");
verifyEqual(testCase,sample.generator.commit,"testcommit");
verifyEqual(testCase,sample.seed,53053);
verifyEqual(testCase,sample.scenario,"v2_plane");
verifyEqual(testCase,sample.wavefield.quantity,"relative_motion");
verifyEqual(testCase,sample.wavefield.units,"arbitrary_relative_motion");
verifyEqual(testCase,sample.wavefield.component,"z");
verifyEqual(testCase,sample.coordinates.array_order,"zx");
verifyEqual(testCase,sample.measurement.axis_xyz,[0 0 1]);
verifyEqual(testCase,sample.wavefield.data_zx, ...
    swsynth.observation.projectComponent(result.U_xyz,[0 0 1]), ...
    "AbsTol",1e-14);
verifyEqual(testCase,sample.truth.cs_map_zx, ...
    2*ones(result.domain.spatial_size));
verifyEqual(testCase,sample.truth.k_map_zx, ...
    500*pi*ones(result.domain.spatial_size),"AbsTol",1e-12);
verifyEqual(testCase,sample.directions.xyz,[1 0 0]);
verifyEqual(testCase,sample.validation.scope, ...
    "schema_and_finite_phasor_only");
verifyFalse(testCase,sample.validation.physics_validated);
end

function testSphericalProjectedSampleRetainsPhysicalSources(testCase)
s=sphericalScenario();
result=swsynth.propagation.synthesize(s);
sample=swsynth.io.buildWavefieldSampleV2(result,s);
info=wavefield.validateSample(sample);
verifyEqual(testCase,info.spatial_dimension,2);
verifyEqual(testCase,sample.coordinates.observation_y_m,.005);
verifyEqual(testCase,sample.propagation.model,"spherical_wave");
verifyEqual(testCase,sample.propagation.phase_model,"analytical");
verifyEqual(testCase,sample.sources.count,2);
verifyEqual(testCase,sample.directions.retained_count,0);
verifyEqual(testCase,sample.directions.interpretation, ...
    "not_applicable_to_point_sources");
verifyEqual(testCase,sample.excitation.phase_rad,[0;pi]);
verifyEqual(testCase,sample.excitation.force_direction_xyz, ...
    [0 0 1;0 0 1]);
verifyEqual(testCase,sample.provenance.resolved_config,s);
verifyEqual(testCase,sample.truth.material_id_zx, ...
    zeros(result.domain.spatial_size,"uint16"));
verifyEmpty(testCase,sample.seed);
end

function testVolumetricV2SampleUsesZyxTruthAndWavefield(testCase)
s=planeScenario();
s.geometry="volumetric3d";
s.domain=struct("x_m",[.01 .02 .03], ...
    "y_m",[0 .005 .01], ...
    "z_m",[.01 .02 .03]);
s.incidence.polarization=struct("policy","transverse_explicit", ...
    "explicit_polarization_xyz",[0 0 1]);
result=swsynth.propagation.synthesize(s);
sample=swsynth.io.buildWavefieldSampleV2(result,s);
info=wavefield.validateSample(sample);
verifyEqual(testCase,info.spatial_dimension,3);
verifySize(testCase,sample.wavefield.data_zyx,[3 3 3]);
verifySize(testCase,sample.truth.cs_map_zyx,[3 3 3]);
verifyEqual(testCase,sample.truth.k_map_zyx, ...
    (500*pi)*ones(3,3,3),"AbsTol",1e-12);
verifyTrue(testCase,all(sample.truth.valid_mask_zyx(:)));
verifyFalse(testCase,isfield(sample.coordinates,"observation_y_m"));
verifyEqual(testCase,sample.coordinates.array_order,"zyx");
end

function testHeterogeneousProjectedEikonalTruthIsLocalMaterialK(testCase)
s=planeScenario();
s.geometry="projected3d";
s.domain=struct("x_m",(0:8)*.001, ...
    "z_m",(0:8)*.001,"observation_y_m",0);
s.medium.objects={struct("type","circle", ...
    "center_xz_m",[.004 .004], ...
    "radius_m",.002,"cs_m_s",4)};
s.propagation.phase_method="eikonal";
result=swsynth.propagation.synthesize(s);
sample=swsynth.io.buildWavefieldSampleV2(result,s);
wavefield.validateSample(sample);
verifyEqual(testCase,sample.truth.cs_map_zx(5,5),4);
verifyEqual(testCase,sample.truth.k_map_zx(5,5),250*pi, ...
    "AbsTol",1e-12);
verifyEqual(testCase,sample.truth.k_map_zx(1,1),500*pi, ...
    "AbsTol",1e-12);
verifyFalse(testCase,sample.propagation.k_map_is_eikonal_phase_gradient);
verifyEqual(testCase,sample.medium.objects,s.medium.objects);
end

function testNonAxialMeasurementIsExplicitProjection(testCase)
s=planeScenario();
s.incidence.polarization=struct("policy","transverse_explicit", ...
    "explicit_polarization_xyz",[0 0 1]);
result=swsynth.propagation.synthesize(s);
sample=swsynth.io.buildWavefieldSampleV2(result,s, ...
    struct("measurement_axis_xyz",[0 0 2]));
verifyEqual(testCase,sample.measurement.axis_xyz,[0 0 1]);
verifyEqual(testCase,sample.wavefield.component,"z");
verifyEqual(testCase,sample.wavefield.data_zx, ...
    swsynth.observation.projectComponent(result.U_xyz,[0 0 1]), ...
    "AbsTol",1e-14);

other=swsynth.io.buildWavefieldSampleV2(result,s, ...
    struct("measurement_axis_xyz",[1 0 0]));
verifyEqual(testCase,other.wavefield.component,"projected");
verifyEqual(testCase,other.measurement.axis_xyz,[1 0 0]);
verifyFalse(testCase,other.validation.analysis_ready);
end

function testDeclaredVelocityDoesNotPretendCalibratedAmplitude(testCase)
s=planeScenario();
s.harmonic.quantity="velocity";
result=swsynth.propagation.synthesize(s);
sample=swsynth.io.buildWavefieldSampleV2(result,s);
verifyEqual(testCase,sample.wavefield.quantity,"velocity");
verifyEqual(testCase,sample.wavefield.units,"arbitrary_velocity");
verifyFalse(testCase,sample.measurement.calibrated);
end

function testSavedMatFilePreservesSharedSchema(testCase)
s=planeScenario();
r=swsynth.propagation.synthesize(s);
wavefield_sample=swsynth.io.buildWavefieldSampleV2(r,s); %#ok<NASGU>
path=[tempname,'.mat'];
cleanup=onCleanup(@() deleteIfExists(path));
save(path,"wavefield_sample","-v7.3");
loaded=load(path,"wavefield_sample");
info=wavefield.validateSample(loaded.wavefield_sample);
verifyEqual(testCase,info.spatial_dimension,2);
verifyEqual(testCase,loaded.wavefield_sample.wavefield.frequency_hz,500);
clear cleanup
end

function deleteIfExists(path)
if isfile(path)
    delete(path);
end
end

function testRejectScenarioFrequencyMismatch(testCase)
s=planeScenario();
r=swsynth.propagation.synthesize(s);
s.harmonic.frequency_hz=400;
verifyError(testCase, ...
    @() swsynth.io.buildWavefieldSampleV2(r,s), ...
    "swsynth:V2SampleScenarioMismatch");
end

function testRejectScenarioGeometryMismatch(testCase)
s=planeScenario();
r=swsynth.propagation.synthesize(s);
s.geometry="volumetric3d";
verifyError(testCase, ...
    @() swsynth.io.buildWavefieldSampleV2(r,s), ...
    "swsynth:V2SampleScenarioMismatch");
end

function testRejectInvalidObservationAxis(testCase)
s=planeScenario();
r=swsynth.propagation.synthesize(s);
verifyError(testCase, ...
    @() swsynth.io.buildWavefieldSampleV2(r,s, ...
        struct("measurement_axis_xyz",[0 0 0])), ...
    "swsynth:InvalidV2SampleMeasurement");
end

function testNoImplicitRandomSeedOrTimestamp(testCase)
s=planeScenario();
r=swsynth.propagation.synthesize(s);
sample=swsynth.io.buildWavefieldSampleV2(r,s);
verifyEmpty(testCase,sample.seed);
verifyEqual(testCase,sample.generator.commit,"");
verifyEqual(testCase,sample.provenance.created_utc,"");
verifyTrue(testCase,sample.validation.valid);
end

function testNoGlobalRngConsumption(testCase)
s=planeScenario();
r=swsynth.propagation.synthesize(s);
before=rng;
swsynth.io.buildWavefieldSampleV2(r,s);
verifyEqual(testCase,rng,before);
end

function s=planeScenario()
s=struct();
s.geometry="2d";
s.domain=struct("x_m",[.01 .02 .03], ...
    "z_m",[.01 .02 .03],"observation_y_m",0);
s.medium=struct("cs_m_s",2);
s.harmonic=struct("frequency_hz",500);
s.propagation=struct("model","plane_wave", ...
    "phase_method","analytical");
s.incidence=struct("direction_xyz",[1 0 0], ...
    "relative_amplitude",1,"phase_rad",0, ...
    "polarization",struct("policy","in_plane_sv"));
end

function s=sphericalScenario()
s=planeScenario();
s.geometry="projected3d";
s.domain.observation_y_m=.005;
s.propagation=struct("model","spherical_wave", ...
    "phase_method","analytical");
s=rmfield(s,"incidence");
s.sources=struct("count",2, ...
    "positions",struct("method","explicit", ...
        "position_xyz_m",[0 .02 0;.04 -.02 0]), ...
    "excitation",struct( ...
        "force_direction_xyz",[0 0 1;0 0 1], ...
        "relative_amplitude",[1;1],"phase_rad",[0;pi]));
end
