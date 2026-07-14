%RUN_STAGE3B_CONTACT_SIZE_SWEEP Compare point, 4 mm, and 8 mm contacts.

project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(project_root, 'src'));
sweep = kwsim.diagnostics.runContactSizeSweep();
disp(sweep.summary);
kwsim.diagnostics.saveContactSizeSweep(sweep, ...
    fullfile(project_root, 'outputs', 'stage3b_finite_contacts'));
