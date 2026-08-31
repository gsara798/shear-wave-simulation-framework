function tests = test_swsynth_medium_maps_3d
%TEST_SWSYNTH_MEDIUM_MAPS_3D Tests for volumetric heterogeneous maps.

tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root, "src"));
end

function testHomogeneousMapsUseZYXContract(testCase)
cfg = compactConfig();
maps = swsynth.buildMediumMaps3D(cfg);
verifySize(testCase, maps.cs_map_zyx, [5 4 6]);
verifyEqual(testCase, maps.cs_map_zyx, 2*ones(5,4,6));
verifyEqual(testCase, maps.material_id_zyx, zeros(5,4,6,"uint16"));
verifyEqual(testCase, maps.output_convention, "maps(z,y,x)");
end

function testSphereCreatesVolumetricInclusion(testCase)
cfg = compactConfig();
cfg.medium.objects = {struct( ...
    "type", "sphere", ...
    "center_xyz_m", [0.003 0.002 0.002], ...
    "radius_m", 0.0011, ...
    "cs_m_s", 3.0)};
maps = swsynth.buildMediumMaps3D(cfg);
mask = maps.material_id_zyx == 1;
verifyGreaterThan(testCase, nnz(mask), 1);
verifyEqual(testCase, unique(maps.cs_map_zyx(mask)), 3.0);
verifyEqual(testCase, unique(maps.cs_map_zyx(~mask)), 2.0);
end

function testSlabCreatesPlanarInterface(testCase)
cfg = compactConfig();
cfg.medium.objects = {struct( ...
    "type", "slab", ...
    "normal_xyz", [0 0 1], ...
    "offset_m", 0.002, ...
    "cs_m_s", 3.0)};
maps = swsynth.buildMediumMaps3D(cfg);
verifyEqual(testCase, maps.cs_map_zyx(1,:,:), 2*ones(1,4,6));
verifyEqual(testCase, maps.cs_map_zyx(end,:,:), 3*ones(1,4,6));
end

function testCustomMaskMustMatchZYXSize(testCase)
cfg = compactConfig();
cfg.medium.objects = {struct( ...
    "type", "custom", ...
    "mask_zyx", true(2,2,2), ...
    "cs_m_s", 3.0)};
verifyError(testCase, @() swsynth.buildMediumMaps3D(cfg), ...
    "swsynth:Custom3DMaskSizeMismatch");
end

function cfg = compactConfig()
cfg = swsynth.defaultConfig3D();
cfg.domain.Lx_m = 0.005;
cfg.domain.Ly_m = 0.003;
cfg.domain.Lz_m = 0.004;
cfg.domain.dx_m = 0.001;
cfg.domain.dy_m = 0.001;
cfg.domain.dz_m = 0.001;
cfg.medium.background_cs_m_s = 2.0;
cfg.wavefield.frequency_hz = 500;
cfg.execution.use_parallel = false;
end
