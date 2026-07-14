%RUN_STAGE1_DIRECTIONAL Execute and save the full Stage 1 reference case.
%
% The script can be launched from any working directory. Results are written
% below outputs/stage1_directional and include run.mat, a text pass/fail
% summary, and source/field diagnostic figures.

example_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(example_dir));
addpath(fullfile(project_root, 'src'));
addpath(fullfile(project_root, 'config'));

cfg = stage1_directional_config();
cfg.output.directory = fullfile(project_root, 'outputs', 'stage1_directional');
cfg.output.overwrite = true;

[result, report] = kwsim.two_d.run(cfg);
fprintf('%s\n', report.summary);
