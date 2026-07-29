function tests = test_swsynth_phase_models
%TEST_SWSYNTH_PHASE_MODELS Wavefield-level phase-model tests.

tests = functiontests(localfunctions);

end

function testHomogeneousStraightRayMatchesLegacy(testCase)

cfg = smallHomogeneousConfig();

cfg.propagation.phase_model = "local_k_distance";
mapsLegacy = swsynth.buildMediumMaps(cfg);
directionsLegacy = swsynth.generateDirections(cfg);
legacy = swsynth.synthesizeWavefield2D( ...
    cfg, mapsLegacy, directionsLegacy);

cfg.propagation.phase_model = "straight_ray_numerical";
mapsStraight = swsynth.buildMediumMaps(cfg);
directionsStraight = swsynth.generateDirections(cfg);
straight = swsynth.synthesizeWavefield2D( ...
    cfg, mapsStraight, directionsStraight);

verifyEqual( ...
    testCase, ...
    straight.sources.x_m, ...
    legacy.sources.x_m, ...
    "AbsTol", 0);

verifyEqual( ...
    testCase, ...
    straight.sources.y_m, ...
    legacy.sources.y_m, ...
    "AbsTol", 0);

verifyEqual( ...
    testCase, ...
    straight.sources.z_m, ...
    legacy.sources.z_m, ...
    "AbsTol", 0);

verifyEqual(testCase, straight.weights, legacy.weights, "AbsTol", 0);
verifyEqual(testCase, straight.phase_rad, legacy.phase_rad, "AbsTol", 0);

difference = norm( ...
    straight.U_zx(:) - legacy.U_zx(:));

reference = max(norm(legacy.U_zx(:)), eps);
relativeDifference = difference / reference;

verifyLessThan(testCase, relativeDifference, 5e-5);
verifyEqual( ...
    testCase, ...
    straight.phase_model, ...
    "straight_ray_numerical");
verifyEqual(testCase, legacy.phase_model, "local_k_distance");

end

function testStraightRayWavefieldIsReproducible(testCase)

cfg = smallHomogeneousConfig();
cfg.propagation.phase_model = "straight_ray_numerical";

maps1 = swsynth.buildMediumMaps(cfg);
directions1 = swsynth.generateDirections(cfg);
result1 = swsynth.synthesizeWavefield2D(cfg, maps1, directions1);

maps2 = swsynth.buildMediumMaps(cfg);
directions2 = swsynth.generateDirections(cfg);
result2 = swsynth.synthesizeWavefield2D(cfg, maps2, directions2);

verifyEqual(testCase, result2.U_zx, result1.U_zx, "AbsTol", 0);
verifyEqual(testCase, result2.sources, result1.sources);
verifyEqual(testCase, result2.weights, result1.weights, "AbsTol", 0);

end

function testStraightRayProducesFiniteBilayerField(testCase)

cfg = smallHomogeneousConfig();
cfg.propagation.phase_model = "straight_ray_numerical";
cfg.medium.background_cs_m_s = 1.0;
cfg.medium.objects = {
    struct( ...
        "type", "bilayer", ...
        "cs_m_s", 3.0, ...
        "normal_angle_rad", 0, ...
        "offset_m", 0.005, ...
        "edge_sigma_m", 0)
};

maps = swsynth.buildMediumMaps(cfg);
directions = swsynth.generateDirections(cfg);
result = swsynth.synthesizeWavefield2D(cfg, maps, directions);

verifySize(testCase, result.U_zx, size(maps.cs_map_zx));
verifyTrue(testCase, all(isfinite(real(result.U_zx(:)))));
verifyTrue(testCase, all(isfinite(imag(result.U_zx(:)))));
verifyGreaterThan(testCase, max(abs(result.U_zx(:))), 0);

end

function testStraightRayRejectedForPlaneWave(testCase)

cfg = swsynth.defaultConfig();
cfg.propagation.model = "plane_wave";
cfg.propagation.phase_model = "straight_ray_numerical";

verifyError( ...
    testCase, ...
    @() swsynth.validateConfig(cfg), ...
    "swsynth:StraightRayRequiresSphericalWave");

end

function cfg = smallHomogeneousConfig()

cfg = swsynth.defaultConfig();

cfg.seed = 7301;
cfg.domain.Lx_m = 0.010;
cfg.domain.Lz_m = 0.010;
cfg.domain.dx_m = 0.001;
cfg.domain.dz_m = 0.001;

cfg.medium.background_cs_m_s = 2.0;
cfg.medium.objects = {};

cfg.wavefield.frequency_hz = 400;

cfg.directions.count = 8;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.require_in_plane = false;
cfg.directions.support.type = "full_sphere";

cfg.sources.amplitude_jitter_fraction = 0.05;
cfg.amplitude.geometric_decay_exponent = 0;
cfg.noise.snr_db = Inf;
cfg.execution.use_parallel = false;

end
