%RUN_CIRCULAR_INCLUSION_BENCHMARK
% Execute, evaluate, plot, and save the circular-inclusion 2D benchmark.

example_directory = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(example_directory));

addpath(fullfile(project_root, 'src'));
addpath(fullfile(project_root, 'benchmarks'));

cfg = kwsim_benchmarks.circular_inclusion_2d.config();
validation = kwsim_benchmarks.circular_inclusion_2d.run(cfg);

fprintf('%s\n', validation.summary);

output_directory = fullfile( ...
    project_root, 'outputs', 'circular_inclusion_2d');

contrast = validation.results.contrast;
contrast_report = validation.reports.contrast;

kwsim.io.saveRun( ...
    contrast, contrast_report, output_directory, ...
    'Overwrite', true);

comparison_file = fullfile( ...
    output_directory, 'inclusion_comparison.png');

kwsim_benchmarks.circular_inclusion_2d.plotResults( ...
    contrast, ...
    validation.results.homogeneous, ...
    comparison_file, ...
    'Visible', false, ...
    'CloseAfterExport', true);

kwsim_benchmarks.circular_inclusion_2d.saveResults( ...
    validation, output_directory);

if ~validation.valid
    error( ...
        'kwsim:CircularInclusionBenchmarkFailed', ...
        'One or more circular-inclusion acceptance checks failed.');
end
