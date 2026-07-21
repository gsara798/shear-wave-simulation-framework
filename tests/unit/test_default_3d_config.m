function tests = test_default_3d_config
%TEST_DEFAULT_3D_CONFIG Unit tests for the baseline 3D configuration.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
end

function testDefaultConfigurationValidates(testCase)
requested = kwsim.three_d.defaultConfig();
[resolved, preflight] = kwsim.three_d.validateConfig(requested);

verifyEqual(testCase, resolved.dimension, 3);

verifyTrue(testCase, isfield(resolved, "analysis"));
verifyEqual(testCase, ...
    resolved.analysis.harmonic_method, ...
    "least_squares");
verifyEqual(testCase, ...
    resolved.analysis.temporal_window, ...
    "none");
verifyTrue(testCase, resolved.analysis.remove_mean);
verifyEqual(testCase, preflight.public_orientation, "[Nz,Ny,Nx]");
verifyEqual(testCase, preflight.internal_orientation, "[Nx,Ny,Nz]");
verifyGreaterThanOrEqual(testCase, ...
    min(preflight.shear_ppw_xyz), ...
    requested.grid.minimum_shear_ppw);
end

function testDefaultPolarizationIsTransverse(testCase)
cfg = kwsim.three_d.defaultConfig();

verifyEqual(testCase, ...
    dot(cfg.source.polarization_xyz, ...
        cfg.source.target_direction_xyz), ...
    0, 'AbsTol', 1e-12);
end

function testDefaultMemoryEstimateIsWithinLimit(testCase)
cfg = kwsim.three_d.defaultConfig();
estimate = kwsim.three_d.estimateMemory(cfg);

verifyTrue(testCase, estimate.within_limit);
verifyGreaterThan(testCase, estimate.estimated_solver_bytes, 0);
verifyEqual(testCase, estimate.grid_size_xyz, ...
    [cfg.grid.Nx, cfg.grid.Ny, cfg.grid.Nz]);
end
