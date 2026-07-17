function tests = test_homogeneous_3d_solver_smoke
%TEST_HOMOGENEOUS_3D_SOLVER_SMOKE Minimal pstdElastic3D integration test.
%
% This test verifies solver compatibility and numerical sanity. It is not
% yet a quantitative validation of shear-wave speed or polarization.

tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));

addpath(fullfile(root, 'src'));

kwsim.io.locateKWave('');
end

function testCompactHomogeneousRun(testCase)
cfg = compactConfig();

raw = kwsim.three_d.runRaw(cfg);

expected_fields = [
    "ux_split_p"
    "ux_split_s"
    "uy_split_p"
    "uy_split_s"
    "uz_split_p"
    "uz_split_s"
];

verifyEqual(testCase, ...
    string(fieldnames(raw.sensor_data)), ...
    expected_fields);

expected_size = [
    raw.cfg.derived.sensor_points, ...
    raw.cfg.time.recorded_samples
];

for field_name = expected_fields.'
    values = raw.sensor_data.(field_name);

    verifySize(testCase, values, expected_size);
    verifyTrue(testCase, all(isfinite(values), "all"));
end

maximum_z_shear = ...
    max(abs(raw.sensor_data.uz_split_s), [], "all");

verifyGreaterThan(testCase, maximum_z_shear, 0);

% This is deliberately broad. It only catches catastrophic numerical
% growth relative to the prescribed micrometre-per-second source.
maximum_all_fields = 0;

for field_name = expected_fields.'
    maximum_all_fields = max( ...
        maximum_all_fields, ...
        max(abs(raw.sensor_data.(field_name)), [], "all"));
end

verifyLessThan(testCase, maximum_all_fields, 1);

verifyGreaterThan(testCase, ...
    raw.metadata.elapsed_time_s, 0);

verifyEqual(testCase, ...
    raw.metadata.output.native_layout, ...
    "[sensor_point,time]");
end

function cfg = compactConfig()
cfg = kwsim.three_d.defaultConfig();

% Small physical grid for a fast solver compatibility test.
cfg.grid.Nx = 32;
cfg.grid.Ny = 24;
cfg.grid.Nz = 32;

% Preserve 8 points per shear wavelength:
% cs = 2 m/s, f0 = 500 Hz, lambda_s = 4 mm, spacing = 0.5 mm.
cfg.grid.dx_m = 0.5e-3;
cfg.grid.dy_m = 0.5e-3;
cfg.grid.dz_m = 0.5e-3;

cfg.grid.cfl = 0.20;

% Short continuous-wave run. One ramp cycle is sufficient for this smoke
% test; quantitative harmonic validation will use a longer simulation.
cfg.source.ramp_cycles = 1;
cfg.time.settling_cycles = 1;
cfg.time.analysis_cycles = 2;
cfg.time.end_time_s = 8e-3;

% Keep the source and sensor inside the compact physical domain.
cfg.source.boundary_margin_m = 2e-3;
cfg.sensor.source_buffer_m = 2e-3;
cfg.sensor.boundary_margin_m = 1.5e-3;

% Smaller exterior PML for this compact integration test.
cfg.solver.pml_size_points = [8, 8, 8];

cfg.execution.maximum_memory_bytes = 8e9;
end
