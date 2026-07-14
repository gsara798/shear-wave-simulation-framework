function paths = saveStage2Validation(validation, output_directory)
%SAVESTAGE2VALIDATION Save Stage 2 cross-run results and readable checks.
%
% The MAT file contains all three simulations. The text file exposes every
% acceptance value and threshold without requiring MATLAB to inspect it.

arguments
    validation struct
    output_directory {mustBeTextScalar}
end

output_directory = string(output_directory);
if ~isfolder(output_directory)
    mkdir(output_directory);
end

mat_file = fullfile(output_directory, "stage2_validation.mat");
save(mat_file, 'validation', '-v7.3');

summary_file = fullfile(output_directory, "stage2_validation_summary.txt");
fid = fopen(summary_file, 'w');
if fid < 0
    error('kwsim:SummaryWriteFailed', ...
        'Could not create Stage 2 validation summary: %s', summary_file);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'KWSIM STAGE 2 CROSS-RUN VALIDATION\n');
fprintf(fid, '%s\n\n', validation.summary);
fprintf(fid, '%-40s %-6s %-14s %-14s\n', ...
    'Check', 'Pass', 'Value', 'Threshold');
for check = validation.checks.'
    fprintf(fid, '%-40s %-6d %-14.6g %-14.6g\n', ...
        check.name, check.pass, check.value, check.threshold);
end
clear cleanup;

paths = struct('mat_file', mat_file, 'summary_file', summary_file);

end
