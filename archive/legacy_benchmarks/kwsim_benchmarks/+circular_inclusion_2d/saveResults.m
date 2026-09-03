function paths = saveResults( ...
    validation, destination, options)
%SAVERESULTS Save circular-inclusion cross-run validation artifacts.
%
% destination may be:
%   - the standardized paths structure returned by saveSimulationResult
%   - a directory path
%
% When standardized paths are supplied, files are written into paths.data.

arguments
    validation struct
    destination
    options.Overwrite (1,1) logical = false
end

data_directory = resolveDataDirectory(destination);

if ~isfolder(data_directory)
    mkdir(data_directory);
end

mat_file = fullfile( ...
    data_directory, ...
    "validation.mat");

summary_file = fullfile( ...
    data_directory, ...
    "validation_summary.txt");

assertWritable(mat_file, options.Overwrite);
assertWritable(summary_file, options.Overwrite);

% validation contains all benchmark simulations, reports, configurations,
% metrics, and cross-run checks. Use v7.3 because the solver results may be
% large.
save(mat_file, "validation", "-v7.3");

writeSummary(validation, summary_file);

paths = struct();

% Preserve the legacy field names.
paths.mat_file = string(mat_file);
paths.summary_file = string(summary_file);

% Also expose names consistent with the generic IO helpers.
paths.mat = string(mat_file);
paths.summary = string(summary_file);

end


function data_directory = resolveDataDirectory(destination)

if isstruct(destination)
    if ~isfield(destination, "data")
        error("kwsim:InvalidOutputPaths", ...
            "Output paths structure is missing the data field.");
    end

    data_directory = string(destination.data);
else
    data_directory = string(destination);
end

end


function writeSummary(validation, path)

file_id = fopen(path, "w");

if file_id < 0
    error("kwsim:SummaryWriteFailed", ...
        ["Could not create circular-inclusion benchmark " ...
         "validation summary: %s"], ...
        path);
end

cleanup = onCleanup(@() fclose(file_id));

fprintf(file_id, ...
    "KWSIM CIRCULAR-INCLUSION 2D BENCHMARK\n");

fprintf(file_id, ...
    "=====================================\n\n");

fprintf(file_id, ...
    "%s\n\n", ...
    char(string(validation.summary)));

fprintf(file_id, ...
    "Overall valid: %d\n\n", ...
    logical(validation.valid));

fprintf(file_id, ...
    "%-40s %-6s %-14s %-14s\n", ...
    "Check", ...
    "Pass", ...
    "Value", ...
    "Threshold");

for check = validation.checks.'
    fprintf(file_id, ...
        "%-40s %-6d %-14.6g %-14.6g\n", ...
        char(string(check.name)), ...
        logical(check.pass), ...
        double(check.value), ...
        double(check.threshold));
end

end


function assertWritable(path, overwrite)

if isfile(path) && ~overwrite
    error("kwsim:OutputFileExists", ...
        "Output file already exists: %s", ...
        path);
end

end
