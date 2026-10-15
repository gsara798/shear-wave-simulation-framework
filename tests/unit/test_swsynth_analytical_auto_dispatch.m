function tests = test_swsynth_analytical_auto_dispatch
%TEST_SWSYNTH_ANALYTICAL_AUTO_DISPATCH Neutral analytical phase contract.
tests = functiontests(localfunctions);
end

function testPlanarAnalyticalEqualsLegacy(testCase)
cfg = swsynth.defaultConfig();
cfg.propagation.model = "plane_wave";
cfg.propagation.phase_model = "analytical";
cfg.domain.Lx_m = .006; cfg.domain.Lz_m = .006;
cfg.domain.dx_m = .002; cfg.domain.dz_m = .002;
cfg.directions.count = 2; cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;
modern = swsynth.run(cfg);
cfg.propagation.phase_model = "homogeneous_analytic";
legacy = swsynth.run(cfg);
verifyEqual(testCase,modern.wavefield.U_zx,legacy.wavefield.U_zx);
verifyEqual(testCase,modern.wavefield.weights,legacy.wavefield.weights);
end

function testProjectedAnalyticalEqualsLegacy(testCase)
cfg = swsynth.defaultConfig();
cfg.propagation.model = "plane_wave";
cfg.propagation.phase_model = "analytical";
cfg.domain.Lx_m = .006; cfg.domain.Lz_m = .006;
cfg.domain.dx_m = .002; cfg.domain.dz_m = .002;
cfg.directions.space = "three_dimensional";
cfg.directions.count = 2; cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;
cfg.observation = struct("geometry","projected3d","component","z");
modern = swsynth.run(cfg);
cfg = rmfield(cfg,"observation");
cfg.propagation.phase_model = "homogeneous_analytic";
legacy = swsynth.run(cfg);
verifyEqual(testCase,modern.wavefield.U_zx,legacy.wavefield.U_zx);
end

function testVolumetricAnalyticalEqualsLegacy(testCase)
cfg = swsynth.defaultConfig3D();
cfg.domain.Lx_m=.006; cfg.domain.Ly_m=.006; cfg.domain.Lz_m=.006;
cfg.domain.dx_m=.002; cfg.domain.dy_m=.002; cfg.domain.dz_m=.002;
cfg.wavefield.frequency_hz = 100;
cfg.directions.count = 1;
cfg.directions.sampling_method = "explicit";
cfg.directions.explicit_xyz = [1,0,0];
cfg.execution.use_parallel=false; cfg.noise.snr_db=Inf;
cfg.propagation.phase_model="analytical";
modern=swsynth.run(cfg);
cfg.propagation.phase_model="homogeneous_analytic";
legacy=swsynth.run(cfg);
verifyEqual(testCase,modern.wavefield.U_zyx,legacy.wavefield.U_zyx);
end

function testAnalyticalHeterogeneousRejected(testCase)
cfg = swsynth.defaultConfig();
cfg.propagation.model="plane_wave";
cfg.propagation.phase_model="analytical";
cfg.medium.objects={struct("type","circle","cs_m_s",3, ...
    "center_xz_m",[.025,.025],"radius_m",.005)};
verifyError(testCase,@() swsynth.run(cfg), ...
    "swsynth:PlaneWaveRequiresHomogeneousMedium");
end

function testVolumetricAnalyticalHeterogeneousRejected(testCase)
cfg=swsynth.defaultConfig3D();
cfg.propagation.phase_model="analytical";
cfg.medium.objects={struct("type","sphere","cs_m_s",3, ...
    "center_xyz_m",[.01 .01 .01],"radius_m",.002)};
verifyError(testCase,@() swsynth.run(cfg), ...
    "swsynth:HomogeneousAnalytic3DRequiresUniformMedium");
end

function testAnalyticalSolverResolvesByGeometry(testCase)
verifyEqual(testCase,swsynth.phase.resolveSolver( ...
    "plane_wave","analytical","2d"),"homogeneous_plane_2d");
verifyEqual(testCase,swsynth.phase.resolveSolver( ...
    "plane_wave","analytical","projected3d"),"homogeneous_projected_3d");
verifyEqual(testCase,swsynth.phase.resolveSolver( ...
    "plane_wave","analytical","volumetric3d"),"homogeneous_plane_3d");
end
