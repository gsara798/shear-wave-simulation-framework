%RUN_DIRECTIONAL_HOMOGENEOUS_BENCHMARK
% Execute and save the full directional homogeneous 2D reference.

example_directory = fileparts(mfilename('fullpath'));

project_root = fileparts( ...
    fileparts(example_directory));

addpath(fullfile(project_root, 'src'));
addpath(fullfile(project_root, 'benchmarks'));

cfg = ...
    kwsim_benchmarks.directional_homogeneous_2d.config();

cfg.output.directory = fullfile( ...
    project_root, ...
    'outputs', ...
    'directional_homogeneous_2d');

cfg.output.overwrite = true;

[result, report] = ...
    kwsim_benchmarks.directional_homogeneous_2d.run(cfg);

fprintf('%s\n', report.summary);

if ~report.valid
    error( ...
        'kwsim:DirectionalHomogeneousBenchmarkFailed', ...
        'The directional homogeneous benchmark failed validation.');
end
