function tests = test_3d_wavefield_sample_export
%TEST_3D_WAVEFIELD_SAMPLE_EXPORT Planar and volumetric 3D export contracts.

tests = functiontests(localfunctions);
end

function testPlanar3DResultExportsAs2DSample(testCase)
result = make3DResult(1);

sample = kwsim.samples.buildWavefieldSample(result);
info = wavefield.validateSample(sample);

verifyEqual(testCase,sample.spatial_dimension,2);
verifyEqual(testCase,string(sample.coordinates.array_order),"zx");
verifyEqual(testCase,size(sample.wavefield.data_zx),[4 5]);
verifyEqual(testCase,size(sample.truth.cs_map_zx),[4 5]);
verifyEqual(testCase,sample.propagation.source_dimension,3);
verifyEqual(testCase,string(sample.propagation.direction_space), ...
    "three_dimensional");
verifyEqual(testCase,string(sample.extraction.method), ...
    "native_3d_xz_sensor_plane");
verifyEqual(testCase,sample.coordinates.observation_y_m,1.5e-3, ...
    AbsTol=1e-12);
verifyEqual(testCase,info.spatial_dimension,2);
verifyFalse(testCase,info.is_volumetric);
end

function testVolumetric3DResultRemains3DSample(testCase)
result = make3DResult(3);

sample = kwsim.samples.buildWavefieldSample(result);
info = wavefield.validateSample(sample);

verifyEqual(testCase,sample.spatial_dimension,3);
verifyEqual(testCase,string(sample.coordinates.array_order),"zyx");
verifyEqual(testCase,size(sample.wavefield.data_zyx),[4 3 5]);
verifyEqual(testCase,size(sample.truth.cs_map_zyx),[4 3 5]);
verifyEqual(testCase,sample.propagation.source_dimension,3);
verifyEqual(testCase,info.spatial_dimension,3);
verifyTrue(testCase,info.is_volumetric);
end

function testPreflightReportsPlanarSampleBeforeSolver(testCase)
cfg = kwsim.three_d.defaultConfig();
cfg.sensor.save_full_volume = false;

[resolved,preflight] = kwsim.three_d.validateConfig(cfg);

verifyEqual(testCase,numel(resolved.sensor.y_indices),1);
verifyEqual(testCase,preflight.wavefield_sample.spatial_dimension,2);
verifyEqual(testCase,string(preflight.wavefield_sample.array_order),"zx");
verifyEqual(testCase,string(preflight.wavefield_sample.output_convention), ...
    "data_zx(z,x)");
verifyTrue(testCase,preflight.wavefield_sample.is_planar);
verifyEqual(testCase,preflight.wavefield_sample.source_dimension,3);
verifyTrue(testCase,isfinite(preflight.wavefield_sample.observation_y_m));
end

function result = make3DResult(yCount)
Nz = 4;
Nx = 5;
Ny = yCount;

field = complex(ones(Nz,Ny,Nx),0.25*ones(Nz,Ny,Nx));
cs = 2*ones(Nz,Ny,Nx);
rho = 1000*ones(Nz,Ny,Nx);
material = ones(Nz,Ny,Nx,'uint16');

result = struct();
result.schema_version = "3.0";
result.dimension = 3;
result.axes = struct( ...
    "x_m",(0:Nx-1)*0.5e-3, ...
    "y_m",1.5e-3 + (0:Ny-1)*0.5e-3, ...
    "z_m",(0:Nz-1)*0.5e-3);
result.fields = struct();
result.fields.frequency_hz = 500;
result.fields.displacement = struct( ...
    "z_total_zyx",field, ...
    "units","m", ...
    "phasor_convention","u(t) = real{U exp(i 2*pi*f*t)}");
result.truth = struct( ...
    "cs_m_s_zyx",cs, ...
    "rho_kg_m3_zyx",rho, ...
    "material_id_zyx",material);
result.config_resolved = struct();
result.config_resolved.dimension = 3;
result.config_resolved.scenario = "heterogeneous_field_regimes";
result.config_resolved.seed = 991001;
result.config_resolved.medium = struct("cs_m_s",2.0);
result.config_resolved.source = struct( ...
    "f0_hz",500, ...
    "vibrator_count",16);
result.config_resolved.sensor = struct( ...
    "x_indices",1:Nx, ...
    "y_indices",10:(9+Ny), ...
    "z_indices",1:Nz);
result.validation = struct("valid",true);
result.provenance = struct();
end
