function tests = test_3d_sensor
%TEST_3D_SENSOR Unit tests for the 3D analysis sensor.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
kwsim.io.locateKWave('');
end

function testSensorMaskMatchesResolvedROI(testCase)
cfg = resolvedConfigWithGrid();
[sensor, metadata] = kwsim.three_d.buildSensor(cfg);

verifySize(testCase, sensor.mask, ...
    [cfg.grid.Nx, cfg.grid.Ny, cfg.grid.Nz]);

verifyEqual(testCase, ...
    metadata.point_count, ...
    cfg.derived.sensor_points);

verifyEqual(testCase, ...
    metadata.size_xyz, ...
    cfg.derived.sensor_size_xyz);

verifyEqual(testCase, ...
    sensor.record, {'u_split_field'});

verifyEqual(testCase, ...
    sensor.record_start_index, ...
    cfg.time.record_start_index);
end

function testSensorUsesPublicOrientationMetadata(testCase)
cfg = resolvedConfigWithGrid();
[~, metadata] = kwsim.three_d.buildSensor(cfg);

verifySize(testCase, metadata.mask_zyx, ...
    [cfg.grid.Nz, cfg.grid.Ny, cfg.grid.Nx]);

verifyEqual(testCase, ...
    metadata.internal_orientation, "[Nx,Ny,Nz]");

verifyEqual(testCase, ...
    metadata.public_orientation, "[Nz,Ny,Nx]");
end

function testSensorDoesNotOverlapSource(testCase)
cfg = resolvedConfigWithGrid();
[sensor, ~] = kwsim.three_d.buildSensor(cfg);

source_x = cfg.source.center_index_xyz(1);

verifyFalse(testCase, ...
    any(sensor.mask(source_x, :, :), "all"));
end

function cfg = resolvedConfigWithGrid()
cfg = kwsim.three_d.defaultConfig();
[cfg, ~] = kwsim.three_d.validateConfig(cfg);
[~, cfg, ~] = kwsim.three_d.buildGrid(cfg);
end
