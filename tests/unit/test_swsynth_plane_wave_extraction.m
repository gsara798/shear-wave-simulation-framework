function tests = test_swsynth_plane_wave_extraction
%TEST_SWSYNTH_PLANE_WAVE_EXTRACTION Compare with frozen legacy implementation.
tests = functiontests(localfunctions);
end

function testEquivalentFieldsAndMetadata(testCase)
for space = ["two_dimensional","three_dimensional"]
    for snr = [Inf,20]
        cfg = swsynth.defaultConfig();
        cfg.propagation.model = "plane_wave";
        cfg.domain.Lx_m = 0.008; cfg.domain.Lz_m = 0.008;
        cfg.domain.dx_m = 0.002; cfg.domain.dz_m = 0.002;
        cfg.directions.space = space;
        cfg.directions.count = 5;
        cfg.noise.snr_db = snr;
        cfg.execution.use_parallel = false;
        [cfg,~] = swsynth.validateConfig(cfg);
        maps = swsynth.buildMediumMaps(cfg);
        directions = swsynth.generateDirections(cfg);
        before = swsynth.synthesizeWavefield2D(cfg,maps,directions);
        after = swsynth.propagation.plane_wave.synthesize2D(cfg,maps,directions);
        verifyEqual(testCase,after,before);
        publicResult = swsynth.run(cfg);
        verifyEqual(testCase,publicResult.wavefield,before);
    end
end
end

function testRejectsSphericalModel(testCase)
cfg = swsynth.defaultConfig();
verifyError(testCase,@() swsynth.propagation.plane_wave.synthesize2D( ...
    cfg,struct(),struct()),"swsynth:InvalidPlaneWaveModel");
end
