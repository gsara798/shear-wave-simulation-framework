function tests = test_swsynth_unified_run
%TEST_SWSYNTH_UNIFIED_RUN Unified public entry and legacy compatibility.
tests = functiontests(localfunctions);
end

function testVolumetricAliasProducesSameResult(testCase)
cfg = compact3D();
legacy = swsynth.run3D(cfg);
modern = swsynth.run(cfg);
verifyEqual(testCase,modern.wavefield.U_zyx,legacy.wavefield.U_zyx);
verifyEqual(testCase,modern.sample.wavefield.data_zyx,legacy.sample.wavefield.data_zyx);
verifyEqual(testCase,modern.config,legacy.config);
end

function testExplicitVolumetricGeometry(testCase)
cfg = compact3D();
original = swsynth.run3D(cfg);
cfg.observation = struct('geometry',"volumetric3d",'component',"z");
actual = swsynth.run(cfg);
verifyEqual(testCase,actual.wavefield.U_zyx,original.wavefield.U_zyx);
verifyEqual(testCase,actual.config,original.config);
end

function testPlanarDefaultPreserved(testCase)
cfg = swsynth.defaultConfig();
cfg.domain.Lx_m = 0.006; cfg.domain.Lz_m = 0.006;
cfg.domain.dx_m = 0.002; cfg.domain.dz_m = 0.002;
cfg.directions.count = 1;
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;
result = swsynth.run(cfg);
verifySize(testCase,result.wavefield.U_zx,[4,4]);
verifyEqual(testCase,result.sample.spatial_dimension,2);
end

function testRejectsMismatchedObservationGeometry(testCase)
cfg = compact3D();
cfg.observation = struct('geometry',"2d",'component',"z");
verifyError(testCase,@() swsynth.run(cfg), ...
    "swsynth:ObservationDomainMismatch");
end

function cfg = compact3D()
cfg = swsynth.defaultConfig3D();
cfg.domain.Lx_m = 0.006; cfg.domain.Ly_m = 0.004;
cfg.domain.Lz_m = 0.006;
cfg.domain.dx_m = 0.002; cfg.domain.dy_m = 0.002;
cfg.domain.dz_m = 0.002;
cfg.directions.count = 1;
cfg.directions.sampling_method = "explicit";
cfg.directions.explicit_xyz = [1,0,0];
cfg.polarization.model = "transverse_preferred";
cfg.sources.amplitude_jitter_fraction = 0;
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;
end
