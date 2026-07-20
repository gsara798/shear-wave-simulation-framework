function tests = test_cli_configuration
%TEST_CLI_CONFIGURATION Test dimension-aware JSON configuration loading.

tests = functiontests(localfunctions);

end


function setupOnce(testCase)

repository_root = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repository_root, "src"));

testCase.TestData.repository_root = ...
    string(repository_root);

end


function testLoadsPartial2DConfiguration(testCase)

config_file = writeTemporaryJson(struct( ...
    "dimension", 2, ...
    "grid", struct("Nx", 80), ...
    "output", struct( ...
        "directory", "outputs/cli_test_2d")));

cleanup = onCleanup(@() deleteIfPresent(config_file));

[cfg, metadata] = ...
    kwsim.io.loadConfigJson(config_file);

verifyEqual(testCase, cfg.dimension, 2);
verifyEqual(testCase, cfg.grid.Nx, 80);

% Unspecified fields must come from the 2D defaults.
verifyEqual(testCase, cfg.grid.Nz, 96);
verifyEqual(testCase, cfg.medium.cs_m_s, 2.0);

verifyEqual(testCase, metadata.dimension, 2);

outcome = kwsim.cli.runConfig( ...
    config_file, ...
    DryRun=true);

verifyEqual(testCase, ...
    outcome.status, ...
    "dry_run_valid");

verifyEqual(testCase, ...
    outcome.dimension, ...
    2);

verifyTrue(testCase, ...
    startsWith( ...
        string(outcome.config_resolved.output.directory), ...
        testCase.TestData.repository_root));

clear cleanup

end


function testLoadsPartial3DConfiguration(testCase)

config_file = writeTemporaryJson(struct( ...
    "dimension", 3, ...
    "grid", struct( ...
        "Nx", 40, ...
        "Ny", 24, ...
        "Nz", 40), ...
    "output", struct( ...
        "directory", "outputs/cli_test_3d")));

cleanup = onCleanup(@() deleteIfPresent(config_file));

[cfg, metadata] = ...
    kwsim.io.loadConfigJson(config_file);

verifyEqual(testCase, cfg.dimension, 3);
verifyEqual(testCase, cfg.grid.Nx, 40);
verifyEqual(testCase, cfg.grid.Ny, 24);
verifyEqual(testCase, cfg.grid.Nz, 40);

verifyEqual(testCase, metadata.dimension, 3);

outcome = kwsim.cli.runConfig( ...
    config_file, ...
    DryRun=true);

verifyEqual(testCase, ...
    outcome.status, ...
    "dry_run_valid");

verifyEqual(testCase, ...
    outcome.dimension, ...
    3);

clear cleanup

end


function testRejectsUnknownConfigurationField(testCase)

config = struct();
config.dimension = 3;
config.grid = struct();
config.grid.Nxx = 32;

config_file = writeTemporaryJson(config);

cleanup = onCleanup(@() deleteIfPresent(config_file));

verifyError(testCase, ...
    @() kwsim.io.loadConfigJson(config_file), ...
    "kwsim:UnknownConfigField");

clear cleanup

end


function testRejectsMissingDimension(testCase)

config_file = writeTemporaryJson(struct( ...
    "scenario", "missing_dimension"));

cleanup = onCleanup(@() deleteIfPresent(config_file));

verifyError(testCase, ...
    @() kwsim.io.loadConfigJson(config_file), ...
    "kwsim:MissingConfigDimension");

clear cleanup

end


function config_file = writeTemporaryJson(config)

config_file = string(tempname) + ".json";

file_id = fopen(config_file, "w");

if file_id < 0
    error("Could not create temporary JSON file.");
end

cleanup = onCleanup(@() fclose(file_id));

fprintf(file_id, "%s", ...
    jsonencode(config, PrettyPrint=true));

clear cleanup

end


function deleteIfPresent(path)

if isfile(path)
    delete(path);
end

end
