function sample = buildWavefieldSample(result, options)
%BUILDWAVEFIELDSAMPLE Build a generic 2D wavefield sample from a k-Wave run.
%
% The estimator-facing field is always a complex z-x field:
%
%   sample.wavefield.data_zx(z,x)
%
% Native 2D results use the axial-total field directly. Three-dimensional
% results are reduced to an x-z slice at the sensor y-position nearest the
% configured source center.
%
% Usage:
%   sample = kwsim.samples.buildWavefieldSample(result);
%   sample = kwsim.samples.buildWavefieldSample( ...
%       result, Quantity="velocity");
%
% This function intentionally reuses the existing validated 2D/3D
% extraction implemented by kwsim.req.createValidationSample. The resulting
% structure is estimator-neutral and does not contain REQ-specific
% readiness fields.

arguments
    result (1,1) struct
    options.Quantity (1,1) string = "displacement"
end

legacy = kwsim.req.createValidationSample( ...
    result, ...
    Quantity=options.Quantity);

sample = struct();

sample.schema_name = "wavefield_sample";
sample.schema_version = "1.0";

sample.sample_id = "";
sample.dataset_id = "";

sample.generator = struct();
sample.generator.name = "kwsim";
sample.generator.backend = "full_wave_kwave";
sample.generator.repository = ...
    "gsara798/shear-wave-simulation-framework";
sample.generator.commit = "";

sample.scenario = resolveScenario(result);
sample.seed = resolveSeed(result);

sample.coordinates = struct();
sample.coordinates.x_m = double(legacy.axes.x_m(:)).';
sample.coordinates.z_m = double(legacy.axes.z_m(:)).';
sample.coordinates.dx_m = legacy.spacing.dx_m;
sample.coordinates.dz_m = legacy.spacing.dz_m;
sample.coordinates.array_order = "zx";
sample.coordinates.observation_plane = "x_z";
sample.coordinates.observation_y_m = resolveObservationY(legacy);

sample.wavefield = struct();
sample.wavefield.data_zx = legacy.wavefield_complex_zx;
sample.wavefield.component = string(legacy.component);
sample.wavefield.quantity = string(legacy.quantity);
sample.wavefield.frequency_hz = double(legacy.frequency_hz);
sample.wavefield.angular_frequency_rad_s = ...
    2*pi*double(legacy.frequency_hz);
sample.wavefield.is_complex = ~isreal(legacy.wavefield_complex_zx);
sample.wavefield.units = string(legacy.units);
sample.wavefield.phasor_convention = ...
    string(legacy.phasor_convention);
sample.wavefield.output_convention = "data_zx(z,x)";

sample.truth = struct();
sample.truth.cs_map_zx = double(legacy.truth.cs_m_s_zx);
sample.truth.k_map_zx = ...
    2*pi*double(legacy.frequency_hz) ./ ...
    double(legacy.truth.cs_m_s_zx);
sample.truth.rho_kg_m3_zx = ...
    double(legacy.truth.rho_kg_m3_zx);
sample.truth.material_id_zx = legacy.truth.material_id_zx;
sample.truth.valid_mask_zx = true(size(legacy.wavefield_complex_zx));

sample.medium = struct();
sample.medium.background_cs_m_s = ...
    resolveBackgroundCs(result, sample.truth.cs_map_zx);
sample.medium.combine_mode = "";
sample.medium.objects = {};
sample.medium.config = resolveMediumConfig(result);

sample.propagation = struct();
sample.propagation.model = "full_wave_kwave";
sample.propagation.source_dimension = ...
    double(legacy.source_dimension);
sample.propagation.direction_space = ...
    resolveDirectionSpace(legacy.source_dimension);
sample.propagation.direction_count = ...
    resolveDirectionCount(result);
sample.propagation.direction_sampling_method = "";
sample.propagation.angular_support = struct();
sample.propagation.require_in_plane = [];

sample.directions = struct();
sample.directions.ux = [];
sample.directions.uy = [];
sample.directions.uz = [];
sample.directions.plane_intersection = struct();

sample.sources = resolveSources(result);
sample.extraction = legacy.extraction;

sample.validation = struct();
sample.validation.valid = resolveSimulationValid(legacy);
sample.validation.analysis_ready = ...
    sample.validation.valid && ...
    all(isfinite(sample.wavefield.data_zx(:))) && ...
    any(abs(sample.wavefield.data_zx(:)) > 0);
sample.validation.output_convention = "data_zx(z,x)";
sample.validation.backend_diagnostics = legacy.validation;

sample.provenance = struct();
sample.provenance.resolved_config = legacy.config_resolved;
sample.provenance.run_id = resolveProvenanceField( ...
    legacy.provenance, "run_id");
sample.provenance.campaign_id = resolveProvenanceField( ...
    legacy.provenance, "campaign_id");
sample.provenance.source_path = resolveProvenanceField( ...
    legacy.provenance, "source_path");
sample.provenance.created_utc = resolveProvenanceField( ...
    legacy.provenance, "created_utc");
sample.provenance.result_schema_version = ...
    string(legacy.result_schema_version);

assertSampleContract(sample);

end

function scenario = resolveScenario(result)

scenario = "";

if isfield(result, "config_resolved") && ...
        isfield(result.config_resolved, "scenario")
    scenario = string(result.config_resolved.scenario);
elseif isfield(result, "scenario")
    scenario = string(result.scenario);
end

end

function seed = resolveSeed(result)

seed = [];

if isfield(result, "config_resolved") && ...
        isfield(result.config_resolved, "seed")
    seed = result.config_resolved.seed;
elseif isfield(result, "seed")
    seed = result.seed;
end

end

function observationY = resolveObservationY(legacy)

observationY = [];

if isfield(legacy, "extraction") && ...
        isfield(legacy.extraction, "y_m") && ...
        ~isempty(legacy.extraction.y_m)
    observationY = double(legacy.extraction.y_m);
elseif legacy.source_dimension == 2
    observationY = 0;
end

end

function backgroundCs = resolveBackgroundCs(result, csMap)

backgroundCs = NaN;

if isfield(result, "config_resolved") && ...
        isfield(result.config_resolved, "medium")

    medium = result.config_resolved.medium;

    if isfield(medium, "cs_m_s")
        backgroundCs = double(medium.cs_m_s);
    elseif isfield(medium, "background") && ...
            isfield(medium.background, "cs_m_s")
        backgroundCs = double(medium.background.cs_m_s);
    end
end

if ~isscalar(backgroundCs) || ~isfinite(backgroundCs)
    backgroundCs = mode(double(csMap(:)));
end

end

function config = resolveMediumConfig(result)

config = struct();

if isfield(result, "config_resolved") && ...
        isfield(result.config_resolved, "medium")
    config = result.config_resolved.medium;
end

end

function space = resolveDirectionSpace(sourceDimension)

if double(sourceDimension) == 2
    space = "two_dimensional";
else
    space = "three_dimensional";
end

end

function count = resolveDirectionCount(result)

count = [];

if isfield(result, "config_resolved") && ...
        isfield(result.config_resolved, "source")

    source = result.config_resolved.source;

    candidateNames = [ ...
        "count", ...
        "source_count", ...
        "num_sources", ...
        "n_sources"];

    for i = 1:numel(candidateNames)
        name = candidateNames(i);
        if isfield(source, name)
            count = double(source.(name));
            return;
        end
    end
end

end

function sources = resolveSources(result)

sources = struct();

if isfield(result, "config_resolved") && ...
        isfield(result.config_resolved, "source")
    sources.config = result.config_resolved.source;
else
    sources.config = struct();
end

end

function valid = resolveSimulationValid(legacy)

if isempty(legacy.simulation_valid)
    valid = true;
else
    valid = logical(legacy.simulation_valid);
end

end

function value = resolveProvenanceField(provenance, name)

value = "";

if isstruct(provenance) && isfield(provenance, name)
    value = string(provenance.(name));
end

end

function assertSampleContract(sample)

requiredTopLevel = [ ...
    "schema_name", ...
    "schema_version", ...
    "generator", ...
    "coordinates", ...
    "wavefield", ...
    "truth", ...
    "validation", ...
    "provenance"];

for i = 1:numel(requiredTopLevel)
    if ~isfield(sample, requiredTopLevel(i))
        error("kwsim:InvalidWavefieldSample", ...
            "sample.%s is required.", requiredTopLevel(i));
    end
end

expectedSize = [ ...
    numel(sample.coordinates.z_m), ...
    numel(sample.coordinates.x_m)];

if ~isequal(size(sample.wavefield.data_zx), expectedSize)
    error("kwsim:InvalidWavefieldSampleSize", ...
        "wavefield.data_zx is inconsistent with the x/z coordinates.");
end

truthNames = [ ...
    "cs_map_zx", ...
    "k_map_zx", ...
    "rho_kg_m3_zx", ...
    "material_id_zx", ...
    "valid_mask_zx"];

for i = 1:numel(truthNames)
    name = truthNames(i);
    if ~isequal(size(sample.truth.(name)), expectedSize)
        error("kwsim:InvalidWavefieldSampleSize", ...
            "truth.%s has an inconsistent size.", name);
    end
end

end
