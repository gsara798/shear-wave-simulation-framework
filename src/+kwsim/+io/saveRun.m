function paths = saveRun(result, report, output_directory, options)
%SAVERUN Save a self-contained simulation result and diagnostic artifacts.
%
% paths = kwsim.io.saveRun(result, report, output_directory)
%
% The MAT file always contains resolved configuration, truth maps, source
% metadata, phasors, diagnostics, and provenance. Time series are present
% only when output.save_time_series was enabled before simulation.

arguments
    result struct
    report struct
    output_directory {mustBeTextScalar}
    options.Overwrite (1,1) logical = false
end

output_directory = string(output_directory);
run_file = fullfile(output_directory, "run.mat");
if isfile(run_file) && ~options.Overwrite
    error('kwsim:OutputExists', ...
        'Refusing to overwrite existing result: %s', run_file);
end
if ~isfolder(output_directory)
    mkdir(output_directory);
end

save(run_file, 'result', 'report', '-v7.3');
figure_paths = kwsim.viz.plotRun(result, report, output_directory);

summary_file = fullfile(output_directory, "diagnostics_summary.txt");
fid = fopen(summary_file, 'w');
if fid < 0
    error('kwsim:SummaryWriteFailed', ...
        'Could not create diagnostic summary: %s', summary_file);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'KWSIM SIMULATION DIAGNOSTICS\n');
fprintf(fid, '%s\n\n', report.summary);
fprintf(fid, '%-34s %-6s %-14s %-14s %s\n', ...
    'Check', 'Pass', 'Value', 'Threshold', 'Meaning');
for check = report.checks.'
    fprintf(fid, '%-34s %-6d %-14.6g %-14.6g %s\n', ...
        check.name, check.pass, check.value, check.threshold, check.message);
end
clear cleanup;

paths = struct('run_mat', run_file, 'summary', summary_file, ...
    'source_figure', figure_paths.source, 'field_figure', figure_paths.field, ...
    'component_figure', figure_paths.components);

end
