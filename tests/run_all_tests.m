function results = run_all_tests()
%RUN_ALL_TESTS Run unit and integration tests from any working directory.

tests_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(tests_dir);
addpath(fullfile(project_root, 'src'));
results = runtests(tests_dir, 'IncludeSubfolders', true);
disp(table(results));
assertSuccess(results);

end
