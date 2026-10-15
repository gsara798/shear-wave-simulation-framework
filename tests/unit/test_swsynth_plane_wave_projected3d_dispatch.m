function tests = test_swsynth_plane_wave_projected3d_dispatch
%TEST_SWSYNTH_PLANE_WAVE_PROJECTED3D_DISPATCH Verify phase-specific routing.
tests = functiontests(localfunctions);
end

function testAnalyticalUsesExistingPlaneSynthesizer(testCase)
cfg = smallPlanarConfig();
cfg.propagation.phase_model = "analytical";
[cfg,~] = swsynth.validateConfig(cfg);
maps = swsynth.buildMediumMaps(cfg);
directions = swsynth.generateDirections(cfg);
expected = swsynth.propagation.plane_wave.synthesize2D(cfg,maps,directions);
actual = swsynth.propagation.plane_wave.synthesizeProjected3D(cfg,maps,directions);
verifyEqual(testCase,actual,expected);
end

function testEikonalUsesExistingBackend(testCase)
cfg = smallPlanarConfig();
cfg.propagation.model = "projected3d_eikonal";
cfg.propagation.phase_model = "eikonal";
[cfg,~] = swsynth.validateConfig(cfg);
maps = swsynth.buildMediumMaps(cfg);
directions = swsynth.generateDirections(cfg);
rng(1234,'twister');
expected = swsynth.propagation.plane_wave.synthesizeProjected3DEikonal( ...
    cfg,maps,directions);
rng(1234,'twister');
actual = swsynth.propagation.plane_wave.synthesizeProjected3D( ...
    cfg,maps,directions);
expected.diagnostics.synthesis = removeTiming(expected.diagnostics.synthesis);
actual.diagnostics.synthesis = removeTiming(actual.diagnostics.synthesis);
verifyEqual(testCase,actual,expected);
end

function testRunAnalyticalMatchesDirect(testCase)
cfg = smallPlanarConfig();
cfg.propagation.phase_model = "analytical";
maps = swsynth.buildMediumMaps(cfg);
directions = swsynth.generateDirections(cfg);
expected = swsynth.propagation.plane_wave.synthesizeProjected3D( ...
    cfg,maps,directions);
actual = swsynth.run(cfg);
verifyEqual(testCase,actual.wavefield.U_zx,expected.U_zx);
verifyEqual(testCase,actual.wavefield.phase_solver,"homogeneous_projected_3d");
end

function testRejectPhysical2DDirections(testCase)
cfg = smallPlanarConfig();
cfg.directions.space = "two_dimensional";
verifyError(testCase, @() swsynth.propagation.plane_wave.synthesizeProjected3D( ...
    cfg,struct(),struct()),"swsynth:Projected3DRequiresThreeDimensions");
end

function cfg = smallPlanarConfig()
cfg = swsynth.defaultConfig();
cfg.propagation.model = "plane_wave";
cfg.domain.Lx_m = .006; cfg.domain.Lz_m = .006;
cfg.domain.dx_m = .001; cfg.domain.dz_m = .001;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "explicit";
cfg.directions.count = 1;
cfg.directions.explicit_xyz = [1 0 0];
cfg.noise.snr_db = Inf;
cfg.execution.use_parallel = false;
end

function d = removeTiming(d)
fields = ["per_direction_time_s","total_direction_time_s"];
for name = fields
    if isfield(d,name)
        d = rmfield(d,name);
    end
end
end
