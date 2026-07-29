function tests = test_swsynth_medium_evaluation
%TEST_SWSYNTH_MEDIUM_EVALUATION Pointwise medium evaluation tests.

tests = functiontests(localfunctions);

end

function testHomogeneousEvaluation(testCase)

cfg = swsynth.defaultConfig();
cfg.medium.background_cs_m_s = 2.5;

X = [0.001, 0.010, 0.040];
Z = [0.003, 0.025, 0.049];

[cs, materialId, alpha] = swsynth.evaluateMediumAtXZ(cfg, X, Z);

verifyEqual(testCase, cs, 2.5 * ones(size(X)));
verifyEqual(testCase, materialId, zeros(size(X), "uint16"));
verifyEmpty(testCase, alpha);

end

function testVerticalBilayerEvaluation(testCase)

cfg = swsynth.defaultConfig();
cfg.medium.background_cs_m_s = 1.0;
cfg.medium.objects = {
    struct( ...
        "type", "bilayer", ...
        "cs_m_s", 3.0, ...
        "normal_angle_rad", 0, ...
        "offset_m", 0.030, ...
        "edge_sigma_m", 0)
};

X = [0.010, 0.030, 0.031, 0.045];
Z = 0.025 * ones(size(X));

[cs, materialId] = swsynth.evaluateMediumAtXZ(cfg, X, Z);

verifyEqual(testCase, cs, [1, 1, 3, 3]);
verifyEqual( ...
    testCase, ...
    materialId, ...
    uint16([0, 0, 1, 1]));

end

function testCircleEvaluation(testCase)

cfg = swsynth.defaultConfig();
cfg.medium.background_cs_m_s = 2.0;
cfg.medium.objects = {
    struct( ...
        "type", "circle", ...
        "cs_m_s", 4.0, ...
        "center_xz_m", [0.025, 0.025], ...
        "radius_m", 0.005, ...
        "edge_sigma_m", 0)
};

X = [0.010, 0.025, 0.030, 0.031];
Z = [0.025, 0.025, 0.025, 0.025];

[cs, materialId] = swsynth.evaluateMediumAtXZ(cfg, X, Z);

verifyEqual(testCase, cs, [2, 4, 4, 2]);
verifyEqual( ...
    testCase, ...
    materialId, ...
    uint16([0, 1, 1, 0]));

end

function testBuildMediumMapsUsesSameSharpEvaluation(testCase)

cfg = swsynth.defaultConfig();
cfg.domain.Lx_m = 0.02;
cfg.domain.Lz_m = 0.02;
cfg.domain.dx_m = 0.001;
cfg.domain.dz_m = 0.001;
cfg.medium.background_cs_m_s = 1.5;

cfg.medium.objects = {
    struct( ...
        "type", "bilayer", ...
        "cs_m_s", 2.5, ...
        "normal_angle_rad", pi/4, ...
        "offset_m", 0.014, ...
        "edge_sigma_m", 0)
    struct( ...
        "type", "circle", ...
        "cs_m_s", 3.5, ...
        "center_xz_m", [0.014, 0.012], ...
        "radius_m", 0.003, ...
        "edge_sigma_m", 0)
};

maps = swsynth.buildMediumMaps(cfg);
[X, Z] = ndgrid(maps.x_m, maps.z_m);

[csXZ, materialIdXZ, alphaXZ] = ...
    swsynth.evaluateMediumAtXZ(cfg, X, Z);

verifyEqual( ...
    testCase, ...
    maps.cs_map_zx, ...
    csXZ.', ...
    "AbsTol", 1e-12);

verifyEqual( ...
    testCase, ...
    maps.material_id_zx, ...
    materialIdXZ.');

verifyNumElements(testCase, alphaXZ, 2);
verifyEqual(testCase, maps.object_alpha_zx{1}, alphaXZ{1}.');
verifyEqual(testCase, maps.object_alpha_zx{2}, alphaXZ{2}.');

end

function testNonzeroEdgeSigmaIsRejectedPointwise(testCase)

cfg = swsynth.defaultConfig();
cfg.medium.objects = {
    struct( ...
        "type", "circle", ...
        "cs_m_s", 3.0, ...
        "center_xz_m", [0.025, 0.025], ...
        "radius_m", 0.005, ...
        "edge_sigma_m", 0.001)
};

verifyError( ...
    testCase, ...
    @() swsynth.evaluateMediumAtXZ(cfg, 0.025, 0.025), ...
    "swsynth:PointEvaluationRequiresSharpEdges");

end
