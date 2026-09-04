function paths = saveResults(validation, output_directory)
%SAVERESULTS Save finite-contact validation and readable checks.

arguments
    validation struct
    output_directory {mustBeTextScalar}
end

output_directory = string(output_directory);

if ~isfolder(output_directory)
    mkdir(output_directory);
end

paths = struct();

paths.mat_file = fullfile( ...
    output_directory, "validation.mat");

save(paths.mat_file, 'validation', '-v7.3');

paths.summary_file = fullfile( ...
    output_directory, "validation_summary.txt");

fid = fopen(paths.summary_file, 'w');

if fid < 0
    error( ...
        'kwsim:SummaryWriteFailed', ...
        'Could not create finite-contact summary: %s', ...
        paths.summary_file);
end

cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'KWSIM FINITE-CONTACTS 2D BENCHMARK\n');
fprintf(fid, '%s\n\n', validation.summary);

fprintf(fid, '%-48s %-6s %-14s %-14s\n', ...
    'Check', 'Pass', 'Value', 'Threshold');

for check = validation.checks.'
    fprintf(fid, '%-48s %-6d %-14.6g %-14.6g\n', ...
        check.name, ...
        check.pass, ...
        check.value, ...
        check.threshold);
end

fprintf(fid, '\nSINGLE-RUN CHECKS\n');

for name = ["directional", "partially_diffuse", "diffuse"]
    report = validation.reports.(name);

    fprintf(fid, '\n%s: %s\n', ...
        upper(name), report.summary);
end

clear cleanup;

end
