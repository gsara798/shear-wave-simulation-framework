function tests = test_swsynth_volumetric_3d
%TEST_SWSYNTH_VOLUMETRIC_3D Tests for native analytical 3D synthesis.

tests = functiontests(localfunctions);

end

function testRunProducesVolumetricContract(testCase)

cfg = compactConfig();
result = swsynth.run3D(cfg);
sample = result.sample;

verifyEqual(testCase, sample.spatial_dimension, 3);
verifyEqual(testCase, sample.coordinates.array_order, "zyx");
verifyEqual(testCase, sample.wavefield.quantity, "velocity");
verifyEqual(testCase, sample.wavefield.component, "axial_total");
verifyEqual(testCase, sample.measurement.axis_xyz, [0 0 1], AbsTol=1e-12);
verifyEqual(testCase, sample.propagation.source_dimension, 3);
verifyEqual(testCase, sample.propagation.direction_space, "three_dimensional");
verifySize(testCase, sample.wavefield.data_zyx, [5 4 6]);
verifyEqual(testCase, size(sample.truth.cs_map_zyx), [5 4 6]);
verifyTrue(testCase, sample.validation.analysis_ready);
verifyEqual(testCase, wavefield.validateSample(sample).spatial_dimension, 3);

end

function testSingleExplicitWaveHasKnownAxialProjection(testCase)

cfg = compactConfig();
cfg.seed = 7;
cfg.directions.count = 1;
cfg.directions.sampling_method = "explicit";
cfg.directions.explicit_xyz = [1 0 0];
cfg.directions.support.type = "full_sphere";
cfg.polarization.model = "transverse_preferred";
cfg.sources.amplitude_jitter_fraction = 0;

result = swsynth.run3D(cfg);
U = result.sample.wavefield.data_zyx;

% k along +x and the preferred transverse polarization along +z imply a
% unit observation projection. Therefore magnitude is spatially constant
% and phase increments only along x.
verifyEqual(testCase, abs(U), ones(size(U)), AbsTol=5e-6);
verifyEqual(testCase, result.wavefield.polarization_xyz, [0 0 1], AbsTol=1e-12);
verifyEqual(testCase, result.wavefield.projection_weights, 1, AbsTol=1e-12);

ratioX = U(1,1,2:end) ./ U(1,1,1:end-1);
expected = exp(1i * result.wavefield.k0_rad_m * cfg.domain.dx_m);
verifyEqual(testCase, ratioX, expected*ones(size(ratioX)), AbsTol=5e-5);

verifyEqual(testCase, U(:,2,:), U(:,1,:), AbsTol=5e-6);
verifyEqual(testCase, U(2,:,:), U(1,:,:), AbsTol=5e-6);

end

function testSameSeedIsReproducible(testCase)

cfg = compactConfig();
cfg.polarization.model = "transverse_random";
cfg.sources.amplitude_jitter_fraction = 0.1;

r1 = swsynth.run3D(cfg);
r2 = swsynth.run3D(cfg);

verifyEqual(testCase, r1.wavefield.U_zyx, r2.wavefield.U_zyx);
verifyEqual(testCase, r1.wavefield.polarization_xyz, r2.wavefield.polarization_xyz);
verifyEqual(testCase, r1.wavefield.source_weights, r2.wavefield.source_weights);

end

function testTruthWavenumberMatchesFrequencyAndSpeed(testCase)

result = swsynth.run3D(compactConfig());
expectedK = 2*pi*result.config.wavefield.frequency_hz / ...
    result.config.medium.background_cs_m_s;

verifyEqual(testCase, result.truth.k_map_zyx, ...
    expectedK * ones(size(result.truth.k_map_zyx)), AbsTol=1e-12);

end

function cfg = compactConfig()

cfg = swsynth.defaultConfig3D();
cfg.seed = 31;
cfg.domain.Lx_m = 0.005;
cfg.domain.Ly_m = 0.003;
cfg.domain.Lz_m = 0.004;
cfg.domain.dx_m = 0.001;
cfg.domain.dy_m = 0.001;
cfg.domain.dz_m = 0.001;
cfg.medium.background_cs_m_s = 2.0;
cfg.wavefield.frequency_hz = 100;
cfg.directions.count = 4;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.support.type = "full_sphere";
cfg.directions.in_plane_count = 0;
cfg.measurement.axis_xyz = [0 0 1];
cfg.polarization.model = "transverse_preferred";
cfg.sources.amplitude_jitter_fraction = 0;
cfg.noise.snr_db = Inf;
cfg.execution.use_parallel = false;
cfg.execution.synthesis_batch_size = 16;

end
