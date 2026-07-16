%RUN_FINITE_CONTACTS_BENCHMARK
% Run, evaluate, plot, and save the finite-contact 2D benchmark.

project_root = fileparts( ...
    fileparts(fileparts(mfilename('fullpath'))));

addpath(fullfile(project_root, 'src'));
addpath(fullfile(project_root, 'benchmarks'));

validation = ...
    kwsim_benchmarks.finite_contacts_2d.run();

fprintf('%s\n', validation.summary);

output_directory = fullfile( ...
    project_root, 'outputs', 'finite_contacts_2d');

paths = kwsim_benchmarks.finite_contacts_2d.saveResults( ...
    validation, output_directory);

paths.figure_file = fullfile( ...
    output_directory, 'finite_contacts_comparison.png');

[figure_handle, ~] = ...
    kwsim_benchmarks.finite_contacts_2d.plotResults( ...
        validation, paths.figure_file);

close(figure_handle);

disp(paths);

if ~validation.valid
    error( ...
        'kwsim:FiniteContactsBenchmarkFailed', ...
        'One or more finite-contact acceptance checks failed.');
end
