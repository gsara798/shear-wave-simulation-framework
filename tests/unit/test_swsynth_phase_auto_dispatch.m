function tests = test_swsynth_phase_auto_dispatch
%TEST_SWSYNTH_PHASE_AUTO_DISPATCH Neutral eikonal selects geometry solver.
tests = functiontests(localfunctions);
end

function testProjected3DEikonalEqualsLegacy(testCase)
cfg = swsynth.defaultConfig();
cfg.domain.Lx_m=.006; cfg.domain.Lz_m=.006;
cfg.domain.dx_m=.001; cfg.domain.dz_m=.001;
cfg.directions.space="three_dimensional";
cfg.directions.sampling_method="explicit";
cfg.directions.count=1;
cfg.directions.explicit_xyz=[1 0 0];
cfg.noise.snr_db=Inf; cfg.execution.use_parallel=false;
cfg.propagation.model="plane_wave";
cfg.propagation.phase_model="eikonal";
cfg.observation=struct("geometry","projected3d","component","z");
modern=swsynth.run(cfg);
cfg=rmfield(cfg,"observation");
cfg.propagation.model="projected3d_eikonal";
legacy=swsynth.run(cfg);
verifyEqual(testCase,modern.wavefield.U_zx,legacy.wavefield.U_zx);
verifyEqual(testCase,modern.wavefield.weights,legacy.wavefield.weights);
verifyEqual(testCase,modern.wavefield.phase_rad,legacy.wavefield.phase_rad);
end

function testVolumetricNeutralEikonalEqualsLegacy(testCase)
cfg=swsynth.defaultConfig3D();
cfg.domain.Lx_m=.006; cfg.domain.Ly_m=.006; cfg.domain.Lz_m=.006;
cfg.domain.dx_m=.001; cfg.domain.dy_m=.001; cfg.domain.dz_m=.001;
cfg.wavefield.frequency_hz=100;
cfg.directions.count=1; cfg.directions.sampling_method="explicit";
cfg.directions.explicit_xyz=[1 0 0];
cfg.polarization.model="transverse_preferred";
cfg.noise.snr_db=Inf; cfg.execution.use_parallel=false;
cfg.propagation.phase_model="eikonal";
modern=swsynth.run(cfg);
cfg.propagation.phase_model="volumetric_eikonal";
legacy=swsynth.run(cfg);
verifyEqual(testCase,modern.wavefield.U_zyx,legacy.wavefield.U_zyx);
verifyEqual(testCase,modern.wavefield.observed_weights,legacy.wavefield.observed_weights);
end

function testAnalyticalHeterogeneousRejected(testCase)
cfg=swsynth.defaultConfig3D();
cfg.medium.objects={struct("type","sphere","cs_m_s",3, ...
    "center_xyz_m",[.01 .01 .01],"radius_m",.002)};
cfg.propagation.phase_model="homogeneous_analytic";
verifyError(testCase,@() swsynth.run(cfg), ...
    "swsynth:HomogeneousAnalytic3DRequiresUniformMedium");
end

function testUnsupported2DEikonalErrors(testCase)
cfg=swsynth.defaultConfig();
cfg.propagation.model="plane_wave";
cfg.propagation.phase_model="eikonal";
cfg.observation=struct("geometry","2d");
verifyError(testCase,@() swsynth.run(cfg), ...
    "swsynth:PhaseRoutingUnsupported");
end

function testSolverChoice(testCase)
verifyEqual(testCase,swsynth.phase.resolveSolver( ...
    "plane_wave","eikonal","projected3d"), ...
    "projected3d_directional_eikonal");
verifyEqual(testCase,swsynth.phase.resolveSolver( ...
    "plane_wave","eikonal","volumetric3d"), ...
    "volumetric_eikonal_3d");
verifyError(testCase,@() swsynth.phase.resolveSolver( ...
    "plane_wave","eikonal","2d"),"swsynth:PhaseRoutingUnsupported");
end
