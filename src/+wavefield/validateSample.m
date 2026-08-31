function info = validateSample(sample)
%VALIDATESAMPLE Validate the backend-neutral wavefield_sample contract.
%
% This validator is intentionally backward-compatible with schema v1.0 2D
% samples while defining the volumetric extension used by future 3D
% backends.
%
% Supported spatial layouts:
%   2D: wavefield.data_zx(z,x), coordinates.array_order = "zx"
%   3D: wavefield.data_zyx(z,y,x), coordinates.array_order = "zyx"
%
% Existing 2D samples are not required to contain spatial_dimension or a
% measurement block. New builders should populate both fields explicitly.

arguments
    sample (1,1) struct
end

requiredTopLevel = [ ...
    "schema_name", ...
    "schema_version", ...
    "coordinates", ...
    "wavefield", ...
    "truth"];

for i = 1:numel(requiredTopLevel)
    requireField(sample, requiredTopLevel(i), "sample");
end

if string(sample.schema_name) ~= "wavefield_sample"
    error("wavefield:InvalidSchemaName", ...
        "sample.schema_name must be 'wavefield_sample'.");
end

dimension = resolveSpatialDimension(sample);

switch dimension
    case 2
        dataField = "data_zx";
        arrayOrder = "zx";
        coordinateNames = ["z_m", "x_m"];
        spacingNames = ["dz_m", "dx_m"];
        truthNames = [ ...
            "cs_map_zx", ...
            "k_map_zx", ...
            "material_id_zx", ...
            "valid_mask_zx"];
        expectedSize = [ ...
            numel(requireCoordinate(sample.coordinates, "z_m")), ...
            numel(requireCoordinate(sample.coordinates, "x_m"))];

    case 3
        dataField = "data_zyx";
        arrayOrder = "zyx";
        coordinateNames = ["z_m", "y_m", "x_m"];
        spacingNames = ["dz_m", "dy_m", "dx_m"];
        truthNames = [ ...
            "cs_map_zyx", ...
            "k_map_zyx", ...
            "material_id_zyx", ...
            "valid_mask_zyx"];
        expectedSize = [ ...
            numel(requireCoordinate(sample.coordinates, "z_m")), ...
            numel(requireCoordinate(sample.coordinates, "y_m")), ...
            numel(requireCoordinate(sample.coordinates, "x_m"))];

    otherwise
        error("wavefield:InvalidSpatialDimension", ...
            "Only spatial dimensions 2 and 3 are supported.");
end

for name = coordinateNames
    requireCoordinate(sample.coordinates, name);
end

for name = spacingNames
    requirePositiveScalar(sample.coordinates, name);
end

if isfield(sample.coordinates, "array_order") && ...
        string(sample.coordinates.array_order) ~= arrayOrder
    error("wavefield:InvalidArrayOrder", ...
        "A %dD wavefield sample must use coordinates.array_order='%s'.", ...
        dimension, arrayOrder);
end

requireField(sample.wavefield, dataField, "sample.wavefield");
data = sample.wavefield.(dataField);
assertSpatialSize(data, expectedSize, "sample.wavefield." + dataField);

for name = truthNames
    requireField(sample.truth, name, "sample.truth");
    assertSpatialSize(sample.truth.(name), expectedSize, ...
        "sample.truth." + name);
end

if isfield(sample, "measurement")
    validateMeasurement(sample.measurement);
end

info = struct();
info.spatial_dimension = dimension;
info.array_order = arrayOrder;
info.data_field = dataField;
info.expected_size = expectedSize;
info.is_volumetric = dimension == 3;

end

function dimension = resolveSpatialDimension(sample)

if isfield(sample, "spatial_dimension") && ~isempty(sample.spatial_dimension)
    dimension = double(sample.spatial_dimension);
elseif isfield(sample.wavefield, "data_zyx")
    dimension = 3;
elseif isfield(sample.wavefield, "data_zx")
    dimension = 2;
elseif isfield(sample.coordinates, "array_order")
    order = string(sample.coordinates.array_order);
    if order == "zyx"
        dimension = 3;
    elseif order == "zx"
        dimension = 2;
    else
        dimension = NaN;
    end
else
    dimension = NaN;
end

if ~isscalar(dimension) || ~isfinite(dimension) || ...
        ~ismember(dimension, [2, 3])
    error("wavefield:InvalidSpatialDimension", ...
        ["Unable to resolve a supported spatial dimension. " ...
         "Use spatial_dimension=2 or 3."]);
end

end

function value = requireCoordinate(coordinates, name)

requireField(coordinates, name, "sample.coordinates");
value = double(coordinates.(name));

if isempty(value) || ~isvector(value) || any(~isfinite(value(:)))
    error("wavefield:InvalidCoordinate", ...
        "sample.coordinates.%s must be a finite nonempty vector.", name);
end

end

function requirePositiveScalar(coordinates, name)

requireField(coordinates, name, "sample.coordinates");
value = double(coordinates.(name));

if ~isscalar(value) || ~isfinite(value) || value <= 0
    error("wavefield:InvalidSpacing", ...
        "sample.coordinates.%s must be a positive finite scalar.", name);
end

end

function assertSpatialSize(value, expectedSize, location)

actualSize = size(value);
actualSize(end+1:numel(expectedSize)) = 1;
actualSize = actualSize(1:numel(expectedSize));

if ~isequal(actualSize, expectedSize)
    error("wavefield:SpatialSizeMismatch", ...
        "%s has size [%s], expected [%s].", ...
        location, join(string(actualSize), " "), ...
        join(string(expectedSize), " "));
end

end

function validateMeasurement(measurement)

if ~isstruct(measurement) || ~isscalar(measurement)
    error("wavefield:InvalidMeasurement", ...
        "sample.measurement must be a scalar struct.");
end

if isfield(measurement, "axis_xyz") && ~isempty(measurement.axis_xyz)
    axisXYZ = double(measurement.axis_xyz(:));
    if numel(axisXYZ) ~= 3 || any(~isfinite(axisXYZ)) || norm(axisXYZ) <= eps
        error("wavefield:InvalidMeasurementAxis", ...
            "sample.measurement.axis_xyz must be a finite nonzero 3-vector.");
    end
end

end

function requireField(value, name, location)

if ~isfield(value, name)
    error("wavefield:MissingField", ...
        "%s.%s is required.", location, name);
end

end
