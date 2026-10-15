function tests = test_swsynth_point_force_radiation
%TEST_SWSYNTH_POINT_FORCE_RADIATION Point-force shear radiation tests.

tests = functiontests(localfunctions);

end

function testAnalyticSourceXAndSourceZProjection(testCase)

source = [0, 0, 0];
points = [ ...
    1, 0, 0; ...
    0, 0, 1; ...
    1, 0, 1];

sourceX = projection(source, points, [1, 0, 0]);
sourceZ = projection(source, points, [0, 0, 1]);

verifyEqual(testCase, sourceX, [0; 0; -0.5], "AbsTol", 1e-14);
verifyEqual(testCase, sourceZ, [1; 0; 0.5], "AbsTol", 1e-14);

end

function testSourceXUzNodalLineAndSignChange(testCase)

source = [0, 0, 0];
points = [ ...
    1, 0, -1; ...
    1, 0, 0; ...
    1, 0, 1];

values = projection(source, points, [1, 0, 0]);

verifyGreaterThan(testCase, values(1), 0);
verifyEqual(testCase, values(2), 0, "AbsTol", 1e-14);
verifyLessThan(testCase, values(3), 0);

end

function testFullThreeDimensionalSourceGeometryIsRetained(testCase)

source = [0, 2, 0];
point = [1, 0, 1];
[value, polarizationXYZ, radialXYZ, distance] = ...
    swsynth.propagation.spherical.point_source.shear_far_field.computeShearProjection( ...
        source, point, [1, 0, 0], [0, 0, 1]);

verifyEqual(testCase, distance, sqrt(6), "AbsTol", 1e-14);
verifyEqual(testCase, radialXYZ, [1, -2, 1] / sqrt(6), ...
    "AbsTol", 1e-14);
verifyEqual(testCase, value, -1/6, "AbsTol", 1e-14);
verifyEqual(testCase, value, polarizationXYZ(3), "AbsTol", 1e-14);

end

function testGeneralProjectorAndTransversality(testCase)

source = [0.2, -0.4, 0.7];
points = [1.1, 0.3, -0.2; -0.5, 1.4, 2.0];
force = [1, 2, -3];
observed = [-2, 1, 4];

[actual, polarizationXYZ, radialXYZ] = ...
    swsynth.propagation.spherical.point_source.shear_far_field.computeShearProjection( ...
        source, points, force, observed);

force = force / norm(force);
observed = observed / norm(observed);
expected = zeros(size(actual));
for index = 1:size(points, 1)
    n = (points(index,:) - source);
    n = n / norm(n);
    expected(index) = observed * (eye(3) - n.' * n) * force.';
end

verifyEqual(testCase, actual, expected, "AbsTol", 1e-14);
verifyEqual(testCase, sum(radialXYZ .* polarizationXYZ, 2), ...
    zeros(size(actual)), "AbsTol", 1e-14);

end

function testArbitraryForceWithYComponent(testCase)

source = [-0.3, 0.7, 1.1];
point = [0.9, -0.2, 2.4];
force = [1, 1, 1];
observed = [0, 0, 1];
n = point - source;
n = n / norm(n);
forceUnit = force / norm(force);
expected = observed * (eye(3) - n.' * n) * forceUnit.';

actual = ...
    swsynth.propagation.spherical.point_source.shear_far_field.computeShearProjection( ...
        source, point, force, observed);

verifyEqual(testCase, actual, expected, "AbsTol", 1e-14);

end

function testNonzeroYChangesProjectionRelativeToCollapsedGeometry(testCase)

point = [1, 0, 1];
full3D = projection([0, 2, 0], point, [1, 0, 0]);
collapsed = projection([0, 0, 0], point, [1, 0, 0]);

verifyEqual(testCase, full3D, -1/6, "AbsTol", 1e-14);
verifyEqual(testCase, collapsed, -1/2, "AbsTol", 1e-14);
verifyNotEqual(testCase, full3D, collapsed);

end

function testSourceZUzIsSymmetricWithoutSignReversal(testCase)

source = [0, 0, 0];
points = [1, 0, -1; 1, 0, 0; 1, 0, 1];
values = projection(source, points, [0, 0, 1]);

verifyEqual(testCase, values(1), values(3), "AbsTol", 1e-14);
verifyEqual(testCase, values, [0.5; 1; 0.5], "AbsTol", 1e-14);
verifyGreaterThan(testCase, values, zeros(size(values)));

end

% Higher-level seeded source synthesis, coherent apertures and propagation
% are tested in test_swsynth_spherical_point_source_contribution_v2 and
% test_simcampaigns_swsynth_v2_integration (no V1 swsynth.run contract).

function values = projection(source, points, force)

values = ...
    swsynth.propagation.spherical.point_source.shear_far_field.computeShearProjection( ...
        source, points, force, [0, 0, 1]);

end

