function [cfg, report] = validateConfig3D(cfg)
%VALIDATECONFIG3D Validate the volumetric analytical 3D configuration.

arguments
    cfg (1,1) struct
end

defaults = swsynth.defaultConfig3D();
cfg = merge(defaults, cfg, "cfg");

positiveScalar(cfg.seed, "seed");

names = ["Lx_m","Ly_m","Lz_m","dx_m","dy_m","dz_m"];
for name = names
    positiveScalar(cfg.domain.(name), "domain." + name);
end

if cfg.domain.dx_m > cfg.domain.Lx_m || ...
        cfg.domain.dy_m > cfg.domain.Ly_m || ...
        cfg.domain.dz_m > cfg.domain.Lz_m
    error("swsynth:Invalid3DDomain", ...
        "Each spatial spacing must not exceed its domain length.");
end

positiveScalar(cfg.medium.background_cs_m_s, ...
    "medium.background_cs_m_s");
positiveScalar(cfg.wavefield.frequency_hz, ...
    "wavefield.frequency_hz");

cfg.wavefield.quantity = choice(cfg.wavefield.quantity, ...
    ["velocity","displacement"], "wavefield.quantity");
cfg.wavefield.observed_component = choice( ...
    cfg.wavefield.observed_component, ["axial_total"], ...
    "wavefield.observed_component");
cfg.propagation.model = choice(cfg.propagation.model, ...
    ["plane_wave"], "propagation.model");
cfg.polarization.model = choice(cfg.polarization.model, ...
    ["transverse_preferred","transverse_random"], ...
    "polarization.model");
cfg.sources.phase_policy = choice(cfg.sources.phase_policy, ...
    ["random_uniform"], "sources.phase_policy");

axisXYZ = double(cfg.measurement.axis_xyz(:));
if numel(axisXYZ) ~= 3 || any(~isfinite(axisXYZ)) || norm(axisXYZ) <= eps
    error("swsynth:InvalidMeasurementAxis", ...
        "measurement.axis_xyz must be a finite nonzero 3-vector.");
end
cfg.measurement.axis_xyz = (axisXYZ / norm(axisXYZ)).';

nonnegativeScalar(cfg.sources.amplitude_jitter_fraction, ...
    "sources.amplitude_jitter_fraction");

snrDb = double(cfg.noise.snr_db);
if ~isscalar(snrDb) || isnan(snrDb)
    error("swsynth:InvalidSNR", "noise.snr_db must be scalar.");
end
cfg.noise.snr_db = snrDb;

positiveInteger(cfg.execution.synthesis_batch_size, ...
    "execution.synthesis_batch_size");
if ~isscalar(cfg.execution.use_parallel)
    error("swsynth:InvalidExecution", ...
        "execution.use_parallel must be scalar.");
end
cfg.execution.use_parallel = logical(cfg.execution.use_parallel);

% Reuse the established angular contract by validating only the angular
% portion through a standard swsynth configuration.
directionCfg = swsynth.defaultConfig();
directionCfg.seed = cfg.seed;
directionCfg.directions = cfg.directions;
[directionCfg, ~] = swsynth.validateConfig(directionCfg);
if directionCfg.directions.space ~= "three_dimensional"
    error("swsynth:Invalid3DDirectionSpace", ...
        "Volumetric synthetic fields require three_dimensional directions.");
end
cfg.directions = directionCfg.directions;

report = struct();
report.valid = true;
report.spatial_dimension = 3;
report.array_order = "zyx";
report.output_convention = "U(z,y,x), maps(z,y,x)";

end

function out = merge(defaults, requested, location)

out = defaults;
fields = fieldnames(requested);
for i = 1:numel(fields)
    name = fields{i};
    if ~isfield(defaults, name)
        error("swsynth:Unknown3DConfigField", ...
            "%s.%s is not a supported configuration field.", ...
            location, name);
    end
    if isstruct(defaults.(name))
        if ~isstruct(requested.(name))
            error("swsynth:Invalid3DConfigField", ...
                "%s.%s must be a struct.", location, name);
        end
        out.(name) = merge(defaults.(name), requested.(name), ...
            location + "." + name);
    else
        out.(name) = requested.(name);
    end
end

end

function value = choice(value, allowed, location)
value = lower(string(value));
if ~isscalar(value) || ~ismember(value, allowed)
    error("swsynth:Invalid3DConfigChoice", ...
        "%s must be one of: %s.", location, strjoin(allowed, ", "));
end
end

function positiveScalar(value, location)
value = double(value);
if ~isscalar(value) || ~isfinite(value) || value <= 0
    error("swsynth:Invalid3DConfigScalar", ...
        "%s must be a positive finite scalar.", location);
end
end

function nonnegativeScalar(value, location)
value = double(value);
if ~isscalar(value) || ~isfinite(value) || value < 0
    error("swsynth:Invalid3DConfigScalar", ...
        "%s must be a nonnegative finite scalar.", location);
end
end

function positiveInteger(value, location)
positiveScalar(value, location);
if round(double(value)) ~= double(value)
    error("swsynth:Invalid3DConfigInteger", ...
        "%s must be an integer.", location);
end
end
