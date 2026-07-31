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
sample.wavefield.quantity = "displacement";
sample.wavefield.frequency_hz = result.wavefield.frequency_hz;
sample.wavefield.angular_frequency_rad_s = ...
    2*pi*result.wavefield.frequency_hz;
sample.wavefield.is_complex = result.wavefield.is_complex;
sample.wavefield.units = "arbitrary_displacement";
sample.wavefield.phasor_convention = ...
    "u(t) = real{U exp(i 2*pi*f*t)}";
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

sample.propagation.direction_count = ...
    result.directions.count;

sample.propagation.requested_direction_count = ...
    result.config.directions.count;

sample.propagation.direction_sampling_method = ...
    result.config.directions.sampling_method;

sample.propagation.angular_support = ...
    result.config.directions.support;

sample.propagation.require_in_plane = ...
    result.config.directions.require_in_plane;

if isfield(result.wavefield, "reference_cs_m_s")
    sample.propagation.reference_cs_m_s = ...
        result.wavefield.reference_cs_m_s;
end

if isfield(result.wavefield, "diagnostics")
    sample.propagation.diagnostics = ...
        result.wavefield.diagnostics;
end

effectiveXYZ = [
    double(result.directions.ux(:)), ...
    double(result.directions.uy(:)), ...
    double(result.directions.uz(:))];

sample.directions = struct();
sample.directions.xyz = effectiveXYZ;
sample.directions.ux = result.directions.ux;
sample.directions.uy = result.directions.uy;
sample.directions.uz = result.directions.uz;

sample.directions.requested_count = ...
    result.config.directions.count;

sample.directions.retained_count = ...
    size(effectiveXYZ,1);

sample.directions.in_plane_count = ...
    result.direction_metrics.count_in_plane;

if sample.directions.retained_count > 0
    sample.directions.in_plane_fraction = ...
        sample.directions.in_plane_count / ...
        sample.directions.retained_count;
else
    sample.directions.in_plane_fraction = NaN;
end

sample.directions.requested_in_plane_count = ...
    result.config.directions.in_plane_count;

sample.directions.plane_intersection = ...
    result.direction_metrics;

sample.requested_directions = struct();

if isfield(result, "requested_directions")
    requestedXYZ = [
        double(result.requested_directions.ux(:)), ...
        double(result.requested_directions.uy(:)), ...
        double(result.requested_directions.uz(:))];

    sample.requested_directions.xyz = requestedXYZ;
    sample.requested_directions.count = ...
        size(requestedXYZ,1);
else
    sample.requested_directions.xyz = effectiveXYZ;
    sample.requested_directions.count = ...
        size(effectiveXYZ,1);
end

if isfield(result, "requested_direction_metrics")
    sample.requested_directions.plane_intersection = ...
        result.requested_direction_metrics;
else
    sample.requested_directions.plane_intersection = ...
        result.direction_metrics;
end

sample.excitation = struct();

excitationFields = [
    "weights"
    "phase_rad"
    "amplitude"
    "polarization_xyz"
    "polarization_z"];

for fieldIndex = 1:numel(excitationFields)
    fieldName = excitationFields(fieldIndex);

    if isfield(result.wavefield, fieldName)
        sample.excitation.(fieldName) = ...
            result.wavefield.(fieldName);
    end
end

sample.sources = result.wavefield.sources;

sample.metrics = struct();

if isfield(result, "spectral_metrics")
    sample.metrics.global_spectrum = ...
        result.spectral_metrics;
end

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

validateDirections( ...
    result.directions, ...
    "result.directions");

if isfield(result, "requested_directions")
    validateDirections( ...
        result.requested_directions, ...
        "result.requested_directions");
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


function validateDirections(directions, location)

requiredFields = ["ux", "uy", "uz"];

for fieldIndex = 1:numel(requiredFields)
    fieldName = requiredFields(fieldIndex);

    if ~isfield(directions, fieldName)
        error( ...
            "swsynth:InvalidWavefieldDirections", ...
            "%s.%s is required.", ...
            location, ...
            fieldName);
    end
end

ux = double(directions.ux(:));
uy = double(directions.uy(:));
uz = double(directions.uz(:));

if isempty(ux) || ...
        numel(uy) ~= numel(ux) || ...
        numel(uz) ~= numel(ux) || ...
        any(~isfinite([ux; uy; uz]))
    error( ...
        "swsynth:InvalidWavefieldDirections", ...
        "%s must contain finite direction vectors of equal length.", ...
        location);
end

directionNorms = sqrt(ux.^2 + uy.^2 + uz.^2);

if any(directionNorms <= eps)
    error( ...
        "swsynth:InvalidWavefieldDirections", ...
        "%s contains a zero-magnitude direction.", ...
        location);
end

end
