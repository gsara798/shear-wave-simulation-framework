%RUN_STAGE2_CIRCULAR_INCLUSION Execute and save the Stage 2 validation suite.
%
% Three independent simulations are run: contrast inclusion, homogeneous
% reference, and zero-contrast inclusion. Results and the dedicated
% comparison figure are saved below outputs/stage2_circular_inclusion.

example_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(example_dir));
addpath(fullfile(project_root, 'src'));
addpath(fullfile(project_root, 'config'));

cfg = stage2_circular_inclusion_config();
validation = kwsim.diagnostics.runStage2Validation(cfg);
fprintf('%s\n', validation.summary);

output_directory = fullfile(project_root, 'outputs', ...
    'stage2_circular_inclusion');
contrast = validation.results.contrast;
contrast_report = validation.reports.contrast;
kwsim.common.saveRun(contrast, contrast_report, output_directory, ...
    'Overwrite', true);

comparison_file = fullfile(output_directory, 'inclusion_comparison.png');
kwsim.diagnostics.plotInclusionComparison(contrast, ...
    validation.results.homogeneous, comparison_file, ...
    'Visible', false, 'CloseAfterExport', true);
kwsim.diagnostics.saveStage2Validation(validation, output_directory);

if ~validation.valid
    error('kwsim:Stage2ValidationFailed', ...
        'One or more Stage 2 acceptance checks failed.');
end
