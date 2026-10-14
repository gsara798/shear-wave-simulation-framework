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
function testMultiSourceExplicitPositionAccepted(testCase)
cfg=makeCfg();
cfg.directions.count=2;
cfg.sources.position_xyz_m=[-0.01 0 0.017; 0.06 0 0.031];
legacy=swsynth.compat.resolveAnalyticalSphericalConfig(cfg);
[resolved,~]=swsynth.validateConfig(legacy);
verifyEqual(testCase,resolved.sources.position_xyz_m,cfg.sources.position_xyz_m);
result=swsynth.run(legacy);
verifyEqual(testCase,result.wavefield.sources.x_m, ...
    cfg.sources.position_xyz_m(:,1)',"AbsTol",1e-6);
verifyEqual(testCase,result.wavefield.sources.z_m, ...
    cfg.sources.position_xyz_m(:,3)',"AbsTol",1e-6);
end
function testWrongPositionCountRejected(testCase)
cfg=makeCfg();cfg.directions.count=2;
cfg.sources.position_xyz_m=[-0.01 0 0.017];
legacy=swsynth.compat.resolveAnalyticalSphericalConfig(cfg);
verifyError(testCase,@()swsynth.validateConfig(legacy), ...
    "swsynth:InvalidSourcePosition");
end
function testLegacyFibonacciRadiusStillWorks(testCase)
cfg=makeCfg();
cfg.directions.count=8;
cfg.directions.sampling_method="fibonacci";
cfg.sources.radius_range_m=[0.025 0.025];
cfg.sources.position_xyz_m=[];
legacy=swsynth.compat.resolveAnalyticalSphericalConfig(cfg);
r=swsynth.run(legacy);
radii=sqrt((double(r.wavefield.sources.x_m)-cfg.domain.Lx_m/2).^2 + ...
    (double(r.wavefield.sources.y_m)-cfg.domain.observation_y_m).^2 + ...
    (double(r.wavefield.sources.z_m)-cfg.domain.Lz_m/2).^2);
verifyEqual(testCase,radii,0.025*ones(size(radii)),"AbsTol",1e-6);
end
function testPlacementExplicitWithoutDirections(testCase)
cfg=makeCfg();
cfg=rmfield(cfg,"directions");
cfg.sources.count=2;
cfg.sources.placement=struct("method","explicit", ...
    "position_xyz_m",[-0.01 0 0.01;0.06 0 0.03]);
legacy=swsynth.compat.resolveAnalyticalSphericalConfig(cfg);
verifyEqual(testCase,legacy.directions.count,2);
verifyEqual(testCase,legacy.sources.position_xyz_m, ...
    cfg.sources.placement.position_xyz_m);
[validated,~]=swsynth.validateConfig(legacy);
verifyEqual(testCase,validated.directions.count,2);
end
function testPlacementFibonacciAndRandom(testCase)
for method=["fibonacci","random"]
    cfg=makeCfg();
    cfg=rmfield(cfg,"directions");
    cfg.sources.count=8;
    cfg.sources.placement=struct("method",method, ...
        "radius_m",0.025,"support",struct("type","full_sphere"));
    legacy=swsynth.compat.resolveAnalyticalSphericalConfig(cfg);
    verifyEqual(testCase,string(legacy.directions.sampling_method),method);
    verifyEqual(testCase,legacy.sources.radius_range_m,[0.025 0.025]);
    result=swsynth.run(legacy);
    radii=sqrt((double(result.wavefield.sources.x_m)-0.025).^2 + ...
        double(result.wavefield.sources.y_m).^2 + ...
        (double(result.wavefield.sources.z_m)-0.025).^2);
    verifyEqual(testCase,radii,0.025*ones(size(radii)),"AbsTol",1e-6);
end
end
function testPlacementConflictsRejected(testCase)
cfg=makeCfg();cfg.sources.count=1;
cfg.sources.placement=struct("method","explicit", ...
    "position_xyz_m",[-0.01 0 0.02],"radius_m",0.025);
verifyError(testCase,@()swsynth.compat.resolveAnalyticalSphericalConfig(cfg), ...
    "swsynth:ConflictingSourcePlacement");
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
