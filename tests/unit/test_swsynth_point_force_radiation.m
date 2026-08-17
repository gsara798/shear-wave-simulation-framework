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
    swsynth.propagation.spherical.computePointForceShearProjection( ...
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
    swsynth.propagation.spherical.computePointForceShearProjection( ...
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
    swsynth.propagation.spherical.computePointForceShearProjection( ...
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

function testDefaultAndExplicitLegacyModesAreIdentical(testCase)

cfgDefault = compactConfig();
cfgExplicit = cfgDefault;
cfgExplicit.sources.radiation.model = ...
    "constant_directional_polarization";

defaultResult = swsynth.run(cfgDefault);
explicitResult = swsynth.run(cfgExplicit);

verifyEqual(testCase, defaultResult.wavefield.U_zx, ...
    explicitResult.wavefield.U_zx);
verifyEqual(testCase, defaultResult.wavefield.weights, ...
    explicitResult.wavefield.weights);
verifyEqual(testCase, defaultResult.wavefield.phase_rad, ...
    explicitResult.wavefield.phase_rad);
verifyEqual(testCase, defaultResult.wavefield.amplitude, ...
    explicitResult.wavefield.amplitude);

end

function testPointForceRunIsDeterministicAndAuditable(testCase)

cfg = compactConfig();
cfg.sources.radiation.model = "point_force_shear_far_field";
cfg.sources.radiation.force_direction_xyz = [2, 0, 0];

first = swsynth.run(cfg);
second = swsynth.run(cfg);

verifyEqual(testCase, first.wavefield.U_zx, second.wavefield.U_zx);
verifyEqual(testCase, first.wavefield.sources.radiation_model, ...
    "point_force_shear_far_field");
verifyEqual(testCase, first.wavefield.sources.force_direction_xyz, ...
    [1, 0, 0], "AbsTol", 1e-14);
verifyEqual(testCase, first.wavefield.sources.observed_direction_xyz, ...
    [0, 0, 1]);
verifyEqual(testCase, first.sample.sources.radiation_model, ...
    "point_force_shear_far_field");
verifyEmpty(testCase, first.wavefield.polarization_z);

end

function testPointForceUsesSameSourceDrawsAndWaveform(testCase)

legacyCfg = compactConfig();
pointCfg = legacyCfg;
pointCfg.sources.radiation.model = "point_force_shear_far_field";

legacy = swsynth.run(legacyCfg);
pointForce = swsynth.run(pointCfg);

verifyEqual(testCase, pointForce.wavefield.sources.x_m, ...
    legacy.wavefield.sources.x_m);
verifyEqual(testCase, pointForce.wavefield.sources.y_m, ...
    legacy.wavefield.sources.y_m);
verifyEqual(testCase, pointForce.wavefield.sources.z_m, ...
    legacy.wavefield.sources.z_m);
verifyEqual(testCase, pointForce.wavefield.amplitude, ...
    legacy.wavefield.amplitude);
verifyEqual(testCase, pointForce.wavefield.phase_rad, ...
    legacy.wavefield.phase_rad);

end

function testIntegratedSourceXAndSourceZSymmetry(testCase)

sourceXCfg = singleSourceConfig([1, 0, 0]);
sourceZCfg = singleSourceConfig([0, 0, 1]);

sourceX = swsynth.run(sourceXCfg);
sourceZ = swsynth.run(sourceZCfg);

z = sourceX.coordinates.z_m;
[~, below] = min(abs(z - 0.004));
[~, center] = min(abs(z - 0.005));
[~, above] = min(abs(z - 0.006));
xIndex = numel(sourceX.coordinates.x_m);

verifyEqual(testCase, sourceX.wavefield.U_zx(center,xIndex), 0, ...
    "AbsTol", 1e-7);
verifyEqual(testCase, sourceX.wavefield.U_zx(below,xIndex), ...
    -sourceX.wavefield.U_zx(above,xIndex), "AbsTol", 1e-6);
verifyEqual(testCase, sourceZ.wavefield.U_zx(below,xIndex), ...
    sourceZ.wavefield.U_zx(above,xIndex), "AbsTol", 1e-6);

end

function testGeometricSpreadingIsIndependentOfRadiationSign(testCase)

cfgZero = singleSourceConfig([1, 0, 0]);
cfgOne = cfgZero;
cfgOne.amplitude.geometric_decay_exponent = 1;

zeroDecay = swsynth.run(cfgZero);
oneDecay = swsynth.run(cfgOne);

zIndex = 2;
xIndex = numel(zeroDecay.coordinates.x_m);
valueZero = zeroDecay.wavefield.U_zx(zIndex,xIndex);
valueOne = oneDecay.wavefield.U_zx(zIndex,xIndex);
sourceXYZ = [ ...
    zeroDecay.wavefield.sources.x_m, ...
    zeroDecay.wavefield.sources.y_m, ...
    zeroDecay.wavefield.sources.z_m];
observationXYZ = [ ...
    zeroDecay.coordinates.x_m(xIndex), ...
    zeroDecay.config.domain.observation_y_m, ...
    zeroDecay.coordinates.z_m(zIndex)];
distance = norm(observationXYZ - sourceXYZ);

verifyEqual(testCase, valueOne / valueZero, 1/distance, ...
    "RelTol", 2e-6);

end

function testPointForceRejectsNonSphericalPropagation(testCase)

cfg = compactConfig();
cfg.propagation.model = "plane_wave";
cfg.sources.radiation.model = "point_force_shear_far_field";

verifyError(testCase, @() swsynth.validateConfig(cfg), ...
    "swsynth:PointForceRadiationRequiresSphericalWave");

end

function testInvalidForceDirectionIsRejected(testCase)

cfg = compactConfig();
cfg.sources.radiation.model = "point_force_shear_far_field";
cfg.sources.radiation.force_direction_xyz = [0, 0, 0];

verifyError(testCase, @() swsynth.validateConfig(cfg), ...
    "swsynth:InvalidVector");

end

function testMalformedAndNonfiniteForceDirectionsAreRejected(testCase)

invalidValues = { [1, 0], [1, 0, 0, 0], [1, NaN, 0], [1, Inf, 0] };
for index = 1:numel(invalidValues)
    cfg = compactConfig();
    cfg.sources.radiation.force_direction_xyz = invalidValues{index};
    verifyError(testCase, @() swsynth.validateConfig(cfg), ...
        "swsynth:InvalidVector");
end

end

function testUnknownRadiationModelIsRejected(testCase)

cfg = compactConfig();
cfg.sources.radiation.model = "not_a_radiation_model";

verifyError(testCase, @() swsynth.validateConfig(cfg), ...
    "swsynth:InvalidChoice");

end

function testValidationConfigurationsRunOnTwoDimensionalPlane(testCase)

repositoryRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
configRoot = fullfile(repositoryRoot, "configs", "swsynth", ...
    "validation", "point_force_shear_radiation");
files = [ ...
    "source_x_uz.json", ...
    "source_z_uz.json", ...
    "source_x_nonzero_y_observe_uz.json"];

for index = 1:numel(files)
    cfg = jsondecode(fileread(fullfile(configRoot, files(index))));
    cfg.noise.snr_db = Inf;
    result = swsynth.run(cfg);
    verifyEqual(testCase, ndims(result.wavefield.U_zx), 2);
    verifyEqual(testCase, result.wavefield.output_convention, "U(z,x)");
    verifyTrue(testCase, all(isfinite(result.wavefield.U_zx), "all"));
end

verifyNotEqual(testCase, result.wavefield.sources.y_m, ...
    result.config.domain.observation_y_m);

end

function values = projection(source, points, force)

values = ...
    swsynth.propagation.spherical.computePointForceShearProjection( ...
        source, points, force, [0, 0, 1]);

end

function cfg = compactConfig()

cfg = swsynth.defaultConfig();
cfg.seed = 91;
cfg.domain.Lx_m = 0.012;
cfg.domain.Lz_m = 0.010;
cfg.domain.dx_m = 0.002;
cfg.domain.dz_m = 0.002;
cfg.medium.background_cs_m_s = 2.5;
cfg.wavefield.frequency_hz = 120;
cfg.propagation.model = "spherical_wave";
cfg.directions.count = 3;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "explicit";
cfg.directions.explicit_xyz = [ ...
    -1, 0, 0; ...
    -0.8, 0.6, 0; ...
    -0.8, 0, 0.6];
cfg.directions.support.type = "full_sphere";
cfg.sources.radius_range_m = [0.02, 0.025];
cfg.sources.amplitude_jitter_fraction = 0.05;
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;

end

function cfg = singleSourceConfig(forceDirectionXYZ)

cfg = swsynth.defaultConfig();
cfg.seed = 19;
cfg.domain.Lx_m = 0.01;
cfg.domain.Lz_m = 0.01;
cfg.domain.dx_m = 0.001;
cfg.domain.dz_m = 0.001;
cfg.medium.background_cs_m_s = 2.5;
cfg.wavefield.frequency_hz = 100;
cfg.propagation.model = "spherical_wave";
cfg.directions.count = 1;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "explicit";
cfg.directions.explicit_xyz = [-1, 0, 0];
cfg.directions.support.type = "full_sphere";
cfg.sources.radius_range_m = [0.02, 0.02];
cfg.sources.amplitude_jitter_fraction = 0;
cfg.sources.radiation.model = "point_force_shear_far_field";
cfg.sources.radiation.force_direction_xyz = forceDirectionXYZ;
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;

end
