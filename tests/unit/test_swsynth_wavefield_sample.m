function tests = test_swsynth_wavefield_sample
%TEST_SWSYNTH_WAVEFIELD_SAMPLE Tests for the generic sample contract.

tests = functiontests(localfunctions);

end

function testRunIncludesGenericWavefieldSample(testCase)

cfg = compactConfig();
result = swsynth.run(cfg);
sample = result.sample;

verifyEqual(testCase, sample.schema_name, "wavefield_sample");
verifyEqual(testCase, sample.schema_version, "1.0");
verifyEqual(testCase, sample.generator.name, "swsynth");
verifyEqual(testCase, sample.generator.backend, "fast_synthetic");

verifyEqual( ...
    testCase, ...
    sample.wavefield.data_zx, ...
    result.wavefield.U_zx);

verifyEqual(testCase, ...
    sample.wavefield.quantity, ...
    "displacement");

verifyEqual(testCase, ...
    sample.wavefield.units, ...
    "arbitrary_displacement");

verifyEqual(testCase, ...
    sample.wavefield.phasor_convention, ...
    "u(t) = real{U exp(i 2*pi*f*t)}");

verifyEqual( ...
    testCase, ...
    sample.truth.cs_map_zx, ...
    result.truth.cs_map_zx);

verifyEqual( ...
    testCase, ...
    sample.coordinates.array_order, ...
    "zx");

verifyTrue(testCase, sample.validation.valid);
verifyTrue(testCase, sample.validation.analysis_ready);

end

function testSampleTruthMapsMatchWavefieldDimensions(testCase)

result = swsynth.run(compactConfig());
sample = result.sample;

fieldSize = size(sample.wavefield.data_zx);

verifyEqual(testCase, size(sample.truth.cs_map_zx), fieldSize);
verifyEqual(testCase, size(sample.truth.k_map_zx), fieldSize);
verifyEqual(testCase, size(sample.truth.material_id_zx), fieldSize);
verifyEqual(testCase, size(sample.truth.valid_mask_zx), fieldSize);

end

function testSampleIsEstimatorNeutral(testCase)

result = swsynth.run(compactConfig());
sample = result.sample;

verifyFalse(testCase, isfield(sample, "req"));
verifyFalse(testCase, isfield(sample.validation, "req_ready"));
verifyTrue(testCase, isfield(sample.validation, "analysis_ready"));
verifyTrue(testCase, isfield(sample.wavefield, "data_zx"));

end

function testInvalidResultIsRejected(testCase)

invalid = struct();

verifyError( ...
    testCase, ...
    @() swsynth.buildWavefieldSample(invalid), ...
    "swsynth:InvalidWavefieldResult");

end

function cfg = compactConfig()

cfg = swsynth.defaultConfig();
cfg.seed = 31;
cfg.domain.Lx_m = 0.008;
cfg.domain.Lz_m = 0.006;
cfg.domain.dx_m = 0.001;
cfg.domain.dz_m = 0.001;
cfg.wavefield.frequency_hz = 100;
cfg.propagation.model = "plane_wave";
cfg.directions.count = 4;
cfg.directions.space = "two_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.support.type = "full_circle";
cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;

end
