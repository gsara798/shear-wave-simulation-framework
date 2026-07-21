function [source, metadata] = buildSource(cfg, kgrid)
%BUILDSOURCE Build a 3D elastic velocity source from the configured layout.
%
% This function is the public source-construction dispatcher. Individual
% source layouts are implemented in dedicated builders.
%
% Supported layouts:
%   single_contact
%
% Planned:
%   vibrator_bank

arguments
    cfg struct
    kgrid
end

if ~isfield(cfg, "source") || ...
        ~isfield(cfg.source, "layout")
    error( ...
        "kwsim:Missing3DSourceLayout", ...
        "The resolved configuration must define source.layout.");
end

layout = lower(string(cfg.source.layout));

switch layout
    case "single_contact"
        [source, metadata] = ...
            kwsim.three_d.buildSingleContactSource( ...
                cfg, ...
                kgrid);

    case "vibrator_bank"
        [source, metadata] = ...
            kwsim.three_d.buildVibratorBankSource( ...
                cfg, ...
                kgrid);

    otherwise
        error( ...
            "kwsim:Unsupported3DSourceLayout", ...
            "Unsupported 3D source layout: %s.", ...
            layout);
end

metadata.layout = layout;
metadata.builder = string(mfilename("fullpath"));

end
