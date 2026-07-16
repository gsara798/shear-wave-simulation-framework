function paths = saveSizeSweep(sweep, output_directory)
%SAVESIZESWEEP Save contact-size fields and summary metrics.

arguments
    sweep struct
    output_directory {mustBeTextScalar}
end

output_directory = string(output_directory);

if ~isfolder(output_directory)
    mkdir(output_directory);
end

paths = struct();

paths.mat_file = fullfile( ...
    output_directory, "contact_size_sweep.mat");

save(paths.mat_file, 'sweep', '-v7.3');

paths.summary_file = fullfile( ...
    output_directory, "contact_size_sweep_summary.txt");

fid = fopen(paths.summary_file, 'w');

if fid < 0
    error( ...
        'kwsim:SummaryWriteFailed', ...
        'Could not create contact-size summary: %s', ...
        paths.summary_file);
end

cleanup = onCleanup(@() fclose(fid));

fprintf(fid, ...
    'KWSIM CONTACT-SIZE SENSITIVITY\n%s\n', ...
    sweep.summary);

clear cleanup;

end
