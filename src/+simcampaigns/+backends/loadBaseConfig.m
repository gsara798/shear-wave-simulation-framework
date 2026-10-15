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

        swsynth.io.requireV2Config(requested);
        [~,validation]=swsynth.io.resolveConfigV2(requested);
        config=requested;
        metadata=struct("backend","swsynth", ...
            "implementation","modular_v2", ...
            "base_config_file",base_config_file, ...
            "requested",requested,"validation",validation, ...
            "spatial_dimension",validation.dimension);

    otherwise
        error("simcampaigns:UnsupportedBackend", ...
            "Unsupported campaign backend: %s", backend);
end

end

