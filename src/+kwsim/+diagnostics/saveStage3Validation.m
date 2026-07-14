function paths = saveStage3Validation(validation, output_directory, options)
%SAVESTAGE3VALIDATION Save Stage 3 fields, checks, and comparison figure.

arguments
    validation struct
    output_directory {mustBeTextScalar}
    options.FilePrefix (1,1) string = "stage3"
end

output_directory = string(output_directory);
if ~isfolder(output_directory)
    mkdir(output_directory);
end

paths = struct();
prefix = options.FilePrefix;
paths.mat_file = fullfile(output_directory, prefix + "_validation.mat");
save(paths.mat_file, 'validation', '-v7.3');

paths.summary_file = fullfile(output_directory, prefix + "_validation_summary.txt");
fid = fopen(paths.summary_file, 'w');
if fid < 0
    error('kwsim:SummaryWriteFailed', ...
        'Could not create Stage 3 validation summary: %s', paths.summary_file);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'KWSIM %s CROSS-RUN VALIDATION\n', upper(prefix));
fprintf(fid, '%s\n\n', validation.summary);
fprintf(fid, '%-48s %-6s %-14s %-14s\n', ...
    'Check', 'Pass', 'Value', 'Threshold');
for check = validation.checks.'
    fprintf(fid, '%-48s %-6d %-14.6g %-14.6g\n', ...
        check.name, check.pass, check.value, check.threshold);
end
fprintf(fid, '\nSINGLE-RUN CHECKS\n');
for name = ["directional", "partially_diffuse", "diffuse"]
    report = validation.reports.(name);
    fprintf(fid, '\n%s: %s\n', upper(name), report.summary);
    for check = report.checks.'
        fprintf(fid, '  %-44s %-6d %-14.6g %-14.6g\n', ...
            check.name, check.pass, check.value, check.threshold);
    end
end
clear cleanup;

paths.figure_file = fullfile(output_directory, prefix + "_field_regimes.png");
[fig, ~] = kwsim.diagnostics.plotStage3Comparison(validation, paths.figure_file);
close(fig);

end
