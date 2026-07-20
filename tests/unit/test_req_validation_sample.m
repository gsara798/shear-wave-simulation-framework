function tests = test_req_validation_sample
%TEST_REQ_VALIDATION_SAMPLE Test common 2D/3D REQ validation input.

tests = functiontests(localfunctions);

end


function setupOnce(~)

repository_root = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repository_root, "src"));

end


function testCreatesNative2DSample(testCase)

result = synthetic2DResult();

sample = ...
    kwsim.req.createValidationSample(result);

verifyEqual(testCase, ...
    sample.source_dimension, ...
    2);

verifyEqual(testCase, ...
    sample.extraction.method, ...
    "native_2d");

verifyEqual(testCase, ...
    sample.wavefield_complex_zx, ...
    result.fields.displacement.axial_total_zx);

verifyEqual(testCase, ...
    sample.truth.cs_m_s_zx, ...
    result.truth.cs_m_s_zx);

verifyEqual(testCase, ...
    sample.orientation, ...
    "[Nz,Nx]");

verifyEqual(testCase, ...
    sample.units, ...
    "m");

end


function testCreatesCentral3DSample(testCase)

result = synthetic3DResult();

sample = ...
    kwsim.req.createValidationSample(result);

verifyEqual(testCase, ...
    sample.source_dimension, ...
    3);

verifyEqual(testCase, ...
    sample.extraction.y_index, ...
    4);

expected_wavefield = reshape( ...
    result.fields.displacement.z_total_zyx(:, 4, :), ...
    3, 4);

verifyEqual(testCase, ...
    sample.wavefield_complex_zx, ...
    expected_wavefield);

expected_truth = reshape( ...
    result.truth.cs_m_s_zyx(:, 4, :), ...
    3, 4);

verifyEqual(testCase, ...
    sample.truth.cs_m_s_zx, ...
    expected_truth);

verifyEqual(testCase, ...
    size(sample.wavefield_complex_zx), ...
    [3, 4]);

end


function testSupportsOlder3DVelocityResult(testCase)

result = synthetic3DResult();

frequency_hz = ...
    result.config_resolved.source.f0_hz;

velocity = ...
    result.fields.displacement.z_total_zyx .* ...
    (1i * 2*pi*frequency_hz);

result.fields = struct();

result.fields.harmonic_velocity = struct();
result.fields.harmonic_velocity.z_shear_zyx = ...
    velocity;

result.fields.harmonic_velocity.z_compression_zyx = ...
    zeros(size(velocity));

result.fields.frequency_hz = ...
    frequency_hz;

sample = ...
    kwsim.req.createValidationSample(result);

expected = reshape( ...
    velocity(:, 4, :), ...
    3, 4) / ...
    (1i * 2*pi*frequency_hz);

verifyEqual(testCase, ...
    sample.wavefield_complex_zx, ...
    expected, ...
    AbsTol=1e-14);

end


function testSavesValidationSample(testCase)

sample = struct();
sample.sample_schema_version = "1.0";
sample.wavefield_complex_zx = complex(ones(3, 4));

temporary_directory = string(tempname);
mkdir(temporary_directory);

cleanup = onCleanup( ...
    @() removeDirectory(temporary_directory));

paths = struct();
paths.data = temporary_directory;

sample_path = ...
    kwsim.req.saveValidationSample( ...
        sample, ...
        paths);

verifyTrue(testCase, ...
    isfile(sample_path));

loaded = load( ...
    sample_path, ...
    "req_validation_sample");

verifyEqual(testCase, ...
    loaded.req_validation_sample. ...
        sample_schema_version, ...
    "1.0");

clear cleanup

end


function result = synthetic2DResult()

Nz = 3;
Nx = 4;

field = complex( ...
    reshape(1:(Nz*Nx), Nz, Nx), ...
    0.25);

result = struct();
result.schema_version = "3.0";
result.dimension = 2;

result.axes = struct();
result.axes.x_m = (0:(Nx - 1)) * 0.5e-3;
result.axes.z_m = (0:(Nz - 1)) * 0.5e-3;
result.axes.f0_hz = 500;

result.fields = struct();
result.fields.displacement = struct();

result.fields.displacement.axial_total_zx = ...
    field;

result.fields.displacement.units = "m";
result.fields.displacement.phasor_convention = ...
    "u(t) = real{U exp(i 2*pi*f*t)}";

result.truth = struct();
result.truth.cs_m_s_zx = 2 * ones(Nz, Nx);
result.truth.rho_kg_m3_zx = 1000 * ones(Nz, Nx);
result.truth.material_id_zx = ones(Nz, Nx, "uint16");

result.config_resolved = struct();
result.config_resolved.source = struct("f0_hz", 500);

result.valid = true;

end


function result = synthetic3DResult()

Nz = 3;
Ny = 5;
Nx = 4;

x_m = (0:(Nx - 1)) * 0.5e-3;
y_m = (-2:2) * 0.5e-3;
z_m = (0:(Nz - 1)) * 0.5e-3;

[Z, Y, X] = ndgrid( ...
    1:Nz, ...
    1:Ny, ...
    1:Nx);

field = complex( ...
    Z + 10*Y + 100*X, ...
    0.5);

result = struct();
result.schema_version = "3.0";
result.dimension = 3;

result.axes = struct();
result.axes.x_m = x_m;
result.axes.y_m = y_m;
result.axes.z_m = z_m;

result.fields = struct();
result.fields.frequency_hz = 500;
result.fields.displacement = struct();

result.fields.displacement.z_total_zyx = ...
    field;

result.fields.displacement.units = "m";
result.fields.displacement.phasor_convention = ...
    "u(t) = real{U exp(i 2*pi*f*t)}";

result.truth = struct();

result.truth.cs_m_s_zyx = ...
    single(2 + zeros(Nz, Ny, Nx));

result.truth.rho_kg_m3_zyx = ...
    single(1000 + zeros(Nz, Ny, Nx));

result.truth.material_id_zyx = ...
    uint16(ones(Nz, Ny, Nx));

result.config_resolved = struct();

result.config_resolved.source = struct( ...
    "f0_hz", 500, ...
    "center_m_xyz", [0, 0.49e-3, 0]);

result.valid = true;

end


function removeDirectory(path)

if isfolder(path)
    rmdir(path, "s");
end

end
