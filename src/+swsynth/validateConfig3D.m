function [cfg, report] = validateConfig3D(cfg)
%VALIDATECONFIG3D Validate the volumetric 3D synthetic configuration.

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
cfg.medium.combine_mode = choice(cfg.medium.combine_mode, ...
    ["overlay"], "medium.combine_mode");
cfg.medium.objects = validateMediumObjects(cfg.medium.objects);

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

% Reuse the established angular contract.
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

function objects = validateMediumObjects(objects)

if isempty(objects)
    objects = {};
    return
end
if ~iscell(objects)
    error("swsynth:Invalid3DMediumObjects", ...
        "medium.objects must be a cell array of structs.");
end

for i = 1:numel(objects)
    object = objects{i};
    if ~isstruct(object) || ~isscalar(object)
        error("swsynth:Invalid3DMediumObject", ...
            "medium.objects{%d} must be a scalar struct.", i);
    end
    required(object, "type", i);
    required(object, "cs_m_s", i);
    object.type = choice(object.type, ...
        ["sphere","box","slab","custom"], ...
        sprintf("medium.objects{%d}.type", i));
    positiveScalar(object.cs_m_s, ...
        sprintf("medium.objects{%d}.cs_m_s", i));

    switch object.type
        case "sphere"
            required(object, "center_xyz_m", i);
            required(object, "radius_m", i);
            object.center_xyz_m = finiteVector3(object.center_xyz_m, ...
                sprintf("medium.objects{%d}.center_xyz_m", i));
            positiveScalar(object.radius_m, ...
                sprintf("medium.objects{%d}.radius_m", i));

        case "box"
            required(object, "center_xyz_m", i);
            required(object, "size_xyz_m", i);
            object.center_xyz_m = finiteVector3(object.center_xyz_m, ...
                sprintf("medium.objects{%d}.center_xyz_m", i));
            object.size_xyz_m = positiveVector3(object.size_xyz_m, ...
                sprintf("medium.objects{%d}.size_xyz_m", i));

        case "slab"
            required(object, "normal_xyz", i);
            required(object, "offset_m", i);
            normal = finiteVector3(object.normal_xyz, ...
                sprintf("medium.objects{%d}.normal_xyz", i));
            if norm(normal) <= eps
                error("swsynth:Invalid3DMediumObject", ...
                    "Slab normal_xyz must be nonzero.");
            end
            object.normal_xyz = normal / norm(normal);
            if ~isscalar(object.offset_m) || ~isfinite(object.offset_m)
                error("swsynth:Invalid3DMediumObject", ...
                    "Slab offset_m must be a finite scalar.");
            end

        case "custom"
            required(object, "mask_zyx", i);
            if ~(islogical(object.mask_zyx) || isnumeric(object.mask_zyx)) || ...
                    isempty(object.mask_zyx)
                error("swsynth:Invalid3DMediumObject", ...
                    "custom mask_zyx must be a nonempty numeric/logical array.");
            end
            object.mask_zyx = logical(object.mask_zyx);
    end
    objects{i} = object;
end

end

function required(object, fieldName, index)
if ~isfield(object, fieldName)
    error("swsynth:Invalid3DMediumObject", ...
        "medium.objects{%d}.%s is required.", index, fieldName);
end
end

function value = finiteVector3(value, location)
value = double(value(:)).';
if numel(value) ~= 3 || any(~isfinite(value))
    error("swsynth:Invalid3DConfigVector", ...
        "%s must be a finite 3-vector.", location);
end
end

function value = positiveVector3(value, location)
value = finiteVector3(value, location);
if any(value <= 0)
    error("swsynth:Invalid3DConfigVector", ...
        "%s must contain positive values.", location);
end
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
