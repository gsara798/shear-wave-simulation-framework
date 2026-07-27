function [config, metadata] = loadBaseConfig(base_config_file, backend)
%LOADBASECONFIG Load and resolve one backend-specific configuration.

arguments
    base_config_file {mustBeTextScalar}
    backend {mustBeTextScalar}
end

base_config_file = string(base_config_file);
backend = lower(string(backend));

switch backend
    case "kwsim"
        [config, metadata] = kwsim.io.loadConfigJson(base_config_file);

    case "swsynth"
        try
            requested = jsondecode(fileread(base_config_file));
        catch exception
            error("simcampaigns:InvalidSwsynthConfigJson", ...
                "Could not decode swsynth config '%s': %s", ...
                base_config_file, exception.message);
        end

        if ~isstruct(requested) || ~isscalar(requested)
            error("simcampaigns:InvalidSwsynthConfigJson", ...
                "The swsynth base config must contain one JSON object.");
        end

        requested = normalizeObjects(requested);
        [config, validation] = swsynth.validateConfig(requested);

        metadata = struct();
        metadata.backend = "swsynth";
        metadata.base_config_file = base_config_file;
        metadata.requested = requested;
        metadata.validation = validation;

    otherwise
        error("simcampaigns:UnsupportedBackend", ...
            "Unsupported campaign backend: %s", backend);
end

end

function config = normalizeObjects(config)

if ~isfield(config, "medium") || ...
        ~isstruct(config.medium) || ...
        ~isfield(config.medium, "objects")
    return
end

objects = config.medium.objects;

if isempty(objects)
    config.medium.objects = {};
elseif isstruct(objects)
    config.medium.objects = reshape(num2cell(objects), [], 1);
elseif ~iscell(objects)
    error("simcampaigns:InvalidSwsynthObjects", ...
        "medium.objects must decode to an object array.");
end

end
