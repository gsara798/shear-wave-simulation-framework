function paths = saveResults(sweep, output_directory, options)
%SAVERESULTS Save benchmark results, readable checks, and figures.

arguments
    sweep struct
    output_directory {mustBeTextScalar}
    options.Overwrite (1,1) logical = false
end

output_directory = string(output_directory);
if ~isfolder(output_directory)
    mkdir(output_directory);
end
paths = struct();
paths.mat_file = fullfile(output_directory, "sweep_index.mat");
paths.summary_file = fullfile(output_directory, "attenuation_power_law_summary.txt");
paths.figure_file = fullfile(output_directory, "attenuation_power_law.png");
if ~options.Overwrite && any(isfile([paths.mat_file, paths.summary_file, ...
        paths.figure_file]))
    error('kwsim:OutputExists', ...
        'Refusing to overwrite existing attenuation benchmark artifacts.');
end

save(paths.mat_file, 'sweep', '-v7.3');
fid = fopen(paths.summary_file, 'w');
if fid < 0
    error('kwsim:SummaryWriteFailed', ...
        'Could not create attenuation benchmark summary: %s', paths.summary_file);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'KWSIM POWER-LAW ATTENUATION BENCHMARK\n');
fprintf(fid, '%s\n\n', sweep.summary);
fprintf(fid, '%-42s %-6s %-14s %-14s\n', ...
    'Check', 'Pass', 'Value', 'Threshold');
for check = sweep.checks.'
    fprintf(fid, '%-42s %-6d %-14.6g %-14.6g\n', ...
        check.name, check.pass, check.value, check.threshold);
end
fprintf(fid, '\nPER-FREQUENCY PAIRS\n');
for pair = sweep.pairs.'
    fprintf(fid, '\n%s\n', pair.summary);
    for check = pair.checks.'
        fprintf(fid, '  %-38s %-6d %-14.6g %-14.6g\n', ...
            check.name, check.pass, check.value, check.threshold);
    end
end
clear cleanup;

[fig, ~] = ...
    kwsim_benchmarks.attenuation_power_law_2d.plotResults( ...
        sweep, paths.figure_file);
close(fig);
paths.pair_figures = strings(numel(sweep.pairs), 1);
for index = 1:numel(sweep.pairs)
    pair = sweep.pairs(index);
    frequency_directory = fullfile(output_directory, ...
        sprintf('f_%06g_hz', pair.frequency_hz));
    if ~isfolder(frequency_directory)
        mkdir(frequency_directory);
    end
    pair_file = fullfile(frequency_directory, "attenuation_diagnostics.png");
    [fig, ~] = ...
        kwsim_benchmarks.attenuation_power_law_2d.plotPair( ...
            pair, pair_file);
    close(fig);
    paths.pair_figures(index) = pair_file;
end

end
