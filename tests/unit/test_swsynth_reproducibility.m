function tests = test_swsynth_reproducibility
%TEST_SWSYNTH_REPRODUCIBILITY Fixed-seed reproducibility tests.

tests = functiontests(localfunctions);

end

function testIdenticalSeedProducesIdenticalResult(testCase)

cfg = compactConfig();
cfg.seed = 1234;

first = swsynth.run(cfg);
second = swsynth.run(cfg);

verifyEqual(testCase, first.directions.ux, second.directions.ux);
verifyEqual(testCase, first.directions.uy, second.directions.uy);
verifyEqual(testCase, first.directions.uz, second.directions.uz);
verifyEqual(testCase, first.wavefield.polarization_z, ...
    second.wavefield.polarization_z);
verifyEqual(testCase, first.wavefield.phase_rad, ...
    second.wavefield.phase_rad);
verifyEqual(testCase, first.wavefield.amplitude, ...
    second.wavefield.amplitude);
verifyEqual(testCase, first.wavefield.U_zx, second.wavefield.U_zx);

end

function testDifferentSeedChangesRandomField(testCase)

cfg = compactConfig();
cfg.seed = 1234;
first = swsynth.run(cfg);

cfg.seed = 1235;
second = swsynth.run(cfg);

verifyNotEqual(testCase, first.wavefield.U_zx, second.wavefield.U_zx);

end

function testFiniteSnrRemainsReproducible(testCase)

cfg = compactConfig();
cfg.seed = 88;
cfg.noise.snr_db = 20;

first = swsynth.run(cfg);
second = swsynth.run(cfg);

verifyEqual(testCase, first.wavefield.U_zx, second.wavefield.U_zx);

end

function cfg = compactConfig()

cfg = swsynth.defaultConfig();
cfg.domain.Lx_m = 0.01;
cfg.domain.Lz_m = 0.008;
cfg.domain.dx_m = 0.001;
cfg.domain.dz_m = 0.001;
cfg.medium.background_cs_m_s = 2.0;
cfg.wavefield.frequency_hz = 100;
cfg.propagation.model = "spherical_wave";
cfg.directions.count = 8;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "random";
cfg.directions.support.type = "cone";
cfg.directions.support.axis_xyz = [-1, 0, 0];
cfg.directions.support.half_angle_deg = 80;
cfg.sources.radius_range_m = [0.015, 0.02];
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;

end
