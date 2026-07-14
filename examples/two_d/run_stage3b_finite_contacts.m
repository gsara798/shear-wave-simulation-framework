%RUN_STAGE3B_FINITE_CONTACTS Validate finite external vibrator contacts.

project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(project_root, 'src'));

validation = kwsim.diagnostics.runFiniteContactValidation();
disp(validation.summary);

output_directory = fullfile(project_root, 'outputs', 'stage3b_finite_contacts');
paths = kwsim.diagnostics.saveFiniteContactValidation( ...
    validation, output_directory);
disp(paths);
