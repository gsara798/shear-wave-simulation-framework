function validateConfig(cfg)
%VALIDATECONFIG Validate optional Boukraa-like displacement readout settings.
arguments
    cfg (1,1) struct
end
allowed=["enabled","seed","level","strength","nt","prf_hz", ...
    "correlation_m","frequency_noise_gain","depth_profile", ...
    "depth_weight_power","depth_noise_floor","max_weight", ...
    "amplitude_normalization","reference_amplitude"];
unknown=setdiff(string(fieldnames(cfg)),allowed);
if ~isempty(unknown)
    error("swsynth:InvalidReadoutNoise", ...
        "Unsupported readout_noise field %s.",unknown(1));
end
if ~isfield(cfg,"enabled") || ~islogical(cfg.enabled) || ~isscalar(cfg.enabled)
    error("swsynth:InvalidReadoutNoise", ...
        "readout_noise.enabled must be a logical scalar.");
end
numericFields=["strength","correlation_m","frequency_noise_gain", ...
    "depth_weight_power","depth_noise_floor","max_weight"];
for field=numericFields
    if isfield(cfg,field)
        v=cfg.(field);
        if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ...
                ~isfinite(v) || v<0
            error("swsynth:InvalidReadoutNoise", ...
                "readout_noise.%s must be a finite nonnegative scalar.",field);
        end
    end
end
for field=["nt","prf_hz"]
    if isfield(cfg,field)
        v=cfg.(field);
        if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ...
                ~isfinite(v) || v<=0
            error("swsynth:InvalidReadoutNoise", ...
                "readout_noise.%s must be positive.",field);
        end
    end
end
if isfield(cfg,"nt") && (cfg.nt<4 || cfg.nt~=fix(cfg.nt))
    error("swsynth:InvalidReadoutNoise", ...
        "readout_noise.nt must be an integer >= 4.");
end
if isfield(cfg,"max_weight") && cfg.max_weight==0
    error("swsynth:InvalidReadoutNoise", ...
        "readout_noise.max_weight must be positive.");
end
if isfield(cfg,"seed")
    v=cfg.seed;
    if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~isfinite(v) || ...
            v<0 || v~=fix(v) || v>2^32-1
        error("swsynth:InvalidReadoutNoise", ...
            "readout_noise.seed must be an integer in [0,2^32-1].");
    end
end
if isfield(cfg,"level") && ...
        ~isChoice(cfg.level,["low","soft","medium","moderate","high","hard"])
    error("swsynth:InvalidReadoutNoise","Unsupported readout_noise.level.");
end
if isfield(cfg,"depth_profile") && ~isChoice(cfg.depth_profile, ...
        ["none","linear_0_to_1","exponential_0_to_1"])
    error("swsynth:InvalidReadoutNoise","Unsupported readout_noise.depth_profile.");
end
normalization="max_abs";
if isfield(cfg,"amplitude_normalization")
    if ~isChoice(cfg.amplitude_normalization, ...
            ["max_abs","rms","fixed_reference","none"])
        error("swsynth:InvalidReadoutNoise", ...
            "Unsupported readout_noise.amplitude_normalization.");
    end
    normalization=lower(string(cfg.amplitude_normalization));
end
if isfield(cfg,"reference_amplitude")
    v=cfg.reference_amplitude;
    if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ...
            ~isfinite(v) || v<=0
        error("swsynth:InvalidReadoutNoise", ...
            "readout_noise.reference_amplitude must be positive.");
    end
end
if cfg.enabled && normalization=="fixed_reference" && ...
        ~isfield(cfg,"reference_amplitude")
    error("swsynth:InvalidReadoutNoise", ...
        "fixed_reference requires an explicit positive reference_amplitude.");
end
end

function tf=isChoice(v,choices)
tf=(ischar(v) || (isstring(v) && isscalar(v))) && ...
    ismember(lower(string(v)),choices);
end
