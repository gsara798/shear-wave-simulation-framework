function saved_paths = saveValidationReport( ...
    report, destination, options)
%SAVEVALIDATIONREPORT Save a validation report as MAT and readable text.
%
% destination may be:
%   - the paths structure returned by saveSimulationResult
%   - a directory path
%
% Files are written into the data directory.

arguments
    report struct
    destination
    options.Overwrite (1,1) logical = false
end

if isstruct(destination)
    if ~isfield(destination, "data")
        error("kwsim:InvalidOutputPaths", ...
            "Output paths structure is missing the data field.");
    end

    data_directory = string(destination.data);
else
    data_directory = string(destination);
end

if ~isfolder(data_directory)
    mkdir(data_directory);
end

mat_path = fullfile( ...
    data_directory, ...
    "validation_report.mat");

text_path = fullfile( ...
    data_directory, ...
    "validation_summary.txt");

assertWritable(mat_path, options.Overwrite);
assertWritable(text_path, options.Overwrite);

validation_report = report;
save(mat_path, "validation_report", "-v7.3");

writeReportText(report, text_path);

saved_paths = struct();
saved_paths.mat = string(mat_path);
saved_paths.summary = string(text_path);

end


function writeReportText(report, path)

file_id = fopen(path, "w");

if file_id < 0
    error("kwsim:OutputWriteFailed", ...
        "Could not open file for writing: %s", path);
end

cleanup = onCleanup(@() fclose(file_id));

fprintf(file_id, "KWSIM VALIDATION REPORT\n");
fprintf(file_id, "=======================\n\n");

if isfield(report, "summary")
    fprintf(file_id, "%s\n\n", char(string(report.summary)));
end

if isfield(report, "valid")
    fprintf(file_id, "Overall valid: %d\n\n", ...
        logical(report.valid));
end

if ~isfield(report, "checks") || isempty(report.checks)
    fprintf(file_id, "No individual checks were provided.\n");
    return
end

fprintf(file_id, ...
    "%-38s %-6s %-14s %-14s %s\n", ...
    "Check", "Pass", "Value", "Threshold", "Meaning");

for check = report.checks.'
    message = "";

    if isfield(check, "message")
        message = string(check.message);
    end

    fprintf(file_id, ...
        "%-38s %-6d %-14.6g %-14.6g %s\n", ...
        char(string(check.name)), ...
        logical(check.pass), ...
        double(check.value), ...
        double(check.threshold), ...
        char(message));
end

end


function assertWritable(path, overwrite)

if isfile(path) && ~overwrite
    error("kwsim:OutputFileExists", ...
        "Output file already exists: %s", path);
end

end
