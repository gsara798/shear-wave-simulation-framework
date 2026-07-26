function sample_path = saveWavefieldSample( ...
    sample, destination, options)
%SAVEWAVEFIELDSAMPLE Save a backend-neutral estimator input.
%
% The MAT-file contains one variable:
%
%   wavefield_sample
%
% Usage:
%   path = kwsim.samples.saveWavefieldSample(sample, paths);
%   path = kwsim.samples.saveWavefieldSample( ...
%       sample, output_directory, Overwrite=true);

arguments
    sample (1,1) struct
    destination
    options.Overwrite (1,1) logical = false
end

if ~isfield(sample, "schema_name") || ...
        string(sample.schema_name) ~= "wavefield_sample"
    error("kwsim:InvalidWavefieldSample", ...
        "sample.schema_name must be wavefield_sample.");
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
    "wavefield_sample.mat");

if isfile(sample_path) && ~options.Overwrite
    error("kwsim:OutputFileExists", ...
        "Wavefield sample already exists: %s", ...
        sample_path);
end

wavefield_sample = sample; %#ok<NASGU>

save( ...
    sample_path, ...
    "wavefield_sample", ...
    "-v7.3");

sample_path = string(sample_path);

end
