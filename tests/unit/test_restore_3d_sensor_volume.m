function tests = test_restore_3d_sensor_volume
%TEST_RESTORE_3D_SENSOR_VOLUME Verify binary-mask point-to-volume mapping.

tests = functiontests(localfunctions);

end


function testRestoresExpectedPublicOrientation(testCase)

nx = 3;
ny = 2;
nz = 4;
nt = 5;

% Construct synthetic data in the same internal ordering used by k-Wave:
% [Nx,Ny,Nz,Nt].
expected_xyzt = zeros(nx, ny, nz, nt);

for time_index = 1:nt
    for z_index = 1:nz
        for y_index = 1:ny
            for x_index = 1:nx
                expected_xyzt(x_index, y_index, z_index, time_index) = ...
                    1000*time_index + ...
                    100*z_index + ...
                    10*y_index + ...
                    x_index;
            end
        end
    end
end

sensor_values = reshape(expected_xyzt, nx*ny*nz, nt);

metadata = struct();
metadata.size_xyz = [nx, ny, nz];
metadata.point_count = nx * ny * nz;

actual_zyxt = kwsim.three_d.restoreSensorVolume( ...
    sensor_values, metadata);

expected_zyxt = permute(expected_xyzt, [3, 2, 1, 4]);

verifySize(testCase, actual_zyxt, [nz, ny, nx, nt]);
verifyEqual(testCase, actual_zyxt, expected_zyxt);

end


function testPreservesNumericClass(testCase)

sensor_values = single(reshape(1:48, 24, 2));

metadata = struct();
metadata.size_xyz = [3, 2, 4];
metadata.point_count = 24;

actual = kwsim.three_d.restoreSensorVolume( ...
    sensor_values, metadata);

verifyClass(testCase, actual, "single");

end


function testRejectsIncorrectPointCount(testCase)

sensor_values = zeros(23, 2);

metadata = struct();
metadata.size_xyz = [3, 2, 4];
metadata.point_count = 24;

verifyError(testCase, ...
    @() kwsim.three_d.restoreSensorVolume( ...
        sensor_values, metadata), ...
    "kwsim:Invalid3DSensorData");

end


function testRejectsInconsistentMetadata(testCase)

sensor_values = zeros(24, 2);

metadata = struct();
metadata.size_xyz = [3, 2, 4];
metadata.point_count = 23;

verifyError(testCase, ...
    @() kwsim.three_d.restoreSensorVolume( ...
        sensor_values, metadata), ...
    "kwsim:Invalid3DSensorMetadata");

end


function testRejectsMissingMetadataField(testCase)

sensor_values = zeros(24, 2);

metadata = struct();
metadata.size_xyz = [3, 2, 4];

verifyError(testCase, ...
    @() kwsim.three_d.restoreSensorVolume( ...
        sensor_values, metadata), ...
    "kwsim:Invalid3DSensorMetadata");

end
