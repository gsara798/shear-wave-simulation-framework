%RUN_FIELD_REGIMES_BENCHMARK
% Run, evaluate, plot, and save the 2D shear-field regimes benchmark.

project_root = fileparts( ...
    fileparts(fileparts(mfilename('fullpath'))));

addpath(fullfile(project_root, 'src'));
addpath(fullfile(project_root, 'benchmarks'));

validation = ...
    kwsim_benchmarks.field_regimes_2d.run();

fprintf('%s\n', validation.summary);

output_directory = fullfile( ...
    project_root, 'outputs', 'field_regimes_2d');

paths = kwsim_benchmarks.field_regimes_2d.saveResults( ...
    validation, output_directory);

paths.figure_file = fullfile( ...
    output_directory, 'field_regimes_comparison.png');

[figure_handle, ~] = ...
    kwsim_benchmarks.field_regimes_2d.plotResults( ...
        validation, paths.figure_file);

close(figure_handle);

disp(paths);

if ~validation.valid
    error( ...
        'kwsim:FieldRegimesBenchmarkFailed', ...
        'One or more field-regimes acceptance checks failed.');
end
