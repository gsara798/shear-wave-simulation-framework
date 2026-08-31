function tests = test_swsynth_volumetric_eikonal_3d
%TEST_SWSYNTH_VOLUMETRIC_EIKONAL_3D End-to-end volumetric Eikonal tests.

tests = functiontests(localfunctions);

end

function testHomogeneousLimitMatchesAnalyticalPlaneWave(testCase)

cfg = compactConfig();
cfg.directions.count = 5;
cfg.directions.sampling_method = "fibonacci";
cfg.polarization.model = "transverse_preferred";
cfg.sources.amplitude_jitter_fraction = 0;

analyticCfg = cfg;
analyticCfg.propagation.model = "plane_wave";
analyticCfg.propagation.phase_model = "homogeneous_analytic";
analytic = swsynth.run3D(analyticCfg);

eikonalCfg = cfg;
eikonalCfg.propagation.model = "plane_wave";
eikonalCfg.propagation.phase_model = "volumetric_eikonal";
eikonal = swsynth.run3D(eikonalCfg);

relativeError = norm( ...
    analytic.wavefield.U_zyx(:) - eikonal.wavefield.U_zyx(:)) / ...
    max(norm(analytic.wavefield.U_zyx(:)), eps);

verifyLessThan(testCase, relativeError, 1e-5);
verifyEqual(testCase, eikonal.sample.propagation.model, "plane_wave");
verifyEqual(testCase, eikonal.sample.propagation.phase_model, "volumetric_eikonal");
verifyEqual(testCase, eikonal.sample.spatial_dimension, 3);
verifyEqual(testCase, eikonal.sample.coordinates.array_order, "zyx");

end

function testSphereHeterogeneityProducesValidVolumetricSample(testCase)

cfg = compactConfig();
cfg.propagation.model = "plane_wave";
cfg.propagation.phase_model = "volumetric_eikonal";
cfg.directions.count = 1;
cfg.directions.sampling_method = "explicit";
cfg.directions.explicit_xyz = [1 0 0];
cfg.polarization.model = "transverse_preferred";
cfg.sources.amplitude_jitter_fraction = 0;

sphere = struct();
sphere.type = "sphere";
sphere.cs_m_s = 3.0;
sphere.center_xyz_m = [0.003 0.003 0.003];
sphere.radius_m = 0.0015;
cfg.medium.objects = {sphere};

result = swsynth.run3D(cfg);

verifyTrue(testCase, any(result.truth.cs_map_zyx(:) == 3.0));
verifyTrue(testCase, any(result.truth.cs_map_zyx(:) == 2.0));
verifyTrue(testCase, any(result.truth.material_id_zyx(:) == 1));
verifyTrue(testCase, result.sample.validation.analysis_ready);
verifyEqual(testCase, size(result.wavefield.U_zyx), ...
    size(result.truth.cs_map_zyx));
verifyEqual(testCase, ...
    wavefield.validateSample(result.sample).spatial_dimension, 3);

end

function testHeterogeneityChangesFieldRelativeToHomogeneous(testCase)

base = compactConfig();
base.propagation.model = "plane_wave";
base.propagation.phase_model = "volumetric_eikonal";
base.directions.count = 1;
base.directions.sampling_method = "explicit";
base.directions.explicit_xyz = [1 0 0];
base.polarization.model = "transverse_preferred";
base.sources.amplitude_jitter_fraction = 0;

homogeneous = swsynth.run3D(base);

heterogeneousCfg = base;
slab = struct();
slab.type = "slab";
slab.cs_m_s = 3.0;
slab.normal_xyz = [1 0 0];
slab.offset_m = 0.003;
heterogeneousCfg.medium.objects = {slab};
heterogeneous = swsynth.run3D(heterogeneousCfg);

relativeDifference = norm( ...
    heterogeneous.wavefield.U_zyx(:) - homogeneous.wavefield.U_zyx(:)) / ...
    max(norm(homogeneous.wavefield.U_zyx(:)), eps);

verifyGreaterThan(testCase, relativeDifference, 1e-3);

end

function testHomogeneousAnalyticRejectsHeterogeneousMedium(testCase)

cfg = compactConfig();
cfg.propagation.model = "plane_wave";
cfg.propagation.phase_model = "homogeneous_analytic";
box = struct();
box.type = "box";
box.cs_m_s = 2.5;
box.center_xyz_m = [0.003 0.003 0.003];
box.size_xyz_m = [0.002 0.002 0.002];
cfg.medium.objects = {box};

verifyError(testCase, @() swsynth.run3D(cfg), ...
    "swsynth:HomogeneousAnalytic3DRequiresUniformMedium");

end

function cfg = compactConfig()

cfg = swsynth.defaultConfig3D();
cfg.seed = 17;
cfg.domain.Lx_m = 0.006;
cfg.domain.Ly_m = 0.006;
cfg.domain.Lz_m = 0.006;
cfg.domain.dx_m = 0.001;
cfg.domain.dy_m = 0.001;
cfg.domain.dz_m = 0.001;
cfg.medium.background_cs_m_s = 2.0;
cfg.wavefield.frequency_hz = 100;
cfg.wavefield.quantity = "velocity";
cfg.measurement.axis_xyz = [0 0 1];
cfg.directions.space = "three_dimensional";
cfg.directions.support.type = "full_sphere";
cfg.noise.snr_db = Inf;
cfg.execution.use_parallel = false;
cfg.propagation.eikonal.maximum_iterations = 100;
cfg.propagation.eikonal.tolerance_s = 1e-10;

end
