function tests = test_swsynth_finite_aperture
%TEST_SWSYNTH_FINITE_APERTURE Coherent line-aperture regression tests.

tests = functiontests(localfunctions);

end

function testPointGeometry(testCase)
aperture = swsynth.sources.buildCoherentAperture( ...
    [1, 2, 3], pointAperture());
verifyEqual(testCase, aperture.node_count, 1);
verifyEqual(testCase, aperture.node_xyz_m, [1, 2, 3]);
verifyEqual(testCase, aperture.node_offsets_m, 0);
verifyEqual(testCase, aperture.node_weights, 1);
end

function testFourMillimeterGeometry(testCase)
aperture = swsynth.sources.buildCoherentAperture( ...
    [0, 0, 0], lineAperture(0.004, [0, 0, 1]));
verifyEqual(testCase, aperture.node_count, 9);
verifyEqual(testCase, aperture.node_offsets_m, -0.002:0.0005:0.002, ...
    "AbsTol", 1e-15);
verifyEqual(testCase, aperture.realized_span_m, 0.004, "AbsTol", 1e-15);
verifyEqual(testCase, sum(aperture.node_weights), 1, "AbsTol", 1e-15);
verifyGreaterThanOrEqual(testCase, aperture.node_weights, ...
    zeros(size(aperture.node_weights)));
end

function testEightMillimeterGeometry(testCase)
aperture = swsynth.sources.buildCoherentAperture( ...
    [0, 0, 0], lineAperture(0.008, [0, 0, 1]));
verifyEqual(testCase, aperture.node_count, 17);
verifyEqual(testCase, aperture.node_offsets_m, -0.004:0.0005:0.004, ...
    "AbsTol", 1e-15);
end

function testArbitraryThreeDimensionalAxisAndCenterOfMass(testCase)
center = [0.2, -0.1, 0.7];
aperture = swsynth.sources.buildCoherentAperture( ...
    center, lineAperture(0.004, [1, 2, 3]));
weightedCenter = aperture.node_weights * aperture.node_xyz_m;
verifyEqual(testCase, weightedCenter, center, "AbsTol", 1e-14);
verifyGreaterThan(testCase, ...
    max(aperture.node_xyz_m(:,2)) - min(aperture.node_xyz_m(:,2)), 0);
verifyGreaterThan(testCase, ...
    max(aperture.node_xyz_m(:,3)) - min(aperture.node_xyz_m(:,3)), 0);
end

function testInvalidApertureConfigurations(testCase)
cfg = finiteConfig([1, 0, 0], 0.004);
cfg.sources.aperture.axis_xyz = [0, 0, 0];
verifyError(testCase, @() swsynth.validateConfig(cfg), ...
    "swsynth:InvalidVector");

cfg = finiteConfig([1, 0, 0], 0.004);
cfg.sources.aperture.node_spacing_m = 0;
verifyError(testCase, @() swsynth.validateConfig(cfg), ...
    "swsynth:InvalidPositiveScalar");

cfg = finiteConfig([1, 0, 0], 0.004);
cfg.sources.aperture.node_spacing_m = 0.0006;
verifyError(testCase, @() swsynth.validateConfig(cfg), ...
    "swsynth:UnrepresentableApertureDiscretization");

cfg = finiteConfig([1, 0, 0], 0.004);
cfg.sources.radiation.model = "constant_directional_polarization";
verifyError(testCase, @() swsynth.validateConfig(cfg), ...
    "swsynth:FiniteApertureRequiresPointForceSphericalWave");
end

function testPointBackwardCompatibility(testCase)
implicitCfg = baseConfig([1, 0, 0]);
explicitCfg = implicitCfg;
explicitCfg.sources.aperture = pointAperture();
implicitResult = swsynth.run(implicitCfg);
explicitResult = swsynth.run(explicitCfg);
verifyEqual(testCase, explicitResult.wavefield.U_zx, ...
    implicitResult.wavefield.U_zx);
verifyEqual(testCase, explicitResult.wavefield.weights, ...
    implicitResult.wavefield.weights);
verifyEqual(testCase, explicitResult.wavefield.phase_rad, ...
    implicitResult.wavefield.phase_rad);
end

function testSourceXFiniteApertureIsDeterministicAndAntisymmetric(testCase)
cfg = finiteConfig([1, 0, 0], 0.004);
first = swsynth.run(cfg);
second = swsynth.run(cfg);
verifyEqual(testCase, first.wavefield.U_zx, second.wavefield.U_zx);

z = first.coordinates.z_m;
[~, below] = min(abs(z - 0.004));
[~, center] = min(abs(z - 0.005));
[~, above] = min(abs(z - 0.006));
xIndex = numel(first.coordinates.x_m);
verifyEqual(testCase, first.wavefield.U_zx(center,xIndex), 0, ...
    "AbsTol", 2e-7);
verifyEqual(testCase, first.wavefield.U_zx(below,xIndex), ...
    -first.wavefield.U_zx(above,xIndex), "AbsTol", 2e-6);
verifyEqual(testCase, first.wavefield.sources.aperture_node_count, 9);
verifyEqual(testCase, first.sample.sources.aperture_node_count, 9);
end

function testSourceZFiniteApertureIsSymmetric(testCase)
result = swsynth.run(finiteConfig([0, 0, 1], 0.004));
z = result.coordinates.z_m;
[~, below] = min(abs(z - 0.004));
[~, above] = min(abs(z - 0.006));
xIndex = numel(result.coordinates.x_m);
verifyEqual(testCase, result.wavefield.U_zx(below,xIndex), ...
    result.wavefield.U_zx(above,xIndex), "AbsTol", 2e-6);
end

function testPointFourAndEightMillimeterFieldsDiffer(testCase)
point = swsynth.run(baseConfig([1, 0, 0]));
four = swsynth.run(finiteConfig([1, 0, 0], 0.004));
eight = swsynth.run(finiteConfig([1, 0, 0], 0.008));
pointShape = point.wavefield.U_zx / norm(point.wavefield.U_zx(:));
fourShape = four.wavefield.U_zx / norm(four.wavefield.U_zx(:));
eightShape = eight.wavefield.U_zx / norm(eight.wavefield.U_zx(:));
verifyGreaterThan(testCase, norm(pointShape(:) - fourShape(:)), 1e-4);
verifyGreaterThan(testCase, norm(fourShape(:) - eightShape(:)), 1e-4);
end

function testStraightRayNumericalSupportsFiniteAperture(testCase)
cfg = finiteConfig([1, 0, 0], 0.004);
cfg.propagation.phase_model = "straight_ray_numerical";
result = swsynth.run(cfg);
verifyTrue(testCase, all(isfinite(result.wavefield.U_zx), "all"));
verifyEqual(testCase, result.wavefield.sources.aperture_node_count, 9);
end

function testValidationConfigurationsRunAndExposeMetadata(testCase)
repositoryRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
configRoot = fullfile(repositoryRoot, "configs", "swsynth", ...
    "validation", "finite_point_force_aperture");
files = [ ...
    "source_x_point.json", ...
    "source_x_aperture_4mm.json", ...
    "source_x_aperture_8mm.json", ...
    "source_z_point.json", ...
    "source_z_aperture_4mm.json", ...
    "source_z_aperture_8mm.json"];
expectedCounts = [1, 9, 17, 1, 9, 17];
for index = 1:numel(files)
    cfg = jsondecode(fileread(fullfile(configRoot, files(index))));
    result = swsynth.run(cfg);
    verifyTrue(testCase, all(isfinite(result.wavefield.U_zx), "all"));
    verifyEqual(testCase, ...
        result.wavefield.sources.aperture_node_count, ...
        expectedCounts(index));
    verifyEqual(testCase, ...
        sum(result.wavefield.sources.aperture_node_weights), 1, ...
        "AbsTol", 1e-14);
end
end

function cfg = baseConfig(forceXYZ)
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
cfg.sources.radiation.force_direction_xyz = forceXYZ;
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;
end

function cfg = finiteConfig(forceXYZ, spanM)
cfg = baseConfig(forceXYZ);
cfg.sources.aperture = lineAperture(spanM, [0, 0, 1]);
end

function aperture = pointAperture()
aperture = struct("model", "point", "span_m", 0, ...
    "axis_xyz", [0, 0, 1], "node_spacing_m", 0.0005);
end

function aperture = lineAperture(spanM, axisXYZ)
aperture = struct("model", "line_segment", "span_m", spanM, ...
    "axis_xyz", axisXYZ, "node_spacing_m", 0.0005);
end
