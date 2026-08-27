function result = writeCampaign(campaign, output_file)
%WRITECAMPAIGN Validate and atomically write a campaign JSON file.
%
% The campaign contract remains defined by simcampaigns.loadCampaignJson.
% This function adds no project-specific metadata or policy.

arguments
    campaign (1,1) struct
    output_file {mustBeTextScalar}
end

output_file = string(output_file);

parent_directory = string(fileparts(output_file));

if strlength(parent_directory) > 0 && ...
        ~isfolder(parent_directory)

    [created,message] = mkdir(parent_directory);

    if ~created
        error( ...
            "simcampaigns:CampaignDirectoryCreateFailed", ...
            "Could not create campaign directory '%s': %s", ...
            parent_directory,message);
    end
end

temporary_file = output_file + ".tmp";

delete_if_present(temporary_file);

file_id = fopen(temporary_file,"w");

if file_id < 0
    error( ...
        "simcampaigns:CampaignWriteFailed", ...
        "Could not create temporary campaign file: %s", ...
        temporary_file);
end

cleanup = onCleanup(@() fclose(file_id));

fprintf( ...
    file_id, ...
    "%s\n", ...
    jsonencode(campaign,PrettyPrint=true));

clear cleanup

% The canonical campaign loader owns schema and path validation.
try
    [validated,metadata] = ...
        simcampaigns.loadCampaignJson(temporary_file);
catch exception
    delete_if_present(temporary_file);
    rethrow(exception)
end

[moved,message] = movefile( ...
    temporary_file, ...
    output_file, ...
    "f");

if ~moved
    delete_if_present(temporary_file);

    error( ...
        "simcampaigns:CampaignWriteFailed", ...
        "Could not publish campaign '%s': %s", ...
        output_file,message);
end

result = struct();
result.path = canonical_path(output_file);
result.campaign = validated;
result.metadata = metadata;

end


function delete_if_present(path_value)

if isfile(path_value)
    delete(path_value);
end

end


function path_value = canonical_path(path_value)

path_value = string(char( ...
    java.io.File(char(path_value)).getCanonicalPath()));

end
