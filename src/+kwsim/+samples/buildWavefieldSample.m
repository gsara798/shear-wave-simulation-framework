function sample = buildWavefieldSample(result, options)
%BUILDWAVEFIELDSAMPLE Convert a k-Wave result to the generic wavefield_sample.
%
% Native 2D results are exported directly in z-x order. For 3D results this
% adapter exports the x-z observation plane nearest the configured source
% y-position. The output contract is backend-neutral and has no dependency
% on a downstream estimator.

arguments
    result (1,1) struct
    options.Quantity (1,1) string = "displacement"
end

quantity = lower(options.Quantity);
if ~any(quantity == ["displacement", "velocity"])
    error("kwsim:InvalidWavefieldQuantity", ...
        "Quantity must be displacement or velocity.");
end

planar = extractPlanarData(result, quantity);

sample = struct();
sample.schema_name = "wavefield_sample";
sample.schema_version = "1.0";
sample.spatial_dimension = 2;
sample.sample_id = "";
sample.dataset_id = "";

sample.generator = struct( ...
    "name", "kwsim", ...
    "backend", "full_wave_kwave", ...
    "repository", "gsara798/shear-wave-simulation-framework", ...
    "commit", "");

sample.scenario = resolveScenario(result);
sample.seed = resolveSeed(result);

sample.coordinates = struct();
sample.coordinates.x_m = double(planar.x_m(:)).';
sample.coordinates.z_m = double(planar.z_m(:)).';
sample.coordinates.dx_m = spacingFromAxis(planar.x_m);
sample.coordinates.dz_m = spacingFromAxis(planar.z_m);
sample.coordinates.array_order = "zx";
sample.coordinates.observation_plane = "x_z";
sample.coordinates.observation_y_m = planar.y_m;

sample.wavefield = struct();
sample.wavefield.data_zx = planar.field_zx;
sample.wavefield.component = "axial_total";
sample.wavefield.quantity = quantity;
sample.wavefield.frequency_hz = planar.frequency_hz;
sample.wavefield.angular_frequency_rad_s = 2*pi*planar.frequency_hz;
sample.wavefield.is_complex = ~isreal(planar.field_zx);
sample.wavefield.units = planar.units;
sample.wavefield.phasor_convention = planar.phasor_convention;
sample.wavefield.output_convention = "data_zx(z,x)";

sample.measurement = struct();
sample.measurement.quantity = quantity;
sample.measurement.component = "axial_total";
sample.measurement.axis_xyz = [0, 0, 1];

sample.truth = struct();
sample.truth.cs_map_zx = planar.cs_zx;
sample.truth.k_map_zx = cast( ...
    2*pi*planar.frequency_hz ./ double(planar.cs_zx), ...
    "like", planar.cs_zx);
sample.truth.rho_kg_m3_zx = planar.rho_zx;
sample.truth.material_id_zx = planar.material_id_zx;
sample.truth.valid_mask_zx = true(size(planar.field_zx));

sample.medium = struct();
sample.medium.background_cs_m_s = resolveBackgroundCs(result, planar.cs_zx);
sample.medium.combine_mode = "";
sample.medium.objects = {};
sample.medium.config = resolveMediumConfig(result);

sample.propagation = struct();
sample.propagation.model = "full_wave_kwave";
sample.propagation.source_dimension = planar.source_dimension;
sample.propagation.direction_space = ...
    resolveDirectionSpace(planar.source_dimension);
sample.propagation.direction_count = resolveDirectionCount(result);
sample.propagation.direction_sampling_method = "";
sample.propagation.angular_support = struct();
sample.propagation.require_in_plane = [];

sample.directions = struct("ux", [], "uy", [], "uz", [], ...
    "plane_intersection", struct());
sample.sources = resolveSources(result);
sample.extraction = planar.extraction;

sample.validation = struct();
sample.validation.valid = resolveSimulationValid(result);
sample.validation.analysis_ready = ...
    sample.validation.valid && ...
    all(isfinite(sample.wavefield.data_zx(:))) && ...
    any(abs(sample.wavefield.data_zx(:)) > 0);
sample.validation.output_convention = "data_zx(z,x)";
sample.validation.backend_diagnostics = resolveValidation(result);

sample.provenance = struct();
sample.provenance.resolved_config = resolveResolvedConfig(result);
provenance = resolveProvenance(result);
sample.provenance.run_id = resolveProvenanceField(provenance, "run_id");
sample.provenance.campaign_id = resolveProvenanceField(provenance, "campaign_id");
sample.provenance.source_path = resolveProvenanceField(provenance, "source_path");
sample.provenance.created_utc = resolveProvenanceField(provenance, "created_utc");
sample.provenance.result_schema_version = resolveResultSchemaVersion(result);

assertSampleContract(sample);
wavefield.validateSample(sample);

end

function planar = extractPlanarData(result, quantity)

if ~isfield(result, "fields") || ~isfield(result.fields, quantity)
    error("kwsim:MissingWavefieldField", ...
        "Result does not contain fields.%s.", quantity);
end

fieldGroup = result.fields.(quantity);
planar = struct();
planar.frequency_hz = resolveFrequency(result);
planar.units = resolveFieldText(fieldGroup, "units", defaultUnits(quantity));
planar.phasor_convention = resolveFieldText( ...
    fieldGroup, "phasor_convention", ...
    "signal(t) = real(phasor * exp(1i*2*pi*f*t)) + dc");

isNative2D = isfield(fieldGroup, "axial_total_zx");
if isNative2D
    planar.source_dimension = 2;
    planar.field_zx = fieldGroup.axial_total_zx;
    planar.x_m = requiredAxis(result, "x_m");
    planar.z_m = requiredAxis(result, "z_m");
    planar.y_m = 0;
    planar.cs_zx = requiredTruth(result, "cs_m_s_zx");
    planar.rho_zx = requiredTruth(result, "rho_kg_m3_zx");
    planar.material_id_zx = requiredTruth(result, "material_id_zx");
    planar.extraction = struct("method", "native_2d", "y_index", [], "y_m", 0);
    return;
end

if isfield(fieldGroup, "z_total_zyx")
    volume = fieldGroup.z_total_zyx;
elseif isfield(fieldGroup, "z_shear_zyx") && isfield(fieldGroup, "z_compression_zyx")
    volume = fieldGroup.z_shear_zyx + fieldGroup.z_compression_zyx;
else
    error("kwsim:MissingWavefieldField", ...
        "Result does not contain an axial 2D field or z_total_zyx volume.");
end

planar.source_dimension = 3;
planar.x_m = requiredAxis(result, "x_m");
planar.z_m = requiredAxis(result, "z_m");
y_m = requiredAxis(result, "y_m");
yTarget = resolveObservationTargetY(result, y_m);
[~, yIndex] = min(abs(double(y_m(:)) - yTarget));
planar.y_m = double(y_m(yIndex));
planar.field_zx = reshape(volume(:, yIndex, :), size(volume, 1), size(volume, 3));
planar.cs_zx = sliceTruth(result, "cs_m_s_zyx", yIndex);
planar.rho_zx = sliceTruth(result, "rho_kg_m3_zyx", yIndex);
planar.material_id_zx = sliceTruth(result, "material_id_zyx", yIndex);
planar.extraction = struct( ...
    "method", "central_xz_plane", ...
    "y_index", yIndex, ...
    "y_m", planar.y_m);

end

function value = resolveFrequency(result)
value = NaN;
if isfield(result, "axes") && isfield(result.axes, "f0_hz")
    value = double(result.axes.f0_hz);
elseif isfield(result, "config_resolved") && ...
        isfield(result.config_resolved, "source") && ...
        isfield(result.config_resolved.source, "f0_hz")
    value = double(result.config_resolved.source.f0_hz);
end
if ~isscalar(value) || ~isfinite(value) || value <= 0
    error("kwsim:MissingWavefieldFrequency", ...
        "A positive finite harmonic frequency is required.");
end
end

function axis = requiredAxis(result, name)
if ~isfield(result, "axes") || ~isfield(result.axes, name)
    error("kwsim:MissingWavefieldAxis", "Result axes.%s is required.", name);
end
axis = result.axes.(name);
end

function truth = requiredTruth(result, name)
if ~isfield(result, "truth") || ~isfield(result.truth, name)
    error("kwsim:MissingWavefieldTruth", "Result truth.%s is required.", name);
end
truth = result.truth.(name);
end

function truth = sliceTruth(result, name, yIndex)
volume = requiredTruth(result, name);
truth = reshape(volume(:, yIndex, :), size(volume, 1), size(volume, 3));
end

function yTarget = resolveObservationTargetY(result, yAxis)
yTarget = double(yAxis(ceil(numel(yAxis)/2)));
if isfield(result, "config_resolved") && isfield(result.config_resolved, "source")
    source = result.config_resolved.source;
    if isfield(source, "center_m_xyz") && numel(source.center_m_xyz) >= 2
        candidate = double(source.center_m_xyz(2));
        if isfinite(candidate)
            yTarget = candidate;
        end
    end
end
end

function spacing = spacingFromAxis(axis)
axis = double(axis(:));
if numel(axis) < 2
    error("kwsim:InvalidWavefieldAxis", "Wavefield axes require at least two samples.");
end
spacing = mean(diff(axis));
end

function value = resolveFieldText(group, name, fallback)
value = string(fallback);
if isfield(group, name) && ~isempty(group.(name))
    value = string(group.(name));
end
end

function value = defaultUnits(quantity)
if quantity == "velocity"
    value = "m/s";
else
    value = "m";
end
end

function scenario = resolveScenario(result)
scenario = "";
if isfield(result, "config_resolved") && isfield(result.config_resolved, "scenario")
    scenario = string(result.config_resolved.scenario);
elseif isfield(result, "scenario")
    scenario = string(result.scenario);
end
end

function seed = resolveSeed(result)
seed = [];
if isfield(result, "config_resolved") && isfield(result.config_resolved, "seed")
    seed = result.config_resolved.seed;
elseif isfield(result, "seed")
    seed = result.seed;
end
end

function backgroundCs = resolveBackgroundCs(result, csMap)
backgroundCs = NaN;
if isfield(result, "config_resolved") && isfield(result.config_resolved, "medium")
    medium = result.config_resolved.medium;
    if isfield(medium, "cs_m_s")
        backgroundCs = double(medium.cs_m_s);
    elseif isfield(medium, "background") && isfield(medium.background, "cs_m_s")
        backgroundCs = double(medium.background.cs_m_s);
    end
end
if ~isscalar(backgroundCs) || ~isfinite(backgroundCs)
    backgroundCs = mode(double(csMap(:)));
end
end

function config = resolveMediumConfig(result)
config = struct();
if isfield(result, "config_resolved") && isfield(result.config_resolved, "medium")
    config = result.config_resolved.medium;
end
end

function space = resolveDirectionSpace(sourceDimension)
if sourceDimension == 2
    space = "two_dimensional";
else
    space = "three_dimensional";
end
end

function count = resolveDirectionCount(result)
count = [];
if ~isfield(result, "config_resolved") || ~isfield(result.config_resolved, "source")
    return;
end
source = result.config_resolved.source;
for name = ["vibrator_count", "count", "source_count", "num_sources", "n_sources"]
    if isfield(source, name)
        count = double(source.(name));
        return;
    end
end
end

function sources = resolveSources(result)
sources = struct();
if isfield(result, "config_resolved") && isfield(result.config_resolved, "source")
    sources.config = result.config_resolved.source;
else
    sources.config = struct();
end
end

function valid = resolveSimulationValid(result)
valid = true;
if isfield(result, "valid") && ~isempty(result.valid)
    valid = logical(result.valid);
elseif isfield(result, "validation") && isfield(result.validation, "valid")
    valid = logical(result.validation.valid);
end
end

function diagnostics = resolveValidation(result)
diagnostics = struct();
if isfield(result, "validation")
    diagnostics = result.validation;
elseif isfield(result, "validation_report")
    diagnostics = result.validation_report;
end
end

function config = resolveResolvedConfig(result)
config = struct();
if isfield(result, "config_resolved")
    config = result.config_resolved;
end
end

function provenance = resolveProvenance(result)
provenance = struct();
if isfield(result, "provenance")
    provenance = result.provenance;
end
end

function value = resolveProvenanceField(provenance, name)
value = "";
if isstruct(provenance) && isfield(provenance, name)
    value = string(provenance.(name));
end
end

function version = resolveResultSchemaVersion(result)
version = "";
if isfield(result, "schema_version")
    version = string(result.schema_version);
end
end

function assertSampleContract(sample)
requiredTopLevel = ["schema_name", "schema_version", "generator", ...
    "coordinates", "wavefield", "truth", "validation", "provenance"];
for name = requiredTopLevel
    if ~isfield(sample, name)
        error("kwsim:InvalidWavefieldSample", "sample.%s is required.", name);
    end
end
expectedSize = [numel(sample.coordinates.z_m), numel(sample.coordinates.x_m)];
if ~isequal(size(sample.wavefield.data_zx), expectedSize)
    error("kwsim:InvalidWavefieldSampleSize", ...
        "wavefield.data_zx is inconsistent with the x/z coordinates.");
end
for name = ["cs_map_zx", "k_map_zx", "rho_kg_m3_zx", ...
        "material_id_zx", "valid_mask_zx"]
    if ~isequal(size(sample.truth.(name)), expectedSize)
        error("kwsim:InvalidWavefieldSampleSize", ...
            "truth.%s has an inconsistent size.", name);
    end
end
end
