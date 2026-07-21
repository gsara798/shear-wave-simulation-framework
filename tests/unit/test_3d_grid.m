function tests = test_3d_grid
%TEST_3D_GRID Unit tests for the 3D k-Wave grid builder.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
kwsim.io.locateKWave('');
end

function testGridDimensionsAndSpacing(testCase)
cfg = resolvedDefaultConfig();
[kgrid, resolved, metadata] = kwsim.three_d.buildGrid(cfg);

verifyEqual(testCase, kgrid.Nx, cfg.grid.Nx);
verifyEqual(testCase, kgrid.Ny, cfg.grid.Ny);
verifyEqual(testCase, kgrid.Nz, cfg.grid.Nz);

verifyEqual(testCase, kgrid.dx, cfg.grid.dx_m);
verifyEqual(testCase, kgrid.dy, cfg.grid.dy_m);
verifyEqual(testCase, kgrid.dz, cfg.grid.dz_m);

verifyEqual(testCase, metadata.grid_size_xyz, ...
    [cfg.grid.Nx, cfg.grid.Ny, cfg.grid.Nz]);

verifyGreaterThan(testCase, resolved.time.dt_s, 0);
verifyGreaterThan(testCase, resolved.time.Nt, 1);
end

function testAutomaticTimeIncludesAnalysisWindow(testCase)
cfg = resolvedDefaultConfig();
[~, resolved, metadata] = kwsim.three_d.buildGrid(cfg);

required_analysis_s = ...
    cfg.time.analysis_cycles / cfg.source.f0_hz;

actual_recorded_s = ...
    metadata.t_record_s(end) - metadata.t_record_s(1);

verifyGreaterThanOrEqual(testCase, ...
    actual_recorded_s + resolved.time.dt_s, ...
    required_analysis_s);
end

function testExplicitEndTimeIsRespected(testCase)
cfg = kwsim.three_d.defaultConfig();
cfg.time.end_time_s = 0.050;
[cfg, ~] = kwsim.three_d.validateConfig(cfg);

[~, resolved, metadata] = kwsim.three_d.buildGrid(cfg);

verifyEqual(testCase, ...
    resolved.time.end_time_s_resolved, ...
    0.050, 'AbsTol', 1e-12);

verifyLessThanOrEqual(testCase, ...
    abs(metadata.end_time_s - 0.050), ...
    resolved.time.dt_s);
end

function cfg = resolvedDefaultConfig()
cfg = kwsim.three_d.defaultConfig();
[cfg, ~] = kwsim.three_d.validateConfig(cfg);
end
