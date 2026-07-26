function tests = test_swsynth_directions
%TEST_SWSYNTH_DIRECTIONS Unit tests for direction generation.

tests = functiontests(localfunctions);

end

function testTwoDimensionalDirectionsRemainInPlane(testCase)

cfg = swsynth.defaultConfig();
cfg.seed = 10;
cfg.directions.count = 32;
cfg.directions.space = "two_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.support.type = "full_circle";

directions = swsynth.generateDirections(cfg);

verifyEqual(testCase, size(directions.ux), [1, 32]);
verifyEqual(testCase, directions.uy, zeros(1, 32, "single"));
verifyEqual( ...
    testCase, ...
    double(directions.ux.^2 + directions.uz.^2), ...
    ones(1, 32), ...
    AbsTol=1e-6);

end

function testFibonacciSphereDirectionsAreUnitLength(testCase)

cfg = swsynth.defaultConfig();
cfg.directions.count = 64;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.support.type = "full_sphere";

directions = swsynth.generateDirections(cfg);

magnitudeSquared = double( ...
    directions.ux.^2 + ...
    directions.uy.^2 + ...
    directions.uz.^2);

verifyEqual(testCase, magnitudeSquared, ones(1, 64), AbsTol=1e-6);

end

function testDirectionGenerationIsReproducible(testCase)

cfg = swsynth.defaultConfig();
cfg.seed = 151;
cfg.directions.count = 24;
cfg.directions.sampling_method = "random";
cfg.directions.support.type = "cone";
cfg.directions.support.axis_xyz = [-1, 0, 0];
cfg.directions.support.half_angle_deg = 70;

first = swsynth.generateDirections(cfg);
second = swsynth.generateDirections(cfg);

verifyEqual(testCase, first.ux, second.ux);
verifyEqual(testCase, first.uy, second.uy);
verifyEqual(testCase, first.uz, second.uz);

end

function testRequiredPlaneDirectionIsInserted(testCase)

cfg = swsynth.defaultConfig();
cfg.seed = 9;
cfg.directions.count = 16;
cfg.directions.sampling_method = "fibonacci";
cfg.directions.support.type = "cone";
cfg.directions.support.axis_xyz = [-1, 0.3, 0.2];
cfg.directions.support.half_angle_deg = 90;
cfg.directions.require_in_plane = true;

directions = swsynth.generateDirections(cfg);
summary = swsynth.summarizePlaneIntersection(directions);

verifyTrue(testCase, summary.has_in_plane_direction);
verifyGreaterThanOrEqual(testCase, summary.count_in_plane, 1);

end
