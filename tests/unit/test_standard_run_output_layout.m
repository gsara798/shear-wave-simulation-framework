function tests = test_standard_run_output_layout
tests = functiontests(localfunctions);
end

function testKWaveRunDirectoriesIncludeValidation(testCase)
root = addFrameworkPath(); %#ok<NASGU>
temporaryRoot = string(tempname);
cleanup = onCleanup(@() removeDirectory(temporaryRoot)); %#ok<NASGU>

cfg = kwsim.two_d.defaultConfig();
cfg.output.directory = temporaryRoot;
cfg.output.run_name = "layout_test";
cfg.output.append_timestamp = false;
cfg.output.overwrite = false;

paths = kwsim.io.createRunDirectory(cfg);
verifyTrue(testCase,isfolder(paths.config));
verifyTrue(testCase,isfolder(paths.data));
verifyTrue(testCase,isfolder(paths.figures));
verifyTrue(testCase,isfolder(paths.validation));
end

function root = addFrameworkPath()
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
end

function removeDirectory(pathValue)
if isfolder(pathValue), rmdir(pathValue,"s"); end
end
