function tests = test_circular_inclusion_geometry
%TEST_CIRCULAR_INCLUSION_GEOMETRY Unit tests for physical circle rasterization.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
end

function testReferenceCircleResolves(testCase)
cfg = circularFixture();
[resolved, preflight] = kwsim.two_d.validateConfig(cfg);
verifyTrue(testCase, preflight.valid);
verifyEqual(testCase, resolved.medium.cp_m_s, 30);
verifyLessThanOrEqual(testCase, ...
    resolved.geometry.resolved.objects(1).area_relative_error, 0.05);
end

function testMaterialMapsAreExact(testCase)
cfg = circularFixture();
[resolved, ~] = kwsim.two_d.validateConfig(cfg);
[maps, metadata] = kwsim.two_d.buildGeometry(resolved);
mask = maps.material_id_xz == 2;
verifyTrue(testCase, any(mask, 'all'));
verifyEqual(testCase, unique(maps.cs_m_s_xz(mask)), 3);
verifyEqual(testCase, unique(maps.rho_kg_m3_xz(mask)), 1020);
verifyEqual(testCase, metadata.object_count, 1);
verifyEqual(testCase, unique(maps.material_id_xz(~mask)), uint16(1));
end

function testRejectsSourceOverlap(testCase)
cfg = circularFixture();
source_z_m = 0.5*(cfg.grid.Nz - 1)*cfg.grid.dz_m;
cfg.geometry.minimum_boundary_clearance_m = 0;
cfg.geometry.require_objects_inside_sensor_roi = false;
cfg.geometry.objects = kwsim.geometry.two_d.makeCircleObject( ...
    [1.5e-3, source_z_m], 1e-3, 2, 3, 1020, "invalid_source_overlap");
verifyError(testCase, @() kwsim.two_d.validateConfig(cfg), ...
    'kwsim:InvalidConfiguration');
end

function testRejectsBoundaryOverlap(testCase)
cfg = circularFixture();
cfg.geometry.objects = kwsim.geometry.two_d.makeCircleObject( ...
    [1e-3, 20e-3], 2e-3, 2, 3, 1020, "invalid_boundary_overlap");
verifyError(testCase, @() kwsim.two_d.validateConfig(cfg), ...
    'kwsim:InvalidConfiguration');
end

function cfg = circularFixture()
cfg = kwsim.two_d.defaultConfig();
cfg.scenario = "circular_inclusion_unit_fixture";
cfg.grid.Nz = 95;
center_x_m = 0.5 * (cfg.grid.Nx - 1) * cfg.grid.dx_m;
center_z_m = 0.5 * (cfg.grid.Nz - 1) * cfg.grid.dz_m;
cfg.geometry.objects = kwsim.geometry.two_d.makeCircleObject( ...
    [center_x_m, center_z_m], 8e-3, 2, 3.0, 1020, "central_inclusion");
end
