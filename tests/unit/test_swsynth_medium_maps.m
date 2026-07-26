function tests = test_swsynth_medium_maps
%TEST_SWSYNTH_MEDIUM_MAPS Unit tests for synthetic material maps.

tests = functiontests(localfunctions);

end

function testHomogeneousMapsUsePublicZXOrientation(testCase)

cfg = swsynth.defaultConfig();
cfg.domain.Lx_m = 0.02;
cfg.domain.Lz_m = 0.03;
cfg.domain.dx_m = 0.001;
cfg.domain.dz_m = 0.002;
cfg.medium.background_cs_m_s = 2.5;
cfg.wavefield.frequency_hz = 500;

maps = swsynth.buildMediumMaps(cfg);

verifySize(testCase, maps.cs_map_zx, [16, 21]);
verifySize(testCase, maps.k_map_zx, [16, 21]);
verifyEqual(testCase, maps.cs_map_zx, 2.5 * ones(16, 21));
verifyEqual( ...
    testCase, ...
    maps.k_map_zx, ...
    (2*pi*500/2.5) * ones(16, 21), ...
    AbsTol=1e-12);
verifyEqual(testCase, maps.output_convention, "maps(z,x)");

end

function testCircleObjectCreatesExpectedCore(testCase)

cfg = swsynth.defaultConfig();
cfg.domain.Lx_m = 0.04;
cfg.domain.Lz_m = 0.04;
cfg.domain.dx_m = 0.001;
cfg.domain.dz_m = 0.001;
cfg.medium.background_cs_m_s = 2.0;
cfg.medium.objects = {
    struct( ...
        "type", "circle", ...
        "cs_m_s", 4.0, ...
        "center_xz_m", [0.02, 0.02], ...
        "radius_m", 0.005, ...
        "edge_sigma_m", 0)
};

maps = swsynth.buildMediumMaps(cfg);

[~, xIndex] = min(abs(maps.x_m - 0.02));
[~, zIndex] = min(abs(maps.z_m - 0.02));

verifyEqual(testCase, maps.cs_map_zx(zIndex, xIndex), 4.0);
verifyEqual(testCase, maps.material_id_zx(zIndex, xIndex), uint16(1));
verifyEqual(testCase, maps.cs_map_zx(1, 1), 2.0);
verifyEqual(testCase, maps.material_id_zx(1, 1), uint16(0));

end

function testCustomMaskUsesZXInputOrientation(testCase)

cfg = swsynth.defaultConfig();
cfg.domain.Lx_m = 0.003;
cfg.domain.Lz_m = 0.002;
cfg.domain.dx_m = 0.001;
cfg.domain.dz_m = 0.001;

maskZX = false(3, 4);
maskZX(2, 3) = true;

cfg.medium.objects = {
    struct( ...
        "type", "custom", ...
        "cs_m_s", 3.5, ...
        "mask_zx", maskZX, ...
        "edge_sigma_m", 0)
};

maps = swsynth.buildMediumMaps(cfg);

verifyEqual(testCase, maps.cs_map_zx(2, 3), 3.5);
verifyEqual(testCase, maps.material_id_zx(2, 3), uint16(1));
verifyEqual(testCase, maps.cs_map_zx(1, 1), 2.0);

end
