%RUN_STAGE3_FIELD_REGIMES Validate directional, partial, and diffuse fields.

project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(project_root, 'src'));

validation = kwsim.diagnostics.runStage3Validation();
disp(validation.summary);

output_directory = fullfile(project_root, 'outputs', 'stage3_field_regimes');
paths = kwsim.diagnostics.saveStage3Validation(validation, output_directory);
disp(paths);
