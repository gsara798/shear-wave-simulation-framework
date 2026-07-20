function tests = test_circular_inclusion_output_io
%TEST_CIRCULAR_INCLUSION_OUTPUT_IO Verify standardized benchmark saving.

tests = functiontests(localfunctions);

end


function setupOnce(~)

root = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(root, "src"));
addpath(fullfile(root, "benchmarks"));

end


function testSavesIntoStandardDataDirectory(testCase)

temporary_root = string(tempname);
cleanup = onCleanup(@() removeDirectory(temporary_root));

cfg = kwsim.two_d.defaultConfig();

cfg.output.directory = temporary_root;
cfg.output.run_name = "circular_io_test";
cfg.output.append_timestamp = false;
cfg.output.overwrite = false;

paths = kwsim.io.createRunDirectory(cfg);

validation = syntheticValidation();

saved = ...
    kwsim_benchmarks.circular_inclusion_2d.saveResults( ...
        validation, ...
        paths);

verifyTrue(testCase, isfile(saved.mat_file));
verifyTrue(testCase, isfile(saved.summary_file));

verifyEqual(testCase, ...
    string(fileparts(saved.mat_file)), ...
    string(paths.data));

verifyEqual(testCase, ...
    string(fileparts(saved.summary_file)), ...
    string(paths.data));

loaded = load(saved.mat_file, "validation");

verifyEqual(testCase, ...
    loaded.validation.benchmark, ...
    "circular_inclusion_2d");

verifyTrue(testCase, loaded.validation.valid);

summary_text = fileread(saved.summary_file);

verifyTrue(testCase, contains( ...
    summary_text, ...
    "KWSIM CIRCULAR-INCLUSION 2D BENCHMARK"));

verifyTrue(testCase, contains( ...
    summary_text, ...
    "zero_contrast_relative_error"));

end


function validation = syntheticValidation()

check = struct();
check.name = "zero_contrast_relative_error";
check.pass = true;
check.value = 1e-8;
check.threshold = 1e-6;

validation = struct();

validation.benchmark = ...
    "circular_inclusion_2d";

validation.valid = true;
validation.checks = check;

validation.metrics = struct( ...
    "zero_contrast_relative_error", ...
    1e-8);

validation.results = struct( ...
    "contrast", struct("synthetic", true), ...
    "homogeneous", struct("synthetic", true), ...
    "zero_contrast", struct("synthetic", true));

validation.reports = struct();
validation.configurations = struct();

validation.summary = ...
    "valid=1, zero-contrast error=1e-08";

end


function removeDirectory(path)

if isfolder(path)
    rmdir(path, "s");
end

end
