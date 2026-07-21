function tests = test_simulation_output_io
%TEST_SIMULATION_OUTPUT_IO Verify standardized simulation output handling.

tests = functiontests(localfunctions);

end


function setupOnce(~)

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));

end


function testCreatesExpectedDirectoryTree(testCase)

temporary_root = string(tempname);
cleanup = onCleanup(@() removeDirectory(temporary_root));

cfg = kwsim.three_d.defaultConfig();
cfg.output.directory = temporary_root;
cfg.output.run_name = "Test simulation";
cfg.output.append_timestamp = true;

timestamp = datetime( ...
    2026, 7, 19, 17, 32, 45);

paths = kwsim.io.createRunDirectory( ...
    cfg, ...
    Timestamp=timestamp);

verifyTrue(testCase, isfolder(paths.run));
verifyTrue(testCase, isfolder(paths.config));
verifyTrue(testCase, isfolder(paths.data));
verifyTrue(testCase, isfolder(paths.figures));

verifyTrue(testCase, endsWith( ...
    paths.run, ...
    "20260719_173245_test_simulation"));

end


function testRejectsExistingDirectoryWithoutOverwrite(testCase)

temporary_root = string(tempname);
cleanup = onCleanup(@() removeDirectory(temporary_root));

cfg = kwsim.three_d.defaultConfig();
cfg.output.directory = temporary_root;
cfg.output.run_name = "duplicate";
cfg.output.append_timestamp = false;
cfg.output.overwrite = false;

kwsim.io.createRunDirectory(cfg);

verifyError(testCase, ...
    @() kwsim.io.createRunDirectory(cfg), ...
    "kwsim:OutputDirectoryExists");

end


function testSavesFigureFiles(testCase)

temporary_root = string(tempname);
mkdir(temporary_root);

cleanup = onCleanup(@() removeDirectory(temporary_root));

figure_handle = figure("Visible", "off");
axes_handle = axes(figure_handle);
plot(axes_handle, 1:5, (1:5).^2);

saved = kwsim.io.saveFigure( ...
    figure_handle, ...
    temporary_root, ...
    "test_figure", ...
    SaveMatlabFigure=true);

verifyTrue(testCase, isfile(saved.png));
verifyTrue(testCase, isfile(saved.fig));

close(figure_handle);

end


function testSavesSimulationConfigurationsAndManifest(testCase)

temporary_root = string(tempname);
cleanup = onCleanup(@() removeDirectory(temporary_root));

requested_cfg = kwsim.three_d.defaultConfig();
requested_cfg.output.directory = temporary_root;
requested_cfg.output.run_name = "io_test";
requested_cfg.output.append_timestamp = false;

resolved_cfg = requested_cfg;
resolved_cfg.medium.cp_m_s = ...
    resolved_cfg.medium.cs_m_s * ...
    resolved_cfg.medium.reduced_cp_factor;

result = syntheticResult(resolved_cfg);

paths = kwsim.io.saveSimulationResult(result);

verifyTrue(testCase, isfile(fullfile( ...
    paths.config, "requested_config.mat")));

verifyTrue(testCase, isfile(fullfile( ...
    paths.config, "resolved_config.mat")));

verifyTrue(testCase, isfile(fullfile( ...
    paths.config, "resolved_config.json")));

verifyTrue(testCase, isfile(fullfile( ...
    paths.data, "result.mat")));

verifyTrue(testCase, isfile(fullfile( ...
    paths.data, "summary.mat")));

verifyTrue(testCase, isfile(paths.manifest));

manifest = fileread(paths.manifest);

verifyTrue(testCase, contains(manifest, ...
    "Scenario: homogeneous_directional_3d"));

verifyTrue(testCase, contains(manifest, ...
    "Frequency: 500 Hz"));

end


function result = syntheticResult(cfg)

result = struct();
result.dimension = 3;
result.config_requested = cfg;
result.config_resolved = cfg;
result.cfg = cfg;
result.runtime_s = 1.25;

result.metadata = struct();
result.metadata.elapsed_time_s = 1.25;
result.metadata.public_volume_size_zyx = [4, 3, 5];

result.provenance = struct();
result.provenance.solver = "pstdElastic3D";
result.provenance.kwave_root = "/tmp/k-wave";
result.provenance.solver_path = "/tmp/k-wave/pstdElastic3D.m";

result.fields = struct();
result.fields.harmonic_velocity = struct();
result.fields.harmonic_velocity.z_shear_zyx = ...
    complex(zeros(4, 3, 5, "single"));

result.truth = struct();
result.truth.cs_m_s_zyx = ...
    cfg.medium.cs_m_s * ones(4, 3, 5, "single");

end


function removeDirectory(path)

if isfolder(path)
    rmdir(path, "s");
end

end
