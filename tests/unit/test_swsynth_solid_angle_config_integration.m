function tests = test_swsynth_solid_angle_config_integration
%TEST_SWSYNTH_SOLID_ANGLE_CONFIG_INTEGRATION Public config integration.

tests = functiontests(localfunctions);

end

function testFullSphereConfigGeneratesExactInPlaneCount(testCase)

cfg = swsynth.defaultConfig();

cfg.directions.count = 128;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.in_plane_count = 8;

cfg.directions.support.type = "solid_angle_cap";
cfg.directions.support.axis_xyz = [1, 0, 0];
cfg.directions.support.solid_angle_sr = 4*pi;

[cfg, report] = swsynth.validateConfig(cfg);
directions = swsynth.generateDirections(cfg);

verifyEqual(testCase, directions.count, 128);
verifyEqual(testCase, directions.in_plane_count, 8);
verifyEqual(testCase, directions.requested_in_plane_count, 8);

verifyEqual( ...
    testCase, ...
    nnz(abs(double(directions.uy)) <= 1e-12), ...
    8);

verifyLessThan(testCase, min(double(directions.ux)), 0);
verifyGreaterThan(testCase, max(double(directions.ux)), 0);

verifyEqual( ...
    testCase, ...
    directions.solid_angle_sr, ...
    4*pi, ...
    "AbsTol", 1e-12);

verifyEqual(testCase, report.in_plane_direction_count, 8);
verifyEqual(testCase, report.direction_support_type, "solid_angle_cap");

end

function testHemisphereConfigRestrictsDirectionsToAxisSide(testCase)

cfg = swsynth.defaultConfig();

cfg.directions.count = 64;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.in_plane_count = 4;

cfg.directions.support.type = "solid_angle_cap";
cfg.directions.support.axis_xyz = [1, 0, 0];
cfg.directions.support.solid_angle_sr = 2*pi;

[cfg, ~] = swsynth.validateConfig(cfg);
directions = swsynth.generateDirections(cfg);

verifyGreaterThanOrEqual( ...
    testCase, ...
    min(double(directions.ux)), ...
    -1e-6);

verifyEqual(testCase, directions.in_plane_count, 4);

verifyEqual( ...
    testCase, ...
    directions.support_half_angle_deg, ...
    90, ...
    "AbsTol", 1e-10);

end

function testSameConfigProducesSameDirections(testCase)

cfg = swsynth.defaultConfig();

cfg.seed = 901;
cfg.directions.count = 96;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.in_plane_count = 6;

cfg.directions.support.type = "solid_angle_cap";
cfg.directions.support.axis_xyz = [1, 2, -1];
cfg.directions.support.solid_angle_sr = 3*pi;

[cfg, ~] = swsynth.validateConfig(cfg);

directionsA = swsynth.generateDirections(cfg);
directionsB = swsynth.generateDirections(cfg);

verifyEqual(testCase, directionsB.ux, directionsA.ux, "AbsTol", 0);
verifyEqual(testCase, directionsB.uy, directionsA.uy, "AbsTol", 0);
verifyEqual(testCase, directionsB.uz, directionsA.uz, "AbsTol", 0);

end

function testLegacyRequireInPlaneResolvesToOne(testCase)

cfg = swsynth.defaultConfig();

cfg.directions.count = 32;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.require_in_plane = true;
cfg.directions.in_plane_count = 0;
cfg.directions.support.type = "full_sphere";

[cfg, report] = swsynth.validateConfig(cfg);
directions = swsynth.generateDirections(cfg);

verifyEqual(testCase, cfg.directions.in_plane_count, 1);
verifyEqual(testCase, report.in_plane_direction_count, 1);

verifyGreaterThanOrEqual( ...
    testCase, ...
    nnz(abs(double(directions.uy)) <= 1e-6), ...
    1);

end

function testMultipleInPlaneDirectionsRequireSolidAngleCap(testCase)

cfg = swsynth.defaultConfig();

cfg.directions.count = 32;
cfg.directions.in_plane_count = 4;
cfg.directions.support.type = "full_sphere";

verifyError( ...
    testCase, ...
    @() swsynth.validateConfig(cfg), ...
    "swsynth:InPlaneCountRequiresSolidAngleCap");

end

function testSolidAngleCapRequiresFibonacci(testCase)

cfg = swsynth.defaultConfig();

cfg.directions.count = 32;
cfg.directions.sampling_method = "random";
cfg.directions.support.type = "solid_angle_cap";
cfg.directions.support.solid_angle_sr = 2*pi;

verifyError( ...
    testCase, ...
    @() swsynth.validateConfig(cfg), ...
    "swsynth:SolidAngleCapRequiresFibonacci");

end

function testLegacyRequireInPlaneIsHarmlessInTwoDimensions(testCase)

cfg = swsynth.defaultConfig();

cfg.directions.count = 16;
cfg.directions.space = "two_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.require_in_plane = true;
cfg.directions.in_plane_count = 0;
cfg.directions.support.type = "full_circle";

[cfg, report] = swsynth.validateConfig(cfg);
directions = swsynth.generateDirections(cfg);

verifyEqual(testCase, cfg.directions.in_plane_count, 0);
verifyEqual(testCase, report.in_plane_direction_count, 0);

% All 2D directions are inherently in the x-z observation plane.
verifyEqual( ...
    testCase, ...
    double(directions.uy), ...
    zeros(size(double(directions.uy))), ...
    "AbsTol", 0);

end
