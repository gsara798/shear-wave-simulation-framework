function tests = test_homogeneous_3d_public_run
%TEST_HOMOGENEOUS_3D_PUBLIC_RUN Verify the public 3D harmonic pipeline.

tests = functiontests(localfunctions);

end


function setupOnce(testCase)

addpath(fullfile(pwd, "src"));
kwsim.io.locateKWave("");

testCase.TestData.cfg = compactConfig();

end


function testPublicRunReturnsComplexHarmonicVolumes(testCase)

cfg = testCase.TestData.cfg;

result = kwsim.three_d.run(cfg);

expected_size_zyx = [
    numel(result.axes.z_m), ...
    numel(result.axes.y_m), ...
    numel(result.axes.x_m)
];

expected_fields = [
    "x_compression_zyx"
    "x_shear_zyx"
    "y_compression_zyx"
    "y_shear_zyx"
    "z_compression_zyx"
    "z_shear_zyx"
];

verifyEqual(testCase, result.dimension, 3);

verifyEqual(testCase, ...
    result.config_requested, ...
    cfg);

verifyEqual(testCase, ...
    result.config_resolved, ...
    result.cfg);

verifyEqual(testCase, ...
    result.runtime_s, ...
    result.metadata.elapsed_time_s);

verifyGreaterThan(testCase, result.runtime_s, 0);

verifyEqual(testCase, result.axes.spatial_orientation, ...
    "[Nz,Ny,Nx]");

for field_name = expected_fields.'
    values = ...
        result.fields.harmonic_velocity.(field_name);

    verifyEqual(testCase, size(values), expected_size_zyx);
    verifyTrue(testCase, all(isfinite(values), "all"));
end

verifyGreaterThan(testCase, ...
    max(abs(result.fields.harmonic_velocity.z_shear_zyx), [], "all"), ...
    0);

verifyEqual(testCase, ...
    size(result.truth.cs_m_s_zyx), ...
    expected_size_zyx);

verifyEqual(testCase, ...
    result.truth.cs_m_s_zyx, ...
    single(cfg.medium.cs_m_s) * ...
        ones(expected_size_zyx, "single"));

verifyEqual(testCase, ...
    result.metadata.harmonic_extraction.method, ...
    "least_squares");

verifyFalse(testCase, isfield(result, "time_series"));

end


function testCanRetainNativeTimeSeries(testCase)

cfg = testCase.TestData.cfg;
cfg.output.save_time_series = true;

result = kwsim.three_d.run(cfg);

verifyTrue(testCase, isfield(result, "time_series"));
verifyTrue(testCase, ...
    isfield(result.time_series.sensor_data, "uz_split_s"));

verifyEqual(testCase, ...
    result.time_series.native_layout, ...
    "[sensor_point,time]");

end


function cfg = compactConfig()

cfg = kwsim.three_d.defaultConfig();

cfg.grid.Nx = 32;
cfg.grid.Ny = 24;
cfg.grid.Nz = 32;

cfg.source.ramp_cycles = 1;

cfg.time.settling_cycles = 1;
cfg.time.analysis_cycles = 2;
cfg.time.end_time_s = 8e-3;

cfg.source.boundary_margin_m = 2e-3;

cfg.sensor.source_buffer_m = 2e-3;
cfg.sensor.boundary_margin_m = 1.5e-3;

cfg.solver.pml_size_points = [8, 8, 8];

cfg.analysis.harmonic_method = "least_squares";
cfg.analysis.temporal_window = "none";
cfg.analysis.remove_mean = true;

end
