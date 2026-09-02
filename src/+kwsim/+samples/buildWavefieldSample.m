function sample = buildWavefieldSample(result, options)
%BUILDWAVEFIELDSAMPLE Convert a k-Wave result to wavefield_sample.
%
% 2D results are exported as data_zx(z,x). 3D results are exported as the
% complete sensor-ROI volume data_zyx(z,y,x). Truth maps and coordinates
% always describe the same spatial ROI as the exported harmonic field.

arguments
    result (1,1) struct
    options.Quantity (1,1) string = "displacement"
end

quantity = lower(options.Quantity);
if ~any(quantity == ["displacement", "velocity"])
    error("kwsim:InvalidWavefieldQuantity", ...
        "Quantity must be displacement or velocity.");
end

dimension = resolveDimension(result);
spatial = extractSpatialData(result, quantity, dimension);

sample = struct();
sample.schema_name = "wavefield_sample";
sample.schema_version = "1.0";
sample.spatial_dimension = dimension;
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
sample.coordinates.x_m = double(spatial.x_m(:)).';
sample.coordinates.z_m = double(spatial.z_m(:)).';
sample.coordinates.dx_m = spacingFromAxis(spatial.x_m);
sample.coordinates.dz_m = spacingFromAxis(spatial.z_m);

if dimension == 3
    sample.coordinates.y_m = double(spatial.y_m(:)).';
    sample.coordinates.dy_m = spacingFromAxis(spatial.y_m);
    sample.coordinates.array_order = "zyx";
else
    sample.coordinates.array_order = "zx";
    sample.coordinates.observation_plane = "x_z";
    sample.coordinates.observation_y_m = 0;
end

sample.wavefield = struct();
if dimension == 3
    sample.wavefield.data_zyx = spatial.field;
    sample.wavefield.output_convention = "data_zyx(z,y,x)";
else
    sample.wavefield.data_zx = spatial.field;
    sample.wavefield.output_convention = "data_zx(z,x)";
end
sample.wavefield.component = "axial_total";
sample.wavefield.quantity = quantity;
sample.wavefield.frequency_hz = spatial.frequency_hz;
sample.wavefield.angular_frequency_rad_s = 2*pi*spatial.frequency_hz;
sample.wavefield.is_complex = ~isreal(spatial.field);
sample.wavefield.units = spatial.units;
sample.wavefield.phasor_convention = spatial.phasor_convention;

sample.measurement = struct();
sample.measurement.quantity = quantity;
sample.measurement.component = "axial_total";
sample.measurement.axis_xyz = [0, 0, 1];

sample.truth = struct();
if dimension == 3
    sample.truth.cs_map_zyx = spatial.cs;
    sample.truth.k_map_zyx = cast( ...
        2*pi*spatial.frequency_hz ./ double(spatial.cs), ...
        "like", spatial.cs);
    sample.truth.rho_kg_m3_zyx = spatial.rho;
    sample.truth.material_id_zyx = spatial.material_id;
    sample.truth.valid_mask_zyx = true(size(spatial.field));
else
    sample.truth.cs_map_zx = spatial.cs;
    sample.truth.k_map_zx = cast( ...
        2*pi*spatial.frequency_hz ./ double(spatial.cs), ...
        "like", spatial.cs);
    sample.truth.rho_kg_m3_zx = spatial.rho;
    sample.truth.material_id_zx = spatial.material_id;
    sample.truth.valid_mask_zx = true(size(spatial.field));
end

sample.medium = struct();
sample.medium.background_cs_m_s = resolveBackgroundCs(result, spatial.cs);
sample.medium.combine_mode = "";
sample.medium.objects = {};
sample.medium.config = resolveMediumConfig(result);

sample.propagation = struct();
sample.propagation.model = "full_wave_kwave";
sample.propagation.source_dimension = dimension;
sample.propagation.direction_space = resolveDirectionSpace(dimension);
sample.propagation.direction_count = resolveDirectionCount(result);
sample.propagation.direction_sampling_method = "";
sample.propagation.angular_support = struct();
sample.propagation.require_in_plane = [];

sample.directions = struct("ux", [], "uy", [], "uz", [], ...
    "xyz", zeros(0,3), "plane_intersection", struct());
sample.sources = resolveSources(result);
sample.extraction = spatial.extraction;

sample.validation = struct();
sample.validation.valid = resolveSimulationValid(result);
sample.validation.analysis_ready = ...
    sample.validation.valid && ...
    all(isfinite(spatial.field(:))) && ...
    any(abs(spatial.field(:)) > 0);
if dimension == 3
    sample.validation.output_convention = "data_zyx(z,y,x)";
else
    sample.validation.output_convention = "data_zx(z,x)";
end
sample.validation.backend_diagnostics = resolveValidation(result);

sample.provenance = struct();
sample.provenance.resolved_config = resolveResolvedConfig(result);
provenance = resolveProvenance(result);
sample.provenance.run_id = resolveProvenanceField(provenance, "run_id");
sample.provenance.campaign_id = resolveProvenanceField(provenance, "campaign_id");
sample.provenance.source_path = resolveProvenanceField(provenance, "source_path");
sample.provenance.created_utc = resolveProvenanceField(provenance, "created_utc");
sample.provenance.result_schema_version = resolveResultSchemaVersion(result);

wavefield.validateSample(sample);
end

function dimension = resolveDimension(result)
dimension = NaN;
if isfield(result, "dimension")
    dimension = double(result.dimension);
elseif isfield(result, "config_resolved") && isfield(result.config_resolved, "dimension")
    dimension = double(result.config_resolved.dimension);
end
if ~isscalar(dimension) || ~ismember(dimension, [2,3])
    error("kwsim:InvalidWavefieldDimension", ...
        "Result dimension must be 2 or 3.");
end
end

function spatial = extractSpatialData(result, quantity, dimension)
if ~isfield(result, "fields") || ~isfield(result.fields, quantity)
    error("kwsim:MissingWavefieldField", ...
        "Result does not contain fields.%s.", quantity);
end

fieldGroup = result.fields.(quantity);
spatial = struct();
spatial.frequency_hz = resolveFrequency(result);
spatial.units = resolveFieldText(fieldGroup, "units", defaultUnits(quantity));
spatial.phasor_convention = resolveFieldText( ...
    fieldGroup, "phasor_convention", ...
    "signal(t) = real(phasor * exp(1i*2*pi*f*t)) + dc");
spatial.x_m = requiredAxis(result, "x_m");
spatial.z_m = requiredAxis(result, "z_m");

if dimension == 2
    if ~isfield(fieldGroup, "axial_total_zx")
        error("kwsim:MissingWavefieldField", ...
            "2D result does not contain axial_total_zx.");
    end
    spatial.field = fieldGroup.axial_total_zx;
    spatial.cs = cropTruth2D(result, "cs_m_s_zx");
    spatial.rho = cropTruth2D(result, "rho_kg_m3_zx");
    spatial.material_id = cropTruth2D(result, "material_id_zx");
    spatial.extraction = struct( ...
        "method", "native_2d_sensor_roi", ...
        "x_indices", resolveSensorIndices(result, "x_indices"), ...
        "z_indices", resolveSensorIndices(result, "z_indices"));
    return
end

spatial.y_m = requiredAxis(result, "y_m");
if isfield(fieldGroup, "z_total_zyx")
    spatial.field = fieldGroup.z_total_zyx;
elseif isfield(fieldGroup, "z_shear_zyx") && ...
        isfield(fieldGroup, "z_compression_zyx")
    spatial.field = fieldGroup.z_shear_zyx + fieldGroup.z_compression_zyx;
else
    error("kwsim:MissingWavefieldField", ...
        "3D result does not contain z_total_zyx.");
end
spatial.cs = requiredTruth(result, "cs_m_s_zyx");
spatial.rho = requiredTruth(result, "rho_kg_m3_zyx");
spatial.material_id = requiredTruth(result, "material_id_zyx");
spatial.extraction = struct("method", "native_3d_sensor_roi");
end

function truth = cropTruth2D(result, name)
truth = requiredTruth(result, name);
expectedSize = [numel(requiredAxis(result,"z_m")), numel(requiredAxis(result,"x_m"))];
if isequal(size(truth), expectedSize)
    return
end
zIndices = resolveSensorIndices(result, "z_indices");
xIndices = resolveSensorIndices(result, "x_indices");
if isempty(zIndices) || isempty(xIndices)
    error("kwsim:MissingWavefieldSensorIndices", ...
        "2D full-domain truth requires sensor x/z indices for ROI cropping.");
end
truth = truth(zIndices, xIndices);
end

function indices = resolveSensorIndices(result, name)
indices = [];
if isfield(result, "sensor") && isfield(result.sensor, name)
    indices = result.sensor.(name);
elseif isfield(result, "config_resolved") && ...
        isfield(result.config_resolved, "sensor") && ...
        isfield(result.config_resolved.sensor, name)
    indices = result.config_resolved.sensor.(name);
end
indices = double(indices(:)).';
end

function value = resolveFrequency(result)
value = NaN;
if isfield(result, "axes") && isfield(result.axes, "f0_hz")
    value = double(result.axes.f0_hz);
elseif isfield(result, "fields") && isfield(result.fields, "frequency_hz")
    value = double(result.fields.frequency_hz);
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

function axisValue = requiredAxis(result, name)
if ~isfield(result, "axes") || ~isfield(result.axes, name)
    error("kwsim:MissingWavefieldAxis", "Result axes.%s is required.", name);
end
axisValue = result.axes.(name);
end

function truth = requiredTruth(result, name)
if ~isfield(result, "truth") || ~isfield(result.truth, name)
    error("kwsim:MissingWavefieldTruth", "Result truth.%s is required.", name);
end
truth = result.truth.(name);
end

function spacing = spacingFromAxis(axisValue)
axisValue = double(axisValue(:));
if numel(axisValue) < 2
    error("kwsim:InvalidWavefieldAxis", ...
        "Wavefield axes require at least two samples.");
end
spacing = mean(diff(axisValue));
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
    return
end
source = result.config_resolved.source;
for name = ["vibrator_count", "count", "source_count", "num_sources", "n_sources"]
    if isfield(source, name)
        count = double(source.(name));
        return
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
