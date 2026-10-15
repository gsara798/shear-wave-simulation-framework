function tests = test_swsynth_phase_provenance
%TEST_SWSYNTH_PHASE_PROVENANCE Record solver without changing field physics.
tests = functiontests(localfunctions);
end

function testPlanarAnalyticalProvenance(testCase)
cfg = swsynth.defaultConfig();
cfg.propagation.model = "plane_wave";
cfg.propagation.phase_model = "analytical";
cfg.domain.Lx_m=.006; cfg.domain.Lz_m=.006;
cfg.domain.dx_m=.002; cfg.domain.dz_m=.002;
cfg.directions.space="two_dimensional";
cfg.directions.count=2; cfg.execution.use_parallel=false;
cfg.noise.snr_db=Inf;
out=swsynth.run(cfg);
verifyEqual(testCase,out.wavefield.phase_solver,"homogeneous_plane_2d");
verifyEqual(testCase,out.wavefield.requested_phase_model,"analytical");
verifyEqual(testCase,out.wavefield.requested_propagation_model,"plane_wave");
end

function testProjectedEikonalKeepsUserIntent(testCase)
cfg=swsynth.defaultConfig();
cfg.propagation.model="plane_wave";
cfg.propagation.phase_model="eikonal";
cfg.observation=struct("geometry","projected3d","component","z");
cfg.domain.Lx_m=.006; cfg.domain.Lz_m=.006;
cfg.domain.dx_m=.001; cfg.domain.dz_m=.001;
cfg.directions.space="three_dimensional";
cfg.directions.sampling_method="explicit";
cfg.directions.count=1; cfg.directions.explicit_xyz=[1 0 0];
cfg.noise.snr_db=Inf; cfg.execution.use_parallel=false;
out=swsynth.run(cfg);
verifyEqual(testCase,out.wavefield.phase_solver,"projected3d_directional_eikonal");
verifyEqual(testCase,out.wavefield.requested_phase_model,"eikonal");
verifyEqual(testCase,out.wavefield.requested_propagation_model,"plane_wave");
verifyEqual(testCase,out.config.propagation.model,"projected3d_eikonal");
end

function testVolumetricAnalyticalProvenance(testCase)
cfg=swsynth.defaultConfig3D();
cfg.domain.Lx_m=.006; cfg.domain.Ly_m=.006; cfg.domain.Lz_m=.006;
cfg.domain.dx_m=.002; cfg.domain.dy_m=.002; cfg.domain.dz_m=.002;
cfg.directions.count=1; cfg.directions.sampling_method="explicit";
cfg.directions.explicit_xyz=[1 0 0];
cfg.execution.use_parallel=false; cfg.noise.snr_db=Inf;
cfg.propagation.phase_model="analytical";
out=swsynth.run(cfg);
verifyEqual(testCase,out.wavefield.phase_solver,"homogeneous_plane_3d");
verifyEqual(testCase,out.wavefield.requested_phase_model,"analytical");
end

function testVolumetricEikonalProvenance(testCase)
cfg=swsynth.defaultConfig3D();
cfg.domain.Lx_m=.006; cfg.domain.Ly_m=.006; cfg.domain.Lz_m=.006;
cfg.domain.dx_m=.002; cfg.domain.dy_m=.002; cfg.domain.dz_m=.002;
cfg.directions.count=1; cfg.directions.sampling_method="explicit";
cfg.directions.explicit_xyz=[1 0 0];
cfg.execution.use_parallel=false; cfg.noise.snr_db=Inf;
cfg.propagation.phase_model="eikonal";
out=swsynth.run(cfg);
verifyEqual(testCase,out.wavefield.phase_solver,"volumetric_eikonal_3d");
verifyEqual(testCase,out.wavefield.requested_phase_model,"eikonal");
end
