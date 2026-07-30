function tests = test_swsynth_explicit_directions

tests = functiontests(localfunctions);

end

function testExplicitDirectionsAreNormalizedAndPreserved(testCase)

cfg = swsynth.defaultConfig();

cfg.directions.count = 3;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "explicit";
cfg.directions.explicit_xyz = [
    2, 0, 0
    0, 0, 4
    1, 0, 1];

[cfg,~] = swsynth.validateConfig(cfg);
directions = swsynth.generateDirections(cfg);

actual = double([
    directions.ux(:), ...
    directions.uy(:), ...
    directions.uz(:)]);

expected = [
    1, 0, 0
    0, 0, 1
    1/sqrt(2), 0, 1/sqrt(2)];

verifyEqual(testCase,actual,expected,"AbsTol",1e-7);
verifyEqual(testCase,directions.count,3);
verifyEqual(testCase,directions.in_plane_count,3);

end

function testExplicitCountMismatchFails(testCase)

cfg = swsynth.defaultConfig();

cfg.directions.count = 2;
cfg.directions.sampling_method = "explicit";
cfg.directions.explicit_xyz = [1,0,0];

verifyError( ...
    testCase, ...
    @() swsynth.validateConfig(cfg), ...
    "swsynth:ExplicitDirectionCountMismatch");

end

function testProjected3DEikonalAcceptsExplicitDirection(testCase)

cfg = swsynth.defaultConfig();

cfg.propagation.model = "projected3d_eikonal";
cfg.propagation.nonpropagating_policy = "filter";

cfg.directions.count = 1;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "explicit";
cfg.directions.explicit_xyz = [1,0,0];
cfg.directions.in_plane_count = 1;

[cfg,~] = swsynth.validateConfig(cfg);
result = swsynth.run(cfg);

actual = double([
    result.directions.ux(:), ...
    result.directions.uy(:), ...
    result.directions.uz(:)]);

verifyEqual(testCase,actual,[1,0,0],"AbsTol",1e-7);

end
