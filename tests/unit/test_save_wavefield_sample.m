function tests = test_save_wavefield_sample
%TEST_SAVE_WAVEFIELD_SAMPLE Test generic sample persistence.

tests = functiontests(localfunctions);

end

function setupOnce(~)

repositoryRoot = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repositoryRoot, "src"));

end

function testSavesExpectedVariableAndFilename(testCase)

sample = minimalSample();

temporaryDirectory = string(tempname);
mkdir(temporaryDirectory);

cleanup = onCleanup( ...
    @() removeDirectory(temporaryDirectory));

paths = struct();
paths.data = temporaryDirectory;

samplePath = kwsim.samples.saveWavefieldSample( ...
    sample, ...
    paths);

verifyTrue(testCase, isfile(samplePath));
verifyEqual( ...
    testCase, ...
    string(samplePath), ...
    fullfile(temporaryDirectory, "wavefield_sample.mat"));

loaded = load(samplePath, "wavefield_sample");

verifyEqual( ...
    testCase, ...
    loaded.wavefield_sample.schema_name, ...
    "wavefield_sample");

verifyEqual( ...
    testCase, ...
    loaded.wavefield_sample.wavefield.data_zx, ...
    sample.wavefield.data_zx);

clear cleanup

end

function testRejectsOverwriteByDefault(testCase)

sample = minimalSample();

temporaryDirectory = string(tempname);
mkdir(temporaryDirectory);

cleanup = onCleanup( ...
    @() removeDirectory(temporaryDirectory));

kwsim.samples.saveWavefieldSample( ...
    sample, ...
    temporaryDirectory);

verifyError( ...
    testCase, ...
    @() kwsim.samples.saveWavefieldSample( ...
        sample, ...
        temporaryDirectory), ...
    "kwsim:OutputFileExists");

clear cleanup

end

function testAllowsExplicitOverwrite(testCase)

sample = minimalSample();

temporaryDirectory = string(tempname);
mkdir(temporaryDirectory);

cleanup = onCleanup( ...
    @() removeDirectory(temporaryDirectory));

samplePath = kwsim.samples.saveWavefieldSample( ...
    sample, ...
    temporaryDirectory);

sample.sample_id = "replacement";

samePath = kwsim.samples.saveWavefieldSample( ...
    sample, ...
    temporaryDirectory, ...
    Overwrite=true);

verifyEqual(testCase, samePath, samplePath);

loaded = load(samePath, "wavefield_sample");
verifyEqual( ...
    testCase, ...
    loaded.wavefield_sample.sample_id, ...
    "replacement");

clear cleanup

end

function sample = minimalSample()

sample = struct();
sample.schema_name = "wavefield_sample";
sample.schema_version = "1.0";
sample.sample_id = "";

sample.wavefield = struct();
sample.wavefield.data_zx = complex(ones(3, 4));

end

function removeDirectory(directory)

if isfolder(directory)
    rmdir(directory, "s");
end

end
