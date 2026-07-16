function paths = saveResults(validation, output_directory)
%SAVERESULTS Save circular-inclusion benchmark cross-run results and readable checks.
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

mat_file = fullfile(output_directory, "validation.mat");
save(mat_file, 'validation', '-v7.3');

summary_file = fullfile(output_directory, "validation_summary.txt");
fid = fopen(summary_file, 'w');
if fid < 0
    error('kwsim:SummaryWriteFailed', ...
        'Could not create circular-inclusion benchmark validation summary: %s', summary_file);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'KWSIM CIRCULAR-INCLUSION 2D BENCHMARK\n');
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
