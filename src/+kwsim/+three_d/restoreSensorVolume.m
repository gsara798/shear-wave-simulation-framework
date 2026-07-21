function volume_zyxt = restoreSensorVolume(sensor_values, sensor_metadata)
%RESTORESENSORVOLUME Restore binary-mask sensor data to a public 3D volume.
%
% Input
% -----
% sensor_values:
%   Numeric array with shape [sensor_point, time].
%
% sensor_metadata:
%   Metadata returned by kwsim.three_d.buildSensor. The required fields are:
%       size_xyz   = [Nx_roi, Ny_roi, Nz_roi]
%       point_count
%
% Output
% ------
% volume_zyxt:
%   Sensor ROI with public orientation [Nz_roi, Ny_roi, Nx_roi, Nt].
%
% k-Wave returns binary-mask sensor points in MATLAB linear-index order.
% For the cuboidal sensor used by the 3D foundation, this corresponds to
% x varying fastest, followed by y and then z.

arguments
    sensor_values {mustBeNumeric}
    sensor_metadata struct
end

required_fields = [
    "size_xyz"
    "point_count"
];

for field_name = required_fields.'
    if ~isfield(sensor_metadata, field_name)
        error("kwsim:Invalid3DSensorMetadata", ...
            "sensor_metadata is missing required field '%s'.", ...
            field_name);
    end
end

if ndims(sensor_values) > 2
    error("kwsim:Invalid3DSensorData", ...
        "sensor_values must have shape [sensor_point,time].");
end

size_xyz = double(sensor_metadata.size_xyz);

if ~(isnumeric(size_xyz) && numel(size_xyz) == 3 && ...
        all(isfinite(size_xyz)) && ...
        all(size_xyz == fix(size_xyz)) && ...
        all(size_xyz > 0))
    error("kwsim:Invalid3DSensorMetadata", ...
        "sensor_metadata.size_xyz must contain three positive integers.");
end

size_xyz = reshape(size_xyz, 1, 3);
expected_point_count = prod(size_xyz);

if double(sensor_metadata.point_count) ~= expected_point_count
    error("kwsim:Invalid3DSensorMetadata", ...
        "sensor_metadata.point_count is inconsistent with size_xyz.");
end

actual_point_count = size(sensor_values, 1);

if actual_point_count ~= expected_point_count
    error("kwsim:Invalid3DSensorData", ...
        "Expected %d sensor points but received %d.", ...
        expected_point_count, actual_point_count);
end

time_count = size(sensor_values, 2);

% Internal k-Wave-compatible orientation:
% [Nx_roi, Ny_roi, Nz_roi, Nt]
volume_xyzt = reshape(sensor_values, ...
    size_xyz(1), ...
    size_xyz(2), ...
    size_xyz(3), ...
    time_count);

% Public project orientation:
% [Nz_roi, Ny_roi, Nx_roi, Nt]
volume_zyxt = permute(volume_xyzt, [3, 2, 1, 4]);

end
