function sample_path = saveValidationSample( ...
    sample, destination, options)
%SAVEVALIDATIONSAMPLE Save a lightweight REQ validation input.

arguments
    sample struct
    destination
    options.Overwrite (1,1) logical = false
end

if isstruct(destination)
    if ~isfield(destination, "data")
        error("kwsim:InvalidOutputPaths", ...
            "Output paths structure is missing data.");
    end

    data_directory = string(destination.data);
else
    data_directory = string(destination);
end

if ~isfolder(data_directory)
    mkdir(data_directory);
end

sample_path = fullfile( ...
    data_directory, ...
    "req_validation_sample.mat");

if isfile(sample_path) && ~options.Overwrite
    error("kwsim:OutputFileExists", ...
        "REQ validation sample already exists: %s", ...
        sample_path);
end

req_validation_sample = sample;

save(sample_path, ...
    "req_validation_sample", ...
    "-v7.3");

sample_path = string(sample_path);

end
