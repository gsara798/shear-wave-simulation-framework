function tests = test_wavefield_sample_contract
%TEST_WAVEFIELD_SAMPLE_CONTRACT Backend-neutral 2D/3D sample validation.

tests = functiontests(localfunctions);

end

function testLegacy2DSampleRemainsValid(testCase)

sample = make2DSample();
info = wavefield.validateSample(sample);

verifyEqual(testCase, info.spatial_dimension, 2);
verifyEqual(testCase, info.array_order, "zx");
verifyEqual(testCase, info.data_field, "data_zx");
verifyFalse(testCase, info.is_volumetric);
verifyFalse(testCase, isfield(sample, "spatial_dimension"));

end

function testExplicit2DSampleWithMeasurementIsValid(testCase)

sample = make2DSample();
sample.spatial_dimension = 2;
sample.measurement = struct( ...
    "quantity", "displacement", ...
    "component", "uz", ...
    "axis_xyz", [0, 0, 1]);

info = wavefield.validateSample(sample);
verifyEqual(testCase, info.spatial_dimension, 2);

end

function testVolumetricZYXSampleIsValid(testCase)

sample = make3DSample();
info = wavefield.validateSample(sample);

verifyEqual(testCase, info.spatial_dimension, 3);
verifyEqual(testCase, info.array_order, "zyx");
verifyEqual(testCase, info.data_field, "data_zyx");
verifyEqual(testCase, info.expected_size, [4, 3, 5]);
verifyTrue(testCase, info.is_volumetric);

end

function testVolumetricSampleRequiresYCoordinate(testCase)

sample = make3DSample();
sample.coordinates = rmfield(sample.coordinates, "y_m");

verifyError(testCase, @() wavefield.validateSample(sample), ...
    "wavefield:MissingField");

end

function testVolumetricTruthMustMatchField(testCase)

sample = make3DSample();
sample.truth.k_map_zyx = zeros(4, 2, 5);

verifyError(testCase, @() wavefield.validateSample(sample), ...
    "wavefield:SpatialSizeMismatch");

end

function testDimensionAndArrayOrderMustAgree(testCase)

sample = make3DSample();
sample.coordinates.array_order = "xyz";

verifyError(testCase, @() wavefield.validateSample(sample), ...
    "wavefield:InvalidArrayOrder");

end

function testInvalidMeasurementAxisIsRejected(testCase)

sample = make3DSample();
sample.measurement.axis_xyz = [0, 0, 0];

verifyError(testCase, @() wavefield.validateSample(sample), ...
    "wavefield:InvalidMeasurementAxis");

end

function sample = make2DSample()

Nz = 4;
Nx = 5;

sample = struct();
sample.schema_name = "wavefield_sample";
sample.schema_version = "1.0";
sample.coordinates = struct( ...
    "x_m", (0:Nx-1)*1e-4, ...
    "z_m", (0:Nz-1)*2e-4, ...
    "dx_m", 1e-4, ...
    "dz_m", 2e-4, ...
    "array_order", "zx");
sample.wavefield = struct( ...
    "data_zx", complex(ones(Nz, Nx)));
sample.truth = struct( ...
    "cs_map_zx", 2*ones(Nz, Nx), ...
    "k_map_zx", 1000*ones(Nz, Nx), ...
    "material_id_zx", ones(Nz, Nx), ...
    "valid_mask_zx", true(Nz, Nx));

end

function sample = make3DSample()

Nz = 4;
Ny = 3;
Nx = 5;

sample = struct();
sample.schema_name = "wavefield_sample";
sample.schema_version = "1.0";
sample.spatial_dimension = 3;
sample.coordinates = struct( ...
    "x_m", (0:Nx-1)*1e-4, ...
    "y_m", (0:Ny-1)*1.5e-4, ...
    "z_m", (0:Nz-1)*2e-4, ...
    "dx_m", 1e-4, ...
    "dy_m", 1.5e-4, ...
    "dz_m", 2e-4, ...
    "array_order", "zyx");
sample.wavefield = struct( ...
    "data_zyx", complex(ones(Nz, Ny, Nx)));
sample.truth = struct( ...
    "cs_map_zyx", 2*ones(Nz, Ny, Nx), ...
    "k_map_zyx", 1000*ones(Nz, Ny, Nx), ...
    "material_id_zyx", ones(Nz, Ny, Nx), ...
    "valid_mask_zyx", true(Nz, Ny, Nx));
sample.measurement = struct( ...
    "quantity", "displacement", ...
    "component", "uz", ...
    "axis_xyz", [0, 0, 1]);

end
