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
verifyEqual(testCase, sample.spatial_dimension, 2);
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

verifyEqual(testCase, sample.measurement.quantity, sample.wavefield.quantity);
verifyEqual(testCase, sample.measurement.component, sample.wavefield.component);

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
verifyEqual(testCase, wavefield.validateSample(sample).spatial_dimension, 2);

verifyTrue(testCase, isfield(sample, "metrics"));

verifyTrue( ...
    testCase, ...
    isfield(sample.metrics, "global_spectrum"));

verifyEqual( ...
    testCase, ...
    sample.metrics.global_spectrum, ...
    result.spectral_metrics);

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


function testProjected3DEikonalSamplePreservesEffectiveField(testCase)

cfg = compactEikonalConfig();

result = swsynth.run(cfg);
sample = result.sample;

effectiveXYZ = double(result.wavefield.directions_xyz);

verifyEqual(testCase, sample.spatial_dimension, 2);
verifyEqual( ...
    testCase, ...
    sample.directions.xyz, ...
    effectiveXYZ, ...
    AbsTol=1e-12);

verifyEqual( ...
    testCase, ...
    sample.directions.xyz(:,1), ...
    double(sample.directions.ux(:)), ...
    AbsTol=1e-12);

verifyEqual( ...
    testCase, ...
    sample.directions.xyz(:,2), ...
    double(sample.directions.uy(:)), ...
    AbsTol=1e-12);

verifyEqual( ...
    testCase, ...
    sample.directions.xyz(:,3), ...
    double(sample.directions.uz(:)), ...
    AbsTol=1e-12);

verifyEqual( ...
    testCase, ...
    sample.directions.retained_count, ...
    size(effectiveXYZ,1));

expectedInPlaneCount = ...
    nnz(abs(effectiveXYZ(:,2)) <= 1e-6);

verifyEqual( ...
    testCase, ...
    sample.directions.in_plane_count, ...
    expectedInPlaneCount);

verifyEqual( ...
    testCase, ...
    sample.directions.in_plane_fraction, ...
    expectedInPlaneCount / size(effectiveXYZ,1), ...
    AbsTol=1e-12);

verifyEqual( ...
    testCase, ...
    sample.requested_directions.xyz, ...
    [ ...
        double(result.requested_directions.ux(:)), ...
        double(result.requested_directions.uy(:)), ...
        double(result.requested_directions.uz(:))], ...
    AbsTol=1e-12);

verifyEqual( ...
    testCase, ...
    sample.excitation.weights, ...
    result.wavefield.weights);

verifyEqual( ...
    testCase, ...
    sample.excitation.phase_rad, ...
    result.wavefield.phase_rad);

verifyEqual( ...
    testCase, ...
    sample.excitation.amplitude, ...
    result.wavefield.amplitude);

verifyEqual( ...
    testCase, ...
    sample.excitation.polarization_xyz, ...
    result.wavefield.polarization_xyz);

verifyEqual( ...
    testCase, ...
    sample.excitation.polarization_z, ...
    result.wavefield.polarization_z);

verifyTrue( ...
    testCase, ...
    isfield(sample.propagation, "reference_cs_m_s"));

verifyTrue( ...
    testCase, ...
    isfield(sample.propagation, "diagnostics"));

verifyFalse(testCase, isfield(sample, "req"));

end


function testInvalidResultIsRejected(testCase)

invalid = struct();

verifyError( ...
    testCase, ...
    @() swsynth.buildWavefieldSample(invalid), ...
    "swsynth:InvalidWavefieldResult");

end


function cfg = compactEikonalConfig()

cfg = swsynth.defaultConfig();

cfg.seed = 41;

cfg.domain.Lx_m = 0.006;
cfg.domain.Lz_m = 0.006;
cfg.domain.dx_m = 0.001;
cfg.domain.dz_m = 0.001;

cfg.medium.background_cs_m_s = 2.0;

cfg.wavefield.frequency_hz = 100;

cfg.propagation.model = "projected3d_eikonal";
cfg.propagation.nonpropagating_policy = "filter";

cfg.directions.count = 4;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.support.type = "solid_angle_cap";
cfg.directions.support.axis_xyz = [-1, 0, 0];
cfg.directions.support.solid_angle_sr = pi;
cfg.directions.in_plane_count = 1;

cfg.polarization.model = "in_plane_sv";
cfg.sources.amplitude_jitter_fraction = 0;

cfg.execution.use_parallel = false;
cfg.noise.snr_db = Inf;

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
