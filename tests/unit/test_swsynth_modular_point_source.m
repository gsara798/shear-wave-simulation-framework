function tests = test_swsynth_modular_point_source
%TEST_SWSYNTH_MODULAR_POINT_SOURCE Shared far-field geometry regressions.
tests = functiontests(localfunctions);
end

function testLegacyProjectorMatchesCanonical(testCase)
a = [-0.03,0.002,0.02];
xyz = [0,0,0;0.01,0,0.005];
f = [1,0,0]; e = [0,0,1];
old = swsynth.propagation.spherical.computePointForceShearProjection(a,xyz,f,e);
new = swsynth.propagation.spherical.point_source.shear_far_field.computeShearProjection(a,xyz,f,e);
verifyEqual(testCase,old,new,'AbsTol',1e-14);
end

function testPlanarAndProjectedDispatchMatchLegacy(testCase)
cfg = swsynth.defaultConfig();
cfg.domain.Lx_m = 0.01; cfg.domain.Lz_m = 0.01;
cfg.domain.dx_m = 0.002; cfg.domain.dz_m = 0.002;
cfg.propagation.model = "spherical_wave";
cfg.sources.radiation.model = "point_force_shear_far_field";
cfg.sources.radiation.force_direction_xyz = [1,0,0];
cfg.sources.amplitude_jitter_fraction = 0;
cfg.noise.snr_db = Inf; cfg.execution.use_parallel = false;
cfg.directions.count = 1;
cfg.directions.sampling_method = "explicit";
cfg.directions.explicit_xyz = [-1,0,0];
cfg.sources.position_xyz_m = [-0.01,0,0.006];
cfg.directions.space = "two_dimensional";
checkOne(cfg,testCase);
cfg.directions.space = "three_dimensional";
checkOne(cfg,testCase);
end

function checkOne(cfg,testCase)
[cfg,~] = swsynth.validateConfig(cfg);
map = swsynth.buildMediumMaps(cfg);
dirs = swsynth.generateDirections(cfg);
legacy = swsynth.synthesizeWavefield2D(cfg,map,dirs);
actual = swsynth.run(cfg);
verifyEqual(testCase,actual.wavefield.U_zx,legacy.U_zx);
verifyEqual(testCase,actual.wavefield.weights,legacy.weights);
verifyEqual(testCase,actual.wavefield.amplitude,legacy.amplitude);
end

function testVolumetricMatchesPlanarCutForSingleSource(testCase)
base = swsynth.defaultConfig();
base.seed = 11;
base.domain.Lx_m = 0.01; base.domain.Lz_m = 0.01;
base.domain.dx_m = 0.002; base.domain.dz_m = 0.002;
base.wavefield.frequency_hz = 200;
base.medium.background_cs_m_s = 2;
base.directions.count = 1;
base.directions.space = "three_dimensional";
base.directions.sampling_method = "explicit";
base.directions.explicit_xyz = [-1,0,0];
base.sources.position_xyz_m = [-0.01,0,0.006];
base.sources.radiation.model = "point_force_shear_far_field";
base.sources.excitation = struct('force_direction_xyz',[1,0,0], ...
    'relative_amplitude',1,'phase_rad',0);
base.sources.amplitude_jitter_fraction = 0;
base.propagation.model = "spherical_wave";
base.amplitude.geometric_decay_exponent = 1;
base.noise.snr_db = Inf;
base.execution.use_parallel = false;
planar = swsynth.run(base);
vol = swsynth.defaultConfig3D();
vol.seed = base.seed;
vol.domain.Lx_m = base.domain.Lx_m;
vol.domain.Ly_m = 0.002;
vol.domain.Lz_m = base.domain.Lz_m;
vol.domain.dx_m = base.domain.dx_m;
vol.domain.dy_m = 0.002;
vol.domain.dz_m = base.domain.dz_m;
vol.medium.background_cs_m_s = base.medium.background_cs_m_s;
vol.wavefield.frequency_hz = base.wavefield.frequency_hz;
vol.propagation.model = "spherical_wave";
vol.propagation.phase_model = "homogeneous_analytic";
vol.propagation.geometric_decay_exponent = 1;
vol.directions = base.directions;
vol.sources.position_xyz_m = base.sources.position_xyz_m;
vol.sources.force_direction_xyz = [1,0,0];
vol.sources.relative_amplitude = 1;
vol.sources.phase_rad = 0;
vol.sources.amplitude_jitter_fraction = 0;
vol.noise.snr_db = Inf;
vol.execution.use_parallel = false;
result = swsynth.run3D(vol);
verifySize(testCase,result.wavefield.U_zyx,[6,2,6]);
verifyEqual(testCase,squeeze(result.wavefield.U_zyx(:,1,:)), ...
    planar.wavefield.U_zx,'AbsTol',2e-3,'RelTol',2e-4);
end
