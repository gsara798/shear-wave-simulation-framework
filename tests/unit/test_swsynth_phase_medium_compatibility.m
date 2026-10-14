function tests = test_swsynth_phase_medium_compatibility
%TEST_SWSYNTH_PHASE_MEDIUM_COMPATIBILITY User-selected phase is validated.
tests = functiontests(localfunctions);
end

function testPlanarExplicitAnalyticMatchesLegacy(testCase)
cfg = planarCfg();
a = swsynth.run(cfg);
cfg.propagation.phase_model = "homogeneous_analytic";
b = swsynth.run(cfg);
verifyEqual(testCase,b.wavefield.U_zx,a.wavefield.U_zx);
verifyEqual(testCase,b.wavefield.phase_model,"homogeneous_analytic");
end

function testPlanarAnalyticRejectsObjects(testCase)
cfg = planarCfg();
cfg.propagation.phase_model = "homogeneous_analytic";
cfg.medium.objects = {struct("type","circle", ...
    "center_x_m",0.003,"center_z_m",0.003,"radius_m",0.001, ...
    "cs_m_s",3)};
verifyError(testCase,@() swsynth.validateConfig(cfg), ...
    "swsynth:PlaneWaveRequiresHomogeneousMedium");
end

function testSphericalDoesNotSilentlyAcceptAnalytic(testCase)
cfg = swsynth.defaultConfig();
cfg.propagation.phase_model = "homogeneous_analytic";
verifyError(testCase,@() swsynth.validateConfig(cfg), ...
    "swsynth:UnsupportedPhaseModelForPropagation");
end

function testVolumetricAnalyticRejectsHeterogeneity(testCase)
cfg = swsynth.defaultConfig3D();
cfg.medium.objects = {struct("type","sphere", ...
    "center_xyz_m",[0.01,0.01,0.01],"radius_m",0.002,"cs_m_s",3)};
verifyError(testCase,@() swsynth.validateConfig3D(cfg), ...
    "swsynth:HomogeneousAnalytic3DRequiresUniformMedium");
end

function cfg = planarCfg()
cfg = swsynth.defaultConfig();
cfg.propagation.model = "plane_wave";
cfg.directions.count = 1;
cfg.domain.Lx_m = 0.006; cfg.domain.Lz_m = 0.006;
cfg.domain.dx_m = 0.002; cfg.domain.dz_m = 0.002;
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;
end
