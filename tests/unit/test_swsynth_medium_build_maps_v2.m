function tests=test_swsynth_medium_build_maps_v2
tests=functiontests(localfunctions);
end

function testHomogeneous2DIndependentOfFrequency(testCase)
cfg=compact2D();
grid=makeGrid2D(cfg);
m=swsynth.medium.buildMaps(grid,cfg.medium);
verifySize(testCase,m.cs_map_zx,[21 31]);
verifyEqual(testCase,m.cs_map_zx,2*ones(21,31));
verifyEqual(testCase,m.material_id_zx,zeros(21,31,"uint16"));
verifyEmpty(testCase,m.object_alpha_zx);
verifyFalse(testCase,isfield(m,"k_map_zx"));
verifyFalse(testCase,isfield(m,"frequency_hz"));
verifyEqual(testCase,m.output_convention,"maps(z,x)");
end

function testCircleMatchesLegacy2DMaps(testCase)
cfg=compact2D();
cfg.medium.objects={struct( ...
    "type","circle","cs_m_s",4.5, ...
    "center_xz_m",[.015 .01],"radius_m",.005,"edge_sigma_m",0)};
check2DAgainstLegacy(testCase,cfg);
end

function testSharpBilayerAndCircleMatchesLegacy(testCase)
cfg=compact2D();
cfg.medium.objects={
    struct("type","bilayer","cs_m_s",3.5, ...
        "normal_angle_rad",pi/4,"offset_m",.018,"edge_sigma_m",0)
    struct("type","circle","cs_m_s",4, ...
        "center_xz_m",[.02 .01],"radius_m",.004,"edge_sigma_m",0)
};
check2DAgainstLegacy(testCase,cfg);
end

function testCustomMaskMatchesLegacy(testCase)
cfg=compact2D();
grid=makeGrid2D(cfg);
mask=false(grid.spatial_size);
mask(3,8)=true;
cfg.medium.objects={struct("type","custom","cs_m_s",4, ...
    "mask_zx",mask,"edge_sigma_m",0)};
check2DAgainstLegacy(testCase,cfg);
end

function testCombineModesMatchLegacy(testCase)
for mode=["overlay","blend","max","min"]
    cfg=compact2D();
    cfg.medium.combine_mode=mode;
    cfg.medium.objects={
        struct("type","circle","cs_m_s",3, ...
            "center_xz_m",[.012 .01],"radius_m",.008,"edge_sigma_m",0)
        struct("type","circle","cs_m_s",4, ...
            "center_xz_m",[.02 .01],"radius_m",.008,"edge_sigma_m",0)
    };
    check2DAgainstLegacy(testCase,cfg);
end
end

function testSmoothCircleMatchesLegacyWhenToolboxAvailable(testCase)
if exist("imgaussfilt","file")~=2
    return;
end
cfg=compact2D();
cfg.medium.objects={struct("type","circle","cs_m_s",4, ...
    "center_xz_m",[.015 .01],"radius_m",.006,"edge_sigma_m",.001)};
check2DAgainstLegacy(testCase,cfg);
end

function testHomogeneous3DMatchesLegacy(testCase)
cfg=compact3D();
check3DAgainstLegacy(testCase,cfg);
end

function testVolumetricSphereMatchesLegacy(testCase)
cfg=compact3D();
cfg.medium.objects={struct( ...
    "type","sphere","center_xyz_m",[.003 .002 .002], ...
    "radius_m",.0011,"cs_m_s",3)};
check3DAgainstLegacy(testCase,cfg);
end

function testVolumetricBoxSlabMatchesLegacy(testCase)
cfg=compact3D();
cfg.medium.objects={
    struct("type","box","center_xyz_m",[.003 .002 .002], ...
        "size_xyz_m",[.002 .002 .002],"cs_m_s",3)
    struct("type","slab","normal_xyz",[0 0 1], ...
        "offset_m",.003,"cs_m_s",4)
};
check3DAgainstLegacy(testCase,cfg);
end

function testVolumetricCustomMaskMatchesLegacy(testCase)
cfg=compact3D();
mask=false(5,4,6);
mask(3,2,4)=true;
cfg.medium.objects={struct("type","custom", ...
    "mask_zyx",mask,"cs_m_s",4)};
check3DAgainstLegacy(testCase,cfg);
end

function testExplicitShiftedGridStillCorrect(testCase)
grid=swsynth.domain.buildGrid(struct("geometry","2d", ...
    "x_m",[-.02 -.01 0],"z_m",[.01 .02 .03]));
medium=struct("cs_m_s",2,"objects",{{ ...
    struct("type","circle","center_xz_m",[-.01 .02], ...
    "radius_m",.001,"cs_m_s",3)}});
m=swsynth.medium.buildMaps(grid,medium);
verifyEqual(testCase,m.cs_map_zx(2,2),3);
verifyEqual(testCase,m.cs_map_zx(1,1),2);
verifyEqual(testCase,m.x_m,grid.x_m);
end

function testDensityIsMetadataNotShearSpeed(testCase)
cfg=compact2D();g=makeGrid2D(cfg);
a=swsynth.medium.buildMaps(g,cfg.medium);
cfg.medium.density_kg_m3=1000;
b=swsynth.medium.buildMaps(g,cfg.medium);
verifyEqual(testCase,b.cs_map_zx,a.cs_map_zx);
verifyEqual(testCase,b.density_kg_m3,1000);
end

function testRejectFrequencyInMedium(testCase)
cfg=compact2D();
cfg.medium.frequency_hz=500;
verifyError(testCase, ...
    @() swsynth.medium.buildMaps(makeGrid2D(cfg),cfg.medium), ...
    "swsynth:MediumCannotOwnFrequency");
end

function testRejectInvalidShearSpeed(testCase)
cfg=compact2D();
cfg.medium.background_cs_m_s=-2;
verifyError(testCase, ...
    @() swsynth.medium.buildMaps(makeGrid2D(cfg),cfg.medium), ...
    "swsynth:InvalidMediumSpeed");
end

function testRejectCustomMaskSize(testCase)
cfg=compact2D();
cfg.medium.objects={struct("type","custom","cs_m_s",3, ...
    "mask_zx",true(2,2),"edge_sigma_m",0)};
verifyError(testCase, ...
    @() swsynth.medium.buildMaps(makeGrid2D(cfg),cfg.medium), ...
    "swsynth:CustomMaskSizeMismatch");
end

function testReject3DNonOverlayCombineMode(testCase)
cfg=compact3D();
cfg.medium.combine_mode="blend";
grid=makeGrid3D(cfg);
verifyError(testCase, ...
    @() swsynth.medium.buildMaps(grid,cfg.medium), ...
    "swsynth:InvalidMediumCombineMode");
end

function check2DAgainstLegacy(tc,cfg)
grid=makeGrid2D(cfg);
actual=swsynth.medium.buildMaps(grid,cfg.medium);
legacy=swsynth.buildMediumMaps(cfg);
verifyEqual(tc,actual.x_m,legacy.x_m);
verifyEqual(tc,actual.z_m,legacy.z_m);
verifyEqual(tc,actual.cs_map_zx,legacy.cs_map_zx,"AbsTol",1e-13);
verifyEqual(tc,actual.material_id_zx,legacy.material_id_zx);
verifyEqual(tc,numel(actual.object_alpha_zx),numel(legacy.object_alpha_zx));
for i=1:numel(actual.object_alpha_zx)
    verifyEqual(tc,actual.object_alpha_zx{i}, ...
        legacy.object_alpha_zx{i},"AbsTol",1e-13);
end
end

function check3DAgainstLegacy(tc,cfg)
grid=makeGrid3D(cfg);
actual=swsynth.medium.buildMaps(grid,cfg.medium);
legacy=swsynth.buildMediumMaps3D(cfg);
verifyEqual(tc,actual.x_m,legacy.x_m);
verifyEqual(tc,actual.y_m,legacy.y_m);
verifyEqual(tc,actual.z_m,legacy.z_m);
verifyEqual(tc,actual.cs_map_zyx,legacy.cs_map_zyx);
verifyEqual(tc,actual.material_id_zyx,legacy.material_id_zyx);
for i=1:numel(actual.object_alpha_zyx)
    verifyEqual(tc,actual.object_alpha_zyx{i},legacy.object_alpha_zyx{i});
end
verifyFalse(tc,isfield(actual,"k_map_zyx"));
end

function grid=makeGrid2D(cfg)
r=cfg.domain;r.geometry="2d";
grid=swsynth.domain.buildGrid(r);
end

function grid=makeGrid3D(cfg)
r=cfg.domain;r.geometry="volumetric3d";
grid=swsynth.domain.buildGrid(r);
end

function cfg=compact2D()
cfg=swsynth.defaultConfig();
cfg.domain.Lx_m=.03;cfg.domain.Lz_m=.02;
cfg.domain.dx_m=.001;cfg.domain.dz_m=.001;
cfg.medium.background_cs_m_s=2;
cfg.wavefield.frequency_hz=500;
end

function cfg=compact3D()
cfg=swsynth.defaultConfig3D();
cfg.domain.Lx_m=.005;cfg.domain.Ly_m=.003;cfg.domain.Lz_m=.004;
cfg.domain.dx_m=.001;cfg.domain.dy_m=.001;cfg.domain.dz_m=.001;
cfg.medium.background_cs_m_s=2;
cfg.execution.use_parallel=false;
end
