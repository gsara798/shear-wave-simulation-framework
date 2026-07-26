function tests = test_swsynth_spherical_wave
%TEST_SWSYNTH_SPHERICAL_WAVE Tests for spherical-wave synthesis.

tests = functiontests(localfunctions);

end

function testSphericalWaveProducesSourcesAndFiniteField(testCase)

cfg = compactConfig();
cfg.propagation.model = "spherical_wave";
cfg.directions.count = 6;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.support.type = "full_sphere";

result = swsynth.run(cfg);

verifySize(testCase, result.wavefield.U_zx, [11, 13]);
verifyEqual(testCase, numel(result.wavefield.sources.x_m), 6);
verifyEqual(testCase, numel(result.wavefield.sources.y_m), 6);
verifyEqual(testCase, numel(result.wavefield.sources.z_m), 6);
verifyTrue(testCase, all(isfinite(result.wavefield.U_zx(:))));
verifyTrue(testCase, any(abs(result.wavefield.U_zx(:)) > 0));

end

function testGeometricDecayChangesField(testCase)

cfg = compactConfig();
cfg.propagation.model = "spherical_wave";
cfg.directions.count = 4;
cfg.directions.space = "two_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.support.type = "full_circle";
cfg.amplitude.geometric_decay_exponent = 0;

withoutDecay = swsynth.run(cfg);

cfg.amplitude.geometric_decay_exponent = 1;
withDecay = swsynth.run(cfg);

verifyNotEqual( ...
    testCase, ...
    withDecay.wavefield.U_zx, ...
    withoutDecay.wavefield.U_zx);

end

function cfg = compactConfig()

cfg = swsynth.defaultConfig();
cfg.seed = 15;
cfg.domain.Lx_m = 0.012;
cfg.domain.Lz_m = 0.010;
cfg.domain.dx_m = 0.001;
cfg.domain.dz_m = 0.001;
cfg.medium.background_cs_m_s = 2.5;
cfg.wavefield.frequency_hz = 120;
cfg.sources.radius_range_m = [0.02, 0.025];
cfg.sources.amplitude_jitter_fraction = 0.05;
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;

end
