function tests = test_swsynth_3d_req3d_regression
%TEST_SWSYNTH_3D_REQ3D_REGRESSION Compare framework 3D synthesis to REQ3D.
%
% This is an optional cross-repository integration test. Set REQ3D_ROOT to
% the local REQ3D repository root before running it. The normal framework
% unit-test suite does not depend on REQ3D.

tests = functiontests(localfunctions);

end

function setupOnce(testCase)

frameworkRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(frameworkRoot, "src"));

req3dRoot = string(getenv("REQ3D_ROOT"));
assumeFalse(testCase, strlength(req3dRoot) == 0, ...
    "REQ3D_ROOT is not set; skipping cross-repository regression.");
assumeTrue(testCase, isfolder(req3dRoot), ...
    "REQ3D_ROOT does not point to an existing directory.");

req3dSrc = fullfile(req3dRoot, "src");
assumeTrue(testCase, isfolder(req3dSrc), ...
    "REQ3D_ROOT/src was not found.");
addpath(req3dSrc);

testCase.TestData.req3dRoot = req3dRoot;

end

function testDeterministicFibonacciProjectedFieldMatchesREQ3D(testCase)

cfg = baseRegressionConfig();
cfg.polarization.model = "transverse_preferred";
cfg.sources.amplitude_jitter_fraction = 0;

[framework, Ulegacy, xLegacy, yLegacy, zLegacy, csLegacy, kLegacy, diagLegacy] = ...
    runMatchedPair(cfg, 'transverse');

verifyCommonOutputs( ...
    testCase, framework, Ulegacy, xLegacy, yLegacy, zLegacy, ...
    csLegacy, kLegacy, diagLegacy, 5e-6);

end

function testRandomTransverseFibonacciFieldMatchesREQ3D(testCase)

% Fibonacci directions consume no random draws after rng(seed), so the
% random-transverse polarization, amplitude jitter, phase, and noise-free
% synthesis streams can be compared directly across implementations.
cfg = baseRegressionConfig();
cfg.seed = 23;
cfg.directions.count = 9;
cfg.polarization.model = "transverse_random";
cfg.sources.amplitude_jitter_fraction = 0.10;

[framework, Ulegacy, xLegacy, yLegacy, zLegacy, csLegacy, kLegacy, diagLegacy] = ...
    runMatchedPair(cfg, 'random_transverse');

verifyCommonOutputs( ...
    testCase, framework, Ulegacy, xLegacy, yLegacy, zLegacy, ...
    csLegacy, kLegacy, diagLegacy, 8e-6);

verifyEqual(testCase, ...
    framework.wavefield.source_weights, ...
    diagLegacy.sources.w, ...
    AbsTol=2e-7);
verifyEqual(testCase, ...
    framework.wavefield.observed_weights, ...
    diagLegacy.sources.wMeasured, ...
    AbsTol=2e-7);

end

function cfg = baseRegressionConfig()

cfg = swsynth.defaultConfig3D();
cfg.seed = 11;
cfg.domain.Lx_m = 0.006;
cfg.domain.Ly_m = 0.005;
cfg.domain.Lz_m = 0.004;
cfg.domain.dx_m = 0.001;
cfg.domain.dy_m = 0.001;
cfg.domain.dz_m = 0.001;
cfg.wavefield.frequency_hz = 600;
cfg.wavefield.quantity = "velocity";
cfg.medium.background_cs_m_s = 2.0;
cfg.directions.count = 7;
cfg.directions.sampling_method = "fibonacci";
cfg.directions.space = "three_dimensional";
cfg.directions.support.type = "full_sphere";
cfg.measurement.axis_xyz = [0, 0, 1];
cfg.noise.snr_db = Inf;
cfg.execution.use_parallel = false;
cfg.execution.synthesis_batch_size = 4;

end

function [framework, Ulegacy, xLegacy, yLegacy, zLegacy, csLegacy, kLegacy, diagLegacy] = ...
        runMatchedPair(cfg, legacyPolarizationMode)

framework = swsynth.run3D(cfg);

legacyCfg = struct();
legacyCfg.Lx = cfg.domain.Lx_m;
legacyCfg.Ly = cfg.domain.Ly_m;
legacyCfg.Lz = cfg.domain.Lz_m;
legacyCfg.dx = cfg.domain.dx_m;
legacyCfg.dy = cfg.domain.dy_m;
legacyCfg.dz = cfg.domain.dz_m;
legacyCfg.f0 = cfg.wavefield.frequency_hz;
legacyCfg.cs_bg = cfg.medium.background_cs_m_s;
legacyCfg.Nwaves = cfg.directions.count;
legacyCfg.AmpJitter = cfg.sources.amplitude_jitter_fraction;
legacyCfg.Seed = cfg.seed;
legacyCfg.SNR = cfg.noise.snr_db;
legacyCfg.SourceSampling = 'full_sphere';
legacyCfg.AngularSamplingMethod = 'fibonacci';
legacyCfg.UseParfor = false;
legacyCfg.SynthesisBatchSize = cfg.execution.synthesis_batch_size;
legacyCfg.MeasurementMode = 'projected';
legacyCfg.MeasurementAxis = cfg.measurement.axis_xyz;
legacyCfg.PolarizationMode = legacyPolarizationMode;

[Ulegacy, xLegacy, yLegacy, zLegacy, csLegacy, kLegacy, diagLegacy] = ...
    req3d.simulate.simulate_plane_wave_3d(legacyCfg);

end

function verifyCommonOutputs( ...
        testCase, framework, Ulegacy, xLegacy, yLegacy, zLegacy, ...
        csLegacy, kLegacy, diagLegacy, fieldTolerance)

verifyEqual(testCase, framework.coordinates.x_m, xLegacy, AbsTol=1e-15);
verifyEqual(testCase, framework.coordinates.y_m, yLegacy, AbsTol=1e-15);
verifyEqual(testCase, framework.coordinates.z_m, zLegacy, AbsTol=1e-15);
verifyEqual(testCase, framework.truth.cs_map_zyx, csLegacy, AbsTol=1e-15);
verifyEqual(testCase, framework.truth.k_map_zyx, kLegacy, RelTol=1e-13);

frameworkDirs = [ ...
    double(framework.directions.ux(:)), ...
    double(framework.directions.uy(:)), ...
    double(framework.directions.uz(:))];
legacyDirs = [ ...
    double(diagLegacy.waveDirs.ux(:)), ...
    double(diagLegacy.waveDirs.uy(:)), ...
    double(diagLegacy.waveDirs.uz(:))];
verifyEqual(testCase, frameworkDirs, legacyDirs, AbsTol=2e-7);

verifyEqual(testCase, ...
    framework.wavefield.polarization_xyz, ...
    diagLegacy.polarizationVectors, ...
    AbsTol=2e-7);
verifyEqual(testCase, ...
    framework.wavefield.projection_weights, ...
    diagLegacy.projectionWeights, ...
    AbsTol=2e-7);

relativeFieldError = norm( ...
    framework.wavefield.U_zyx(:) - Ulegacy(:)) / ...
    max(norm(Ulegacy(:)), eps);

verifyLessThan(testCase, relativeFieldError, fieldTolerance, ...
    sprintf("Framework/REQ3D relative field error was %.3g.", ...
    relativeFieldError));

verifyEqual(testCase, framework.sample.spatial_dimension, 3);
verifyEqual(testCase, framework.sample.coordinates.array_order, "zyx");
verifyEqual(testCase, framework.sample.measurement.axis_xyz, [0, 0, 1]);

end
