%RUN_STAGE1_VALIDATION Execute repeatability, grid, and PML comparisons.

example_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(example_dir));
addpath(fullfile(project_root, 'src'));

cfg = kwsim.diagnostics.compactValidationConfig();
validation = kwsim.diagnostics.runStage1Validation(cfg);
fprintf('%s\n', validation.summary);

output_directory = fullfile(project_root, 'outputs', 'stage1_validation');
if ~isfolder(output_directory)
    mkdir(output_directory);
end
save(fullfile(output_directory, 'validation.mat'), 'validation', '-v7.3');

if ~validation.valid
    error('kwsim:Stage1ValidationFailed', ...
        'One or more Stage 1 cross-run checks failed.');
end
