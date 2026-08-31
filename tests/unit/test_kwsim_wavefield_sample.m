function tests = test_kwsim_wavefield_sample
%TEST_KWSIM_WAVEFIELD_SAMPLE Test the generic k-Wave sample adapter.

tests = functiontests(localfunctions);

end

function setupOnce(~)

repositoryRoot = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repositoryRoot, "src"));

end

function testCreatesGenericNative2DSample(testCase)

result = synthetic2DResult();

sample = kwsim.samples.buildWavefieldSample(result);

verifyEqual(testCase, sample.schema_name, "wavefield_sample");
verifyEqual(testCase, sample.schema_version, "1.0");
verifyEqual(testCase, sample.spatial_dimension, 2);
verifyEqual(testCase, sample.generator.name, "kwsim");
verifyEqual(testCase, sample.generator.backend, "full_wave_kwave");

verifyEqual( ...
    testCase, ...
    sample.wavefield.data_zx, ...
    result.fields.displacement.axial_total_zx);

verifyEqual(testCase, sample.wavefield.component, "axial_total");
verifyEqual(testCase, sample.wavefield.quantity, "displacement");
verifyEqual(testCase, sample.wavefield.units, "m");
verifyEqual(testCase, sample.measurement.component, "axial_total");
verifyEqual(testCase, sample.measurement.quantity, "displacement");
verifyEqual(testCase, sample.coordinates.array_order, "zx");
verifyEqual(testCase, sample.coordinates.observation_y_m, 0);

verifyEqual( ...
    testCase, ...
    sample.truth.cs_map_zx, ...
    result.truth.cs_m_s_zx);

verifyEqual( ...
    testCase, ...
    sample.truth.k_map_zx, ...
    2*pi*500 ./ result.truth.cs_m_s_zx);

verifyEqual(testCase, sample.extraction.method, "native_2d");
verifyTrue(testCase, sample.validation.valid);
verifyTrue(testCase, sample.validation.analysis_ready);
verifyEqual(testCase, wavefield.validateSample(sample).spatial_dimension, 2);

end

function testCreatesCentral3DSample(testCase)

result = synthetic3DResult();

sample = kwsim.samples.buildWavefieldSample(result);

expectedField = reshape( ...
    result.fields.displacement.z_total_zyx(:, 4, :), ...
    3, 4);

verifyEqual(testCase, sample.wavefield.data_zx, expectedField);
verifyEqual(testCase, sample.extraction.y_index, 4);
verifyEqual(testCase, sample.coordinates.observation_y_m, 0.5e-3);
verifyEqual(testCase, sample.spatial_dimension, 2);
verifyEqual(testCase, sample.propagation.source_dimension, 3);
verifyEqual(testCase, sample.propagation.direction_space, ...
    "three_dimensional");
verifySize(testCase, sample.wavefield.data_zx, [3, 4]);
verifyEqual(testCase, wavefield.validateSample(sample).spatial_dimension, 2);

end

function testSupportsVelocityQuantity(testCase)

result = synthetic2DResult();
frequencyHz = result.config_resolved.source.f0_hz;

result.fields.velocity = struct();
result.fields.velocity.axial_total_zx = ...
    1i*2*pi*frequencyHz .* ...
    result.fields.displacement.axial_total_zx;
result.fields.velocity.units = "m/s";
result.fields.velocity.phasor_convention = ...
    "u(t) = real{U exp(i 2*pi*f*t)}";

sample = kwsim.samples.buildWavefieldSample( ...
    result, ...
    Quantity="velocity");

verifyEqual(testCase, sample.wavefield.quantity, "velocity");
verifyEqual(testCase, sample.measurement.quantity, "velocity");
verifyEqual(testCase, sample.wavefield.units, "m/s");
verifyEqual( ...
    testCase, ...
    sample.wavefield.data_zx, ...
    result.fields.velocity.axial_total_zx);

end

function testSampleRemainsEstimatorNeutral(testCase)

sample = kwsim.samples.buildWavefieldSample( ...
    synthetic2DResult());

verifyFalse(testCase, isfield(sample, "req"));
verifyFalse(testCase, isfield(sample.validation, "req_ready"));
verifyTrue(testCase, isfield(sample.validation, "analysis_ready"));
verifyTrue(testCase, isfield(sample.wavefield, "data_zx"));

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
result.fields.displacement.axial_total_zx = field;
result.fields.displacement.units = "m";
result.fields.displacement.phasor_convention = ...
    "u(t) = real{U exp(i 2*pi*f*t)}";

result.truth = struct();
result.truth.cs_m_s_zx = 2 * ones(Nz, Nx);
result.truth.rho_kg_m3_zx = 1000 * ones(Nz, Nx);
result.truth.material_id_zx = ones(Nz, Nx, "uint16");

result.config_resolved = struct();
result.config_resolved.scenario = "synthetic_2d_test";
result.config_resolved.seed = 101;
result.config_resolved.source = struct("f0_hz", 500);
result.config_resolved.medium = struct("cs_m_s", 2.0);

result.valid = true;
result.provenance = struct("run_id", "run_2d");

end

function result = synthetic3DResult()

Nz = 3;
Ny = 5;
Nx = 4;

xM = (0:(Nx - 1)) * 0.5e-3;
yM = (-2:2) * 0.5e-3;
zM = (0:(Nz - 1)) * 0.5e-3;

[Z, Y, X] = ndgrid(1:Nz, 1:Ny, 1:Nx);

field = complex(Z + 10*Y + 100*X, 0.5);

result = struct();
result.schema_version = "3.0";
result.dimension = 3;

result.axes = struct();
result.axes.x_m = xM;
result.axes.y_m = yM;
result.axes.z_m = zM;
result.axes.f0_hz = 500;

result.fields = struct();
result.fields.displacement = struct();
result.fields.displacement.z_total_zyx = field;
result.fields.displacement.units = "m";
result.fields.displacement.phasor_convention = ...
    "u(t) = real{U exp(i 2*pi*f*t)}";

result.truth = struct();
result.truth.cs_m_s_zyx = 2 * ones(Nz, Ny, Nx);
result.truth.rho_kg_m3_zyx = 1000 * ones(Nz, Ny, Nx);
result.truth.material_id_zyx = ones(Nz, Ny, Nx, "uint16");

result.config_resolved = struct();
result.config_resolved.scenario = "synthetic_3d_test";
result.config_resolved.seed = 202;
result.config_resolved.source = struct( ...
    "f0_hz", 500, ...
    "center_m_xyz", [0, 0.5e-3, 0]);
result.config_resolved.medium = struct("cs_m_s", 2.0);

result.valid = true;
result.provenance = struct("run_id", "run_3d");

end
