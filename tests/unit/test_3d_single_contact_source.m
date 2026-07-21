function tests = test_3d_single_contact_source
%TEST_3D_SINGLE_CONTACT_SOURCE Unit tests for the sparse disk source.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
kwsim.io.locateKWave('');
end

function testSourceMaskAndMetadata(testCase)
[cfg, kgrid] = resolvedConfigAndGrid();
[source, metadata] = ...
    kwsim.three_d.buildSingleContactSource(cfg, kgrid);

verifySize(testCase, source.u_mask, ...
    [cfg.grid.Nx, cfg.grid.Ny, cfg.grid.Nz]);

verifyEqual(testCase, ...
    nnz(source.u_mask), ...
    cfg.source.contact_node_count);

verifyEqual(testCase, ...
    metadata.contact_node_count, ...
    cfg.source.contact_node_count);

verifyEqual(testCase, ...
    metadata.center_index_xyz, ...
    cfg.source.center_index_xyz);

verifyEqual(testCase, source.u_mode, 'dirichlet');
end

function testDefaultSourceIsZPolarized(testCase)
[cfg, kgrid] = resolvedConfigAndGrid();
[source, metadata] = ...
    kwsim.three_d.buildSingleContactSource(cfg, kgrid);

verifyEqual(testCase, source.ux, ...
    zeros(size(source.ux), 'single'));

verifyEqual(testCase, source.uy, ...
    zeros(size(source.uy), 'single'));

verifyGreaterThan(testCase, max(abs(source.uz)), 0);

verifyEqual(testCase, ...
    metadata.polarization_xyz, [0, 0, 1]);

verifyEqual(testCase, ...
    metadata.nominal_propagation_xyz, [1, 0, 0]);

verifyEqual(testCase, ...
    dot(metadata.polarization_xyz, ...
        metadata.nominal_propagation_xyz), ...
    0, 'AbsTol', 1e-12);
end

function testContactOccupiesOneXPlane(testCase)
[cfg, kgrid] = resolvedConfigAndGrid();
[source, ~] = ...
    kwsim.three_d.buildSingleContactSource(cfg, kgrid);

[x_index, ~, ~] = ind2sub( ...
    size(source.u_mask), find(source.u_mask));

verifyEqual(testCase, ...
    unique(x_index), ...
    cfg.source.center_index_xyz(1));
end

function testSparseContactHasNoFaceAdjacentNodes(testCase)
[cfg, kgrid] = resolvedConfigAndGrid();
[source, ~] = ...
    kwsim.three_d.buildSingleContactSource(cfg, kgrid);

x_index = cfg.source.center_index_xyz(1);
contact_yz = squeeze(source.u_mask(x_index, :, :));

adjacent_y = ...
    contact_yz(1:end-1, :) & contact_yz(2:end, :);

adjacent_z = ...
    contact_yz(:, 1:end-1) & contact_yz(:, 2:end);

verifyFalse(testCase, any(adjacent_y, "all"));
verifyFalse(testCase, any(adjacent_z, "all"));
end

function testWaveformUsesResolvedTimeArray(testCase)
[cfg, kgrid] = resolvedConfigAndGrid();
[source, metadata] = ...
    kwsim.three_d.buildSingleContactSource(cfg, kgrid);

verifyEqual(testCase, ...
    numel(source.uz), numel(kgrid.t_array));

verifyEqual(testCase, ...
    metadata.t_s, double(kgrid.t_array(:).'));

verifyLessThanOrEqual(testCase, ...
    max(abs(double(source.uz))), ...
    cfg.source.velocity_amplitude_m_s * (1 + 10*eps));
end

function [cfg, kgrid] = resolvedConfigAndGrid()
cfg = kwsim.three_d.defaultConfig();
[cfg, ~] = kwsim.three_d.validateConfig(cfg);
[kgrid, cfg, ~] = kwsim.three_d.buildGrid(cfg);
end
