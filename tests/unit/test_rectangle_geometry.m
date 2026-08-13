function tests = test_rectangle_geometry
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'benchmarks'));
end

function testRectangleRasterizationAndMetadata(testCase)
cfg = kwsim.two_d.defaultConfig();
xmax = (cfg.grid.Nx-1)*cfg.grid.dx_m;
zmax = (cfg.grid.Nz-1)*cfg.grid.dz_m;
cfg.geometry.objects = kwsim.geometry.two_d.makeRectangleObject( ...
    [0.010, xmax, 0.020, zmax], 2, 3.05, 1000, "lower_right");
[maps, metadata] = kwsim.two_d.buildGeometry(cfg);
expected = ((0:cfg.grid.Nx-1)'*cfg.grid.dx_m >= 0.010) & ...
    ((0:cfg.grid.Nz-1)*cfg.grid.dz_m >= 0.020);
verifyEqual(testCase, maps.material_id_xz == 2, expected);
verifyEqual(testCase, unique(maps.cs_m_s_xz(expected)), 3.05);
verifyEqual(testCase, metadata.objects.requested_bounds_m_xz, ...
    [0.010, xmax, 0.020, zmax]);
verifyEqual(testCase, metadata.objects.realized_bounds_m_xz, ...
    [0.010, xmax, 0.020, zmax], AbsTol=1e-12);
end

function testCircleBehaviorIsUnchanged(testCase)
cfg = kwsim_benchmarks.circular_inclusion_2d.config();
[before, ~] = kwsim.two_d.buildGeometry(cfg);
circle = cfg.geometry.objects;
verifyTrue(testCase, isfield(circle, 'bounds_m_xz'));
verifyTrue(testCase, all(isnan(circle.bounds_m_xz)));
[after, metadata] = kwsim.two_d.buildGeometry(cfg);
verifyEqual(testCase, after.material_id_xz, before.material_id_xz);
verifyEqual(testCase, metadata.objects.type, "circle");
end

function testMalformedRectangleFailsClearly(testCase)
cfg = kwsim.two_d.defaultConfig();
object = kwsim.geometry.two_d.makeRectangleObject( ...
    [0.01 0.02 0.01 0.02], 2, 3, 1000);
object.bounds_m_xz = [0.02 0.01 0.01 0.02];
cfg.geometry.objects = object;
verifyError(testCase, @() kwsim.two_d.buildGeometry(cfg), ...
    'kwsim:InvalidRectangleBounds');
verifyError(testCase, @() kwsim.geometry.two_d.makeRectangleObject( ...
    [0.02 0.01 0.01 0.02], 2, 3, 1000), ...
    'kwsim:InvalidRectangleBounds');
end

function testOrderedOverwriteSemantics(testCase)
cfg = kwsim.two_d.defaultConfig();
r = kwsim.geometry.two_d.makeRectangleObject( ...
    [0.01 0.03 0.01 0.03], 2, 3, 1000);
c = kwsim.geometry.two_d.makeCircleObject( ...
    [0.02 0.02], 0.005, 3, 4, 1000);
cfg.geometry.objects = [r c];
[maps, ~] = kwsim.two_d.buildGeometry(cfg);
ix = round(0.02/cfg.grid.dx_m)+1;
iz = round(0.02/cfg.grid.dz_m)+1;
verifyEqual(testCase, maps.material_id_xz(ix, iz), uint16(3));
end
