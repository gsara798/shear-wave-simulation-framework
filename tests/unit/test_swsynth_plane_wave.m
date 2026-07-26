function tests = test_swsynth_plane_wave
%TEST_SWSYNTH_PLANE_WAVE Tests for plane-wave field synthesis.

tests = functiontests(localfunctions);

end

function testPlaneWaveProducesExpectedDimensions(testCase)

cfg = compactConfig();
cfg.propagation.model = "plane_wave";
cfg.directions.space = "two_dimensional";
cfg.directions.count = 8;
cfg.directions.sampling_method = "fibonacci";
cfg.directions.support.type = "full_circle";

result = swsynth.run(cfg);

verifySize(testCase, result.wavefield.U_zx, [11, 13]);
verifySize(testCase, result.truth.cs_map_zx, [11, 13]);
verifyTrue(testCase, result.wavefield.is_complex);
verifyEqual(testCase, result.wavefield.output_convention, "U(z,x)");
verifyEqual(testCase, result.wavefield.sources.x_m, []);

end

function testSingleInPlaneWaveHasExpectedSpatialPhase(testCase)

cfg = compactConfig();
cfg.seed = 7;
cfg.propagation.model = "plane_wave";
cfg.directions.space = "two_dimensional";
cfg.directions.count = 1;
cfg.directions.sampling_method = "fibonacci";
cfg.directions.support.type = "cone";
cfg.directions.support.axis_xyz = [1, 0, 0];
cfg.directions.support.half_angle_deg = 0;
cfg.sources.amplitude_jitter_fraction = 0;
cfg.noise.snr_db = Inf;

result = swsynth.run(cfg);

U = result.wavefield.U_zx;
reference = U(:,1);
ratio = U(:,2) ./ reference;

expectedPhaseStep = ...
    2*pi*cfg.wavefield.frequency_hz / ...
    cfg.medium.background_cs_m_s * ...
    cfg.domain.dx_m;

verifyEqual( ...
    testCase, ...
    ratio, ...
    exp(1i*expectedPhaseStep) * ones(size(ratio)), ...
    AbsTol=1e-5);

end

function cfg = compactConfig()

cfg = swsynth.defaultConfig();
cfg.domain.Lx_m = 0.012;
cfg.domain.Lz_m = 0.010;
cfg.domain.dx_m = 0.001;
cfg.domain.dz_m = 0.001;
cfg.medium.background_cs_m_s = 2.0;
cfg.wavefield.frequency_hz = 100;
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;

end
