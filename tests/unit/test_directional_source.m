function tests = test_directional_source
%TEST_DIRECTIONAL_SOURCE Verify ramp, polarization, and contact sampling.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
kwsim.io.locateKWave();
end

function testSourceIsAxialRampedAndNonAdjacent(testCase)
cfg = kwsim.two_d.defaultConfig();
[cfg, ~] = kwsim.two_d.validateConfig(cfg);
[kgrid, cfg] = kwsim.two_d.buildGrid(cfg);
[source, metadata] = kwsim.two_d.buildSingleContactSource(cfg, kgrid);

verifyEqual(testCase, string(source.u_mode), "dirichlet");
verifyEqual(testCase, source.uy(1), single(0));
verifyEqual(testCase, metadata.polarization_xz, [0, 1]);
verifyGreaterThanOrEqual(testCase, ...
    metadata.contact_minimum_node_spacing_points, 2);

[~, z_index] = find(source.u_mask);
verifyGreaterThanOrEqual(testCase, min(diff(sort(z_index))), 2);
verifyFalse(testCase, any(contains(string(fieldnames(source)), "square")));
end
