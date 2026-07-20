function sample = createValidationSample(result, options)
%CREATEVALIDATIONSAMPLE Build a lightweight 2D input for external REQ validation.
%
% The returned wavefield always uses public orientation [Nz,Nx].
%
% Dimension 2:
%   Uses the native axial-total field.
%
% Dimension 3:
%   Extracts an x-z plane at the sensor y-position nearest the source
%   elevational center.
%
% This product is intended for external validation of REQ algorithms.
% It does not contain oracle q targets or ML training labels.

arguments
    result struct
    options.Quantity (1,1) string = "displacement"
end

quantity = lower(options.Quantity);

if ~ismember(quantity, ["displacement", "velocity"])
    error("kwsim:InvalidReqQuantity", ...
        "Quantity must be displacement or velocity.");
end

if ~isfield(result, "dimension")
    error("kwsim:InvalidSimulationResult", ...
        "Simulation result is missing dimension.");
end

dimension = double(result.dimension);

switch dimension
    case 2
        sample = createFrom2D(result, quantity);

    case 3
        sample = createFrom3D(result, quantity);

    otherwise
        error("kwsim:UnsupportedDimension", ...
            "REQ validation samples support dimensions 2 and 3.");
end

sample.sample_schema_version = "1.0";
sample.source_dimension = dimension;
sample.quantity = quantity;
sample.component = "axial_total";
sample.orientation = "[Nz,Nx]";
sample.frequency_hz = resolveFrequency(result);

sample.spacing = struct();
sample.spacing.dx_m = spacingFromAxis(sample.axes.x_m);
sample.spacing.dz_m = spacingFromAxis(sample.axes.z_m);

sample.size_zx = size(sample.wavefield_complex_zx);

if isfield(result, "schema_version")
    sample.result_schema_version = ...
        string(result.schema_version);
else
    sample.result_schema_version = "";
end

if isfield(result, "valid")
    sample.simulation_valid = ...
        logical(result.valid);
else
    sample.simulation_valid = [];
end

if isfield(result, "diagnostics")
    sample.validation = ...
        result.diagnostics;
else
    sample.validation = struct();
end

if isfield(result, "config_resolved")
    sample.config_resolved = ...
        result.config_resolved;
else
    sample.config_resolved = struct();
end

if isfield(result, "provenance")
    sample.provenance = ...
        result.provenance;
else
    sample.provenance = struct();
end

end


function sample = createFrom2D(result, quantity)

container = resolve2DContainer(result, quantity);

required_field = "axial_total_zx";

if ~isfield(container, required_field)
    error("kwsim:MissingReqField", ...
        "2D result is missing fields.%s.%s.", ...
        quantity, required_field);
end

sample = baseSample();

sample.wavefield_complex_zx = ...
    container.(required_field);

sample.units = resolveUnits( ...
    container, ...
    quantity);

sample.phasor_convention = ...
    resolvePhasorConvention(result, container);

sample.axes = struct();
sample.axes.x_m = double(result.axes.x_m(:));
sample.axes.z_m = double(result.axes.z_m(:));

sample.truth = struct();
sample.truth.cs_m_s_zx = ...
    result.truth.cs_m_s_zx;

sample.truth.rho_kg_m3_zx = ...
    result.truth.rho_kg_m3_zx;

sample.truth.material_id_zx = ...
    result.truth.material_id_zx;

sample.extraction = struct();
sample.extraction.method = "native_2d";
sample.extraction.plane = "xz";
sample.extraction.y_index = [];
sample.extraction.y_m = [];

assertSampleSizes(sample);

end


function sample = createFrom3D(result, quantity)

container = resolve3DContainer(result, quantity);

if ~isfield(container, "z_total_zyx")
    if isfield(container, "z_shear_zyx") && ...
            isfield(container, "z_compression_zyx")

        container.z_total_zyx = ...
            container.z_shear_zyx + ...
            container.z_compression_zyx;
    else
        error("kwsim:MissingReqField", ...
            "3D result is missing the z-total harmonic field.");
    end
end

volume_zyx = container.z_total_zyx;

x_m = double(result.axes.x_m(:));
y_m = double(result.axes.y_m(:));
z_m = double(result.axes.z_m(:));

requested_center_y_m = resolveSourceCenterY( ...
    result, ...
    y_m);

[~, y_index] = min(abs( ...
    y_m - requested_center_y_m));

wavefield_zx = reshape( ...
    volume_zyx(:, y_index, :), ...
    size(volume_zyx, 1), ...
    size(volume_zyx, 3));

sample = baseSample();

sample.wavefield_complex_zx = ...
    wavefield_zx;

sample.units = resolveUnits( ...
    container, ...
    quantity);

sample.phasor_convention = ...
    resolvePhasorConvention(result, container);

sample.axes = struct();
sample.axes.x_m = x_m;
sample.axes.z_m = z_m;

sample.truth = struct();

sample.truth.cs_m_s_zx = reshape( ...
    result.truth.cs_m_s_zyx(:, y_index, :), ...
    size(volume_zyx, 1), ...
    size(volume_zyx, 3));

sample.truth.rho_kg_m3_zx = reshape( ...
    result.truth.rho_kg_m3_zyx(:, y_index, :), ...
    size(volume_zyx, 1), ...
    size(volume_zyx, 3));

sample.truth.material_id_zx = reshape( ...
    result.truth.material_id_zyx(:, y_index, :), ...
    size(volume_zyx, 1), ...
    size(volume_zyx, 3));

sample.extraction = struct();
sample.extraction.method = ...
    "central_xz_slice_nearest_source_center";

sample.extraction.plane = "xz";
sample.extraction.y_index = y_index;
sample.extraction.y_m = y_m(y_index);
sample.extraction.requested_center_y_m = ...
    requested_center_y_m;

assertSampleSizes(sample);

end


function container = resolve2DContainer(result, quantity)

if ~isfield(result, "fields") || ...
        ~isfield(result.fields, quantity)

    error("kwsim:MissingReqField", ...
        "2D result is missing fields.%s.", ...
        quantity);
end

container = result.fields.(quantity);

end


function container = resolve3DContainer(result, quantity)

if isfield(result.fields, quantity)
    container = result.fields.(quantity);
    return
end

compatibility_name = ...
    "harmonic_" + quantity;

if isfield(result.fields, compatibility_name)
    container = ...
        result.fields.(compatibility_name);
    return
end

% Backward compatibility for older saved 3D results that contain velocity
% phasors but not the derived displacement container.
if quantity == "displacement" && ...
        isfield(result.fields, "harmonic_velocity")

    velocity = ...
        result.fields.harmonic_velocity;

    if isfield(velocity, "z_total_zyx")
        z_velocity_zyx = ...
            velocity.z_total_zyx;
    elseif isfield(velocity, "z_shear_zyx") && ...
            isfield(velocity, "z_compression_zyx")
        z_velocity_zyx = ...
            velocity.z_shear_zyx + ...
            velocity.z_compression_zyx;
    else
        error("kwsim:MissingReqField", ...
            "Older 3D result has no usable z velocity field.");
    end

    frequency_hz = ...
        resolveFrequency(result);

    container = struct();
    container.z_total_zyx = ...
        z_velocity_zyx / ...
        (1i * 2*pi*frequency_hz);

    container.units = "m";
    container.phasor_convention = ...
        "u(t) = real{U exp(i 2*pi*f*t)}";

    return
end

error("kwsim:MissingReqField", ...
    "3D result is missing fields.%s.", ...
    quantity);

end


function center_y_m = resolveSourceCenterY(result, y_m)

center_y_m = median(y_m);

if isfield(result, "config_resolved") && ...
        isfield(result.config_resolved, "source") && ...
        isfield(result.config_resolved.source, ...
            "center_m_xyz")

    source_center = double( ...
        result.config_resolved.source.center_m_xyz);

    if numel(source_center) == 3 && ...
            isfinite(source_center(2))
        center_y_m = source_center(2);
    end
end

end


function frequency_hz = resolveFrequency(result)

if isfield(result, "fields") && ...
        isfield(result.fields, "frequency_hz")

    frequency_hz = ...
        double(result.fields.frequency_hz);

elseif isfield(result, "axes") && ...
        isfield(result.axes, "f0_hz")

    frequency_hz = ...
        double(result.axes.f0_hz);

elseif isfield(result, "config_resolved") && ...
        isfield(result.config_resolved, "source") && ...
        isfield(result.config_resolved.source, "f0_hz")

    frequency_hz = ...
        double(result.config_resolved.source.f0_hz);

else
    error("kwsim:MissingReqFrequency", ...
        "Could not determine the harmonic frequency.");
end

if ~isscalar(frequency_hz) || ...
        ~isfinite(frequency_hz) || ...
        frequency_hz <= 0
    error("kwsim:InvalidReqFrequency", ...
        "REQ validation frequency must be positive.");
end

end


function units = resolveUnits(container, quantity)

if isfield(container, "units")
    units = string(container.units);
elseif quantity == "displacement"
    units = "m";
else
    units = "m/s";
end

end


function convention = ...
    resolvePhasorConvention(result, container)

if isfield(container, "phasor_convention")
    convention = ...
        string(container.phasor_convention);
elseif isfield(result.fields, "phasor_convention")
    convention = ...
        string(result.fields.phasor_convention);
else
    convention = "";
end

end


function spacing_m = spacingFromAxis(axis_m)

axis_m = double(axis_m(:));

if numel(axis_m) < 2
    spacing_m = NaN;
else
    spacing_m = median(diff(axis_m));
end

end


function assertSampleSizes(sample)

expected_size = [
    numel(sample.axes.z_m), ...
    numel(sample.axes.x_m)
];

if ~isequal( ...
        size(sample.wavefield_complex_zx), ...
        expected_size)
    error("kwsim:InvalidReqSampleSize", ...
        "Wavefield size is inconsistent with x/z axes.");
end

truth_names = [
    "cs_m_s_zx"
    "rho_kg_m3_zx"
    "material_id_zx"
];

for name = truth_names.'
    if ~isequal( ...
            size(sample.truth.(name)), ...
            expected_size)
        error("kwsim:InvalidReqSampleSize", ...
            "Truth map '%s' has an inconsistent size.", ...
            name);
    end
end

end


function sample = baseSample()

sample = struct();
sample.wavefield_complex_zx = [];
sample.axes = struct();
sample.truth = struct();
sample.extraction = struct();

end
