function tests = test_swsynth_straight_ray_integration
%TEST_SWSYNTH_STRAIGHT_RAY_INTEGRATION Physical travel-time tests.

tests = functiontests(localfunctions);

end

function testHomogeneousOutOfPlaneRay(testCase)

cfg = swsynth.defaultConfig();
cfg.medium.background_cs_m_s = 2.5;

source = [0.000, 0.030, 0.010];
targets = [
    0.040, 0.000, 0.010
    0.030, 0.000, 0.040
];

[travelTime, diagnostics] = ...
    swsynth.integrateStraightRayTravelTime( ...
        cfg, source, targets);

distance = sqrt(sum((targets - source).^2, 2));
expected = distance / 2.5;

verifyEqual(testCase, travelTime, expected, "AbsTol", 1e-14);
verifyEqual(testCase, diagnostics.method, "homogeneous_exact");
verifyTrue(testCase, all(diagnostics.converged));

end

function testVerticalBilayerMatchesAnalyticTravelTime(testCase)

cfg = swsynth.defaultConfig();
cfg.medium.background_cs_m_s = 1.0;
cfg.medium.objects = {
    struct( ...
        "type", "bilayer", ...
        "cs_m_s", 3.0, ...
        "normal_angle_rad", 0, ...
        "offset_m", 0.020, ...
        "edge_sigma_m", 0)
};

source = [0.000, 0.030, 0.025];
target = [0.040, 0.000, 0.025];

[travelTime, diagnostics] = ...
    swsynth.integrateStraightRayTravelTime( ...
        cfg, source, target);

distance = norm(target - source);
expected = 0.5 * distance / 1.0 + ...
    0.5 * distance / 3.0;

verifyEqual(testCase, travelTime, expected, "AbsTol", 1e-13);
verifyEqual(testCase, diagnostics.method, "event_split_midpoint");
verifyEqual(testCase, diagnostics.segment_count, 2);

end

function testCircleMatchesAnalyticChordTravelTime(testCase)

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

source = [0.000, 0.030, 0.025];
target = [0.050, 0.000, 0.025];

travelTime = swsynth.integrateStraightRayTravelTime( ...
    cfg, source, target);

distance = norm(target - source);

outsideFraction = 0.8;
insideFraction = 0.2;

expected = ...
    outsideFraction * distance / 2.0 + ...
    insideFraction * distance / 4.0;

verifyEqual(testCase, travelTime, expected, "AbsTol", 1e-13);

end

function testBilayerAndCircleOverlayMatchesAnalyticSegments(testCase)

cfg = swsynth.defaultConfig();
cfg.medium.background_cs_m_s = 1.0;
cfg.medium.combine_mode = "overlay";

cfg.medium.objects = {
    struct( ...
        "type", "bilayer", ...
        "cs_m_s", 3.0, ...
        "normal_angle_rad", 0, ...
        "offset_m", 0.025, ...
        "edge_sigma_m", 0)
    struct( ...
        "type", "circle", ...
        "cs_m_s", 4.0, ...
        "center_xz_m", [0.035, 0.025], ...
        "radius_m", 0.005, ...
        "edge_sigma_m", 0)
};

source = [0.000, 0.030, 0.025];
target = [0.050, 0.000, 0.025];

[travelTime, diagnostics] = ...
    swsynth.integrateStraightRayTravelTime( ...
        cfg, source, target);

distance = norm(target - source);

expected = distance * ( ...
    0.5 / 1.0 + ...
    0.3 / 3.0 + ...
    0.2 / 4.0);

verifyEqual(testCase, travelTime, expected, "AbsTol", 1e-13);
verifyEqual(testCase, diagnostics.segment_count, 4);

end

function testTravelTimeIsContinuousAcrossBilayer(testCase)

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

source = [0.000, 0.020, 0.025];
epsilon = 1e-8;

targets = [
    0.030 - epsilon, 0.000, 0.025
    0.030 + epsilon, 0.000, 0.025
];

travelTime = swsynth.integrateStraightRayTravelTime( ...
    cfg, source, targets);

verifyLessThan(testCase, abs(diff(travelTime)), 1e-7);

end
