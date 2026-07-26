function sample = buildWavefieldSample(result)
%BUILDWAVEFIELDSAMPLE Build a backend-neutral wavefield sample.
%
% The sample is intended for any downstream estimator, including REQ,
% wavelet, Helmholtz, finite-difference, and learned estimators.
%
% Usage:
%   result = swsynth.run(cfg);
%   sample = swsynth.buildWavefieldSample(result);
%
% Public array orientation:
%   wavefield.data_zx(z,x)
%   truth.cs_map_zx(z,x)
%   truth.k_map_zx(z,x)
%   truth.material_id_zx(z,x)
%   truth.valid_mask_zx(z,x)

arguments
    result (1,1) struct
end

validateResult(result);

sample = struct();

sample.schema_name = "wavefield_sample";
sample.schema_version = "1.0";

sample.sample_id = "";
sample.dataset_id = "";

sample.generator = struct();
sample.generator.name = "swsynth";
sample.generator.backend = "fast_synthetic";
sample.generator.repository = "gsara798/shear-wave-simulation-framework";
sample.generator.commit = "";

sample.scenario = string(result.config.scenario);
sample.seed = result.config.seed;

sample.coordinates = struct();
sample.coordinates.x_m = result.coordinates.x_m;
sample.coordinates.z_m = result.coordinates.z_m;
sample.coordinates.dx_m = result.coordinates.dx_m;
sample.coordinates.dz_m = result.coordinates.dz_m;
sample.coordinates.array_order = "zx";
sample.coordinates.observation_plane = "x_z";
sample.coordinates.observation_y_m = ...
    result.config.domain.observation_y_m;

sample.wavefield = struct();
sample.wavefield.data_zx = result.wavefield.U_zx;
sample.wavefield.component = result.wavefield.component;
sample.wavefield.frequency_hz = result.wavefield.frequency_hz;
sample.wavefield.angular_frequency_rad_s = ...
    2*pi*result.wavefield.frequency_hz;
sample.wavefield.is_complex = result.wavefield.is_complex;
sample.wavefield.units = "arbitrary_displacement";
sample.wavefield.output_convention = "data_zx(z,x)";

sample.truth = struct();
sample.truth.cs_map_zx = result.truth.cs_map_zx;
sample.truth.k_map_zx = result.truth.k_map_zx;
sample.truth.material_id_zx = result.truth.material_id_zx;
sample.truth.valid_mask_zx = logical(result.truth.valid_mask_zx);

sample.medium = struct();
sample.medium.background_cs_m_s = ...
    result.config.medium.background_cs_m_s;
sample.medium.combine_mode = result.config.medium.combine_mode;
sample.medium.objects = result.config.medium.objects;

sample.propagation = struct();
sample.propagation.model = result.config.propagation.model;
sample.propagation.direction_space = result.config.directions.space;
sample.propagation.direction_count = result.config.directions.count;
sample.propagation.direction_sampling_method = ...
    result.config.directions.sampling_method;
sample.propagation.angular_support = ...
    result.config.directions.support;
sample.propagation.require_in_plane = ...
    result.config.directions.require_in_plane;

sample.directions = struct();
sample.directions.ux = result.directions.ux;
sample.directions.uy = result.directions.uy;
sample.directions.uz = result.directions.uz;
sample.directions.plane_intersection = result.direction_metrics;

sample.sources = result.wavefield.sources;

sample.validation = struct();
sample.validation.valid = logical(result.validation.valid);
sample.validation.analysis_ready = ...
    result.validation.valid && ...
    all(isfinite(result.wavefield.U_zx(:))) && ...
    any(abs(result.wavefield.U_zx(:)) > 0);
sample.validation.output_convention = ...
    result.validation.output_convention;

sample.provenance = struct();
sample.provenance.resolved_config = result.config;
sample.provenance.run_id = "";
sample.provenance.campaign_id = "";
sample.provenance.source_path = "";
sample.provenance.created_utc = "";

end

function validateResult(result)

requiredTopLevel = [ ...
    "config", ...
    "validation", ...
    "coordinates", ...
    "wavefield", ...
    "truth", ...
    "directions", ...
    "direction_metrics"];

for i = 1:numel(requiredTopLevel)
    if ~isfield(result, requiredTopLevel(i))
        error("swsynth:InvalidWavefieldResult", ...
            "result.%s is required.", requiredTopLevel(i));
    end
end

requiredWavefield = [ ...
    "U_zx", ...
    "component", ...
    "frequency_hz", ...
    "is_complex", ...
    "sources"];

for i = 1:numel(requiredWavefield)
    if ~isfield(result.wavefield, requiredWavefield(i))
        error("swsynth:InvalidWavefieldResult", ...
            "result.wavefield.%s is required.", requiredWavefield(i));
    end
end

requiredTruth = [ ...
    "cs_map_zx", ...
    "k_map_zx", ...
    "material_id_zx", ...
    "valid_mask_zx"];

for i = 1:numel(requiredTruth)
    if ~isfield(result.truth, requiredTruth(i))
        error("swsynth:InvalidWavefieldResult", ...
            "result.truth.%s is required.", requiredTruth(i));
    end
end

fieldSize = size(result.wavefield.U_zx);

if ~isequal(size(result.truth.cs_map_zx), fieldSize) || ...
        ~isequal(size(result.truth.k_map_zx), fieldSize) || ...
        ~isequal(size(result.truth.material_id_zx), fieldSize) || ...
        ~isequal(size(result.truth.valid_mask_zx), fieldSize)
    error("swsynth:WavefieldSampleSizeMismatch", ...
        "Wavefield and truth maps must have identical z-x dimensions.");
end

end
