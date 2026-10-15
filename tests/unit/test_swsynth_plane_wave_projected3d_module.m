function tests = test_swsynth_plane_wave_projected3d_module
%TEST_SWSYNTH_PLANE_WAVE_PROJECTED3D_MODULE Verify relocated entrypoints.
tests = functiontests(localfunctions);
end

function testLegacyWrapperMatchesModule(testCase)
cfg = swsynth.defaultConfig();
cfg.propagation.model = "projected3d_eikonal";
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "explicit";
cfg.directions.count = 1;
cfg.directions.explicit_xyz = [1,0,0];
cfg.domain.Lx_m = 0.006; cfg.domain.Lz_m = 0.006;
cfg.domain.dx_m = 0.001; cfg.domain.dz_m = 0.001;
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;
[cfg,~] = swsynth.validateConfig(cfg);
maps = swsynth.buildMediumMaps(cfg);
directions = swsynth.generateDirections(cfg);
rng(31415,'twister');
legacy = swsynth.synthesizeProjected3DEikonal(cfg,maps,directions);
rng(31415,'twister');
modular = swsynth.propagation.plane_wave.synthesizeProjected3D(cfg,maps,directions);
% Timing diagnostics are nondeterministic and are not physical outputs.
legacy.diagnostics.synthesis = stripTimingDiagnostics(legacy.diagnostics.synthesis);
modular.diagnostics.synthesis = stripTimingDiagnostics(modular.diagnostics.synthesis);
verifyEqual(testCase,modular,legacy);
end

function testUnifiedRunStillUsesProjected3D(testCase)
cfg = swsynth.defaultConfig();
cfg.propagation.model = "projected3d_eikonal";
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "explicit";
cfg.directions.count = 1;
cfg.directions.explicit_xyz = [1,0,0];
cfg.domain.Lx_m = 0.006; cfg.domain.Lz_m = 0.006;
cfg.domain.dx_m = 0.001; cfg.domain.dz_m = 0.001;
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;
a = swsynth.run(cfg); b = swsynth.run(cfg);
% Do not compare wall-clock timing across two valid simulations.
a.wavefield.diagnostics.synthesis = stripTimingDiagnostics( ...
    a.wavefield.diagnostics.synthesis);
b.wavefield.diagnostics.synthesis = stripTimingDiagnostics( ...
    b.wavefield.diagnostics.synthesis);
verifyEqual(testCase,a.wavefield,b.wavefield);
verifyEqual(testCase,a.wavefield.propagation_model,"projected3d_eikonal");
end

function diagnostics = stripTimingDiagnostics(diagnostics)
% Keep physical and numerical solver diagnostics; discard measured durations.
timingFields = ["per_direction_time_s","total_direction_time_s"];
for fieldName = timingFields
    if isfield(diagnostics,fieldName)
        diagnostics = rmfield(diagnostics,fieldName);
    end
end
end
