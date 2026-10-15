function tests = test_swsynth_plane_wave_volumetric_module
%TEST_SWSYNTH_PLANE_WAVE_VOLUMETRIC_MODULE Regression for modularized 3D paths.
tests = functiontests(localfunctions);
end

function testAnalyticalWrapperMatchesModule(testCase)
cfg = smallConfig();
cfg.propagation.phase_model = "analytical";
maps = swsynth.buildMediumMaps3D(cfg);
rng(184,'twister');
legacy = swsynth.synthesizePlaneWave3D(cfg);
rng(184,'twister');
modular = swsynth.propagation.plane_wave.synthesizeVolumetric3D(cfg,maps);
verifyEqual(testCase,modular,legacy);
end

function testEikonalWrapperMatchesModule(testCase)
cfg = smallConfig();
cfg.propagation.phase_model = "eikonal";
maps = swsynth.buildMediumMaps3D(cfg);
rng(184,'twister');
legacy = swsynth.synthesizeVolumetricEikonal3D(cfg,maps);
rng(184,'twister');
modular = swsynth.propagation.plane_wave.synthesizeVolumetric3D(cfg,maps);
verifyEqual(testCase,modular,legacy);
end

function testRunPreservesField(testCase)
cfg = smallConfig();
for phase = ["analytical","eikonal"]
    cfg.propagation.phase_model = phase;
    maps = swsynth.buildMediumMaps3D(cfg);
    expected = swsynth.propagation.plane_wave.synthesizeVolumetric3D(cfg,maps);
    actual = swsynth.run(cfg);
    verifyEqual(testCase,actual.wavefield.U_zyx,expected.U_zyx);
end
end

function cfg = smallConfig()
cfg = swsynth.defaultConfig3D();
cfg.domain.Lx_m = .006; cfg.domain.Ly_m = .006; cfg.domain.Lz_m = .006;
cfg.domain.dx_m = .002; cfg.domain.dy_m = .002; cfg.domain.dz_m = .002;
cfg.directions.count = 1;
cfg.directions.sampling_method = "explicit";
cfg.directions.explicit_xyz = [1 0 0];
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;
end
