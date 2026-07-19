function tests = test_2d_output_io
%TEST_2D_OUTPUT_IO Verify standardized saving of a synthetic 2D result.

tests = functiontests(localfunctions);

end


function setupOnce(~)

root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root, "src"));

end


function testSavesStandardized2DOutput(testCase)

temporary_root = string(tempname);
cleanup = onCleanup(@() removeDirectory(temporary_root));

requested_cfg = kwsim.two_d.defaultConfig();

requested_cfg.output.enabled = true;
requested_cfg.output.directory = temporary_root;
requested_cfg.output.run_name = "synthetic_2d";
requested_cfg.output.append_timestamp = false;
requested_cfg.output.overwrite = false;

resolved_cfg = requested_cfg;
resolved_cfg.medium.cp_m_s = ...
    resolved_cfg.medium.cs_m_s * ...
    resolved_cfg.medium.reduced_cp_factor;

report = syntheticReport();
result = syntheticResult( ...
    requested_cfg, ...
    resolved_cfg, ...
    report);

paths = kwsim.io.saveSimulationResult(result);

validation_paths = kwsim.io.saveValidationReport( ...
    report, ...
    paths);

verifyTrue(testCase, isfolder(paths.config));
verifyTrue(testCase, isfolder(paths.data));
verifyTrue(testCase, isfolder(paths.figures));

verifyTrue(testCase, isfile(fullfile( ...
    paths.config, ...
    "requested_config.mat")));

verifyTrue(testCase, isfile(fullfile( ...
    paths.config, ...
    "resolved_config.mat")));

verifyTrue(testCase, isfile(fullfile( ...
    paths.config, ...
    "resolved_config.json")));

verifyTrue(testCase, isfile(fullfile( ...
    paths.data, ...
    "result.mat")));

verifyTrue(testCase, isfile(fullfile( ...
    paths.data, ...
    "summary.mat")));

verifyTrue(testCase, isfile(validation_paths.mat));
verifyTrue(testCase, isfile(validation_paths.summary));
verifyTrue(testCase, isfile(paths.manifest));

manifest = fileread(paths.manifest);

verifyTrue(testCase, contains(manifest, ...
    "Dimension: 2"));

verifyTrue(testCase, contains(manifest, ...
    "Size [Nx Nz]"));

verifyTrue(testCase, contains(manifest, ...
    "Scenario: homogeneous_directional"));

summary_text = fileread(validation_paths.summary);

verifyTrue(testCase, contains(summary_text, ...
    "Overall valid: 1"));

verifyTrue(testCase, contains(summary_text, ...
    "shear_speed_relative_error"));

end


function result = syntheticResult( ...
    requested_cfg, resolved_cfg, report)

result = struct();

result.schema_version = resolved_cfg.schema_version;
result.dimension = 2;

result.config_requested = requested_cfg;
result.config_resolved = resolved_cfg;

result.runtime_s = 1.25;

result.fields = struct();
result.fields.velocity = struct();

result.fields.velocity.axial_shear_zx = ...
    complex(zeros(8, 10, "single"));

result.fields.velocity.axial_compression_zx = ...
    complex(zeros(8, 10, "single"));

result.fields.velocity.lateral_shear_zx = ...
    complex(zeros(8, 10, "single"));

result.fields.velocity.lateral_compression_zx = ...
    complex(zeros(8, 10, "single"));

result.provenance = struct();
result.provenance.kwave_root = "/tmp/k-wave";
result.provenance.backend = "cpu";
result.provenance.data_cast = "single";

result.valid = report.valid;
result.diagnostics = report;

end


function report = syntheticReport()

check = struct();
check.name = "shear_speed_relative_error";
check.pass = true;
check.value = 0.01;
check.threshold = 0.02;
check.message = "Synthetic speed check.";

report = struct();
report.valid = true;
report.checks = check;
report.summary = ...
    "valid=1, cs estimate=2.0000 m/s";

end


function removeDirectory(path)

if isfolder(path)
    rmdir(path, "s");
end

end
