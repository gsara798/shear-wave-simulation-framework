function paths = saveContactSizeSweep(sweep, output_directory)
%SAVECONTACTSIZESWEEP Save point-limit fields, metrics, and figure.

arguments
    sweep struct
    output_directory {mustBeTextScalar}
end

output_directory = string(output_directory);
if ~isfolder(output_directory)
    mkdir(output_directory);
end
paths = struct();
paths.mat_file = fullfile(output_directory, "contact_size_sweep.mat");
save(paths.mat_file, 'sweep', '-v7.3');
paths.summary_file = fullfile(output_directory, "contact_size_sweep_summary.txt");
fid = fopen(paths.summary_file, 'w');
if fid < 0
    error('kwsim:SummaryWriteFailed', ...
        'Could not create contact-size summary: %s', paths.summary_file);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'KWSIM CONTACT-SIZE SENSITIVITY\n%s\n', sweep.summary);
clear cleanup;
paths.figure_file = fullfile(output_directory, "contact_size_sweep.png");
[fig, ~] = kwsim.diagnostics.plotContactSizeSweep(sweep, paths.figure_file);
close(fig);

end
