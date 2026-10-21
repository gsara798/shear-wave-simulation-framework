function validateConfig(cfg)
%VALIDATECONFIG Validate phenomenological shear noise settings.
arguments
    cfg (1,1) struct
end
allowed=["enabled","source_amplitude_jitter_std", ...
    "source_phase_jitter_cycles_std","propagation_relative_std", ...
    "correlation_m","amplitude_floor_fraction","seed","spatial_scaling"];
unknown=setdiff(string(fieldnames(cfg)),allowed);
if ~isempty(unknown)
    error("swsynth:InvalidShearNoise","Unsupported shear_noise field %s.",unknown(1));
end
if ~isfield(cfg,"enabled") || ~islogical(cfg.enabled) || ~isscalar(cfg.enabled)
    error("swsynth:InvalidShearNoise","shear_noise.enabled must be logical scalar.");
end
fields=["source_amplitude_jitter_std","source_phase_jitter_cycles_std", ...
    "propagation_relative_std","correlation_m","amplitude_floor_fraction"];
for field=fields
    if isfield(cfg,field)
        v=cfg.(field);
        if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~isfinite(v) || v<0
            error("swsynth:InvalidShearNoise","%s must be finite nonnegative scalar.",field);
        end
    end
end
if isfield(cfg,"spatial_scaling")
    mode=cfg.spatial_scaling;
    if ~(ischar(mode) || (isstring(mode) && isscalar(mode)))
        error("swsynth:InvalidShearNoise", ...
            "spatial_scaling must be a scalar string or character vector.");
    end
    mode=string(mode);
    if ~ismember(mode,["relative_local","uniform_global_rms"])
        error("swsynth:InvalidShearNoise", ...
            "Unsupported spatial_scaling: %s.",mode);
    end
end
if isfield(cfg,"seed")
    v=cfg.seed;
    if ~isnumeric(v) || ~isscalar(v) || ~isfinite(v) || v<0 || v~=fix(v) || v>2^32-1
        error("swsynth:InvalidShearNoise","seed must be an integer in [0,2^32-1].");
    end
end
end
