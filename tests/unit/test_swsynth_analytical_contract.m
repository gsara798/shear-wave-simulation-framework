function tests=test_swsynth_analytical_contract
tests=functiontests(localfunctions);
end
function testProjected3DAdapter(testCase)
cfg=makeCfg();
legacy=swsynth.compat.resolveAnalyticalSphericalConfig(cfg);
verifyEqual(testCase,string(legacy.propagation.model),"spherical_wave");
verifyEqual(testCase,string(legacy.sources.radiation.model),"point_force_shear_far_field");
verifyEqual(testCase,double(legacy.sources.radiation.force_direction_xyz),[1 0 0]);
verifyFalse(testCase,isfield(legacy,"observation"));
[resolved,~]=swsynth.validateConfig(legacy);
verifyEqual(testCase,string(resolved.propagation.model),"spherical_wave");
end
function testPhysical2DRejected(testCase)
cfg=makeCfg();cfg.observation.geometry="2d";
verifyError(testCase,@()swsynth.compat.resolveAnalyticalSphericalConfig(cfg), ...
    "swsynth:Physical2DNotImplemented");
end
function testVolumetricRejected(testCase)
cfg=makeCfg();cfg.observation.geometry="volumetric3d";
verifyError(testCase,@()swsynth.compat.resolveAnalyticalSphericalConfig(cfg), ...
    "swsynth:VolumetricPointForceNotImplemented");
end
function testNotImplementedGreenRejected(testCase)
cfg=makeCfg();cfg.propagation.model="elastodynamic_green";
verifyError(testCase,@()swsynth.compat.resolveAnalyticalSphericalConfig(cfg), ...
    "swsynth:UnsupportedRadiationModel");
end
function testPlaneRejected(testCase)
cfg=makeCfg();cfg.propagation.wave_type="plane";
verifyError(testCase,@()swsynth.compat.resolveAnalyticalSphericalConfig(cfg), ...
    "swsynth:UnsupportedWaveType");
end
function testPositionIsUsedInField(testCase)
cfg=makeCfg();
cfg.sources.position_xyz_m=[-0.01 0 0.017];
legacy=swsynth.compat.resolveAnalyticalSphericalConfig(cfg);
[resolved,~]=swsynth.validateConfig(legacy);
verifyEqual(testCase,resolved.sources.position_xyz_m,[-0.01 0 0.017]);
w1=swsynth.run(legacy);
legacy.sources.position_xyz_m=[-0.01 0 0.027];
w2=swsynth.run(legacy);
verifyGreaterThan(testCase, ...
    norm(double(w1.wavefield.U_zx(:))-double(w2.wavefield.U_zx(:))),1e-6);
end
function testInvalidPositionRejected(testCase)
cfg=makeCfg();
cfg.sources.position_xyz_m=[NaN 0 0];
verifyError(testCase,@()swsynth.compat.resolveAnalyticalSphericalConfig(cfg), ...
    "swsynth:InvalidSourcePosition");
end
function testMultiSourceExplicitPositionRejected(testCase)
cfg=makeCfg();
cfg.directions.count=2;
cfg.sources.position_xyz_m=[-0.01 0 0.017];
legacy=swsynth.compat.resolveAnalyticalSphericalConfig(cfg);
verifyError(testCase,@()swsynth.validateConfig(legacy), ...
    "swsynth:SourcePositionUnsupported");
end
function cfg=makeCfg()
cfg=swsynth.defaultConfig();
cfg.directions.count=1;
cfg.simulation=struct("method","analytical");
cfg.observation=struct("geometry","projected3d","component","z");
cfg.propagation.model="point_force_shear_far_field";
cfg.propagation.wave_type="spherical";
cfg.sources.geometry="point";
cfg.sources.force_direction_xyz=[1 0 0];
end
