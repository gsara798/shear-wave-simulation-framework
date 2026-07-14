function [cfg, preflight] = validateConfig(cfg)
%VALIDATECONFIG Validate and resolve a homogeneous or heterogeneous 2D configuration.
%
% [resolved_cfg, preflight] = kwsim.two_d.validateConfig(cfg)
%
% This function performs no simulation. It resolves derived grid indices,
% the reduced compressional speed, automatic duration, recording interval,
% and a conservative sensor-memory estimate. Invalid physical or numerical
% configurations fail here rather than deep inside k-Wave.

arguments
    cfg struct
end

checks = repmat(emptyCheck(), 0, 1);

required_top_level = ["grid", "medium", "geometry", "source", "time", ...
    "sensor", "solver", "output", "diagnostics", "seed", "stage", "scenario"];
for name = required_top_level
    addCheck("field_" + name, isfield(cfg, name), double(isfield(cfg, name)), 1, ...
        "Required configuration field: " + name);
end
if any(~[checks.pass])
    throwPreflight(checks);
end

Nx = cfg.grid.Nx;
Nz = cfg.grid.Nz;
dx = cfg.grid.dx_m;
dz = cfg.grid.dz_m;
cs = cfg.medium.cs_m_s;
rho = cfg.medium.rho_kg_m3;
f0 = cfg.source.f0_hz;

addCheck("Nx_integer", isIntegerScalar(Nx) && Nx >= 32, Nx, 32, ...
    "Nx must be an integer of at least 32 points.");
addCheck("Nz_integer", isIntegerScalar(Nz) && Nz >= 32, Nz, 32, ...
    "Nz must be an integer of at least 32 points.");
addCheck("dx_positive", isPositiveScalar(dx), dx, 0, "dx_m must be positive.");
addCheck("dz_positive", isPositiveScalar(dz), dz, 0, "dz_m must be positive.");
addCheck("isotropic_spacing", isPositiveScalar(dx) && isPositiveScalar(dz) && ...
    abs(dx - dz) <= 10 * eps(max(dx, dz)), abs(dx - dz), 10 * eps(max(dx, dz)), ...
    "The validated 2D implementation requires dx_m == dz_m so rasterized geometry is isotropic.");
addCheck("cs_positive", isPositiveScalar(cs), cs, 0, "cs_m_s must be positive.");
addCheck("density_positive", isPositiveScalar(rho), rho, 0, ...
    "rho_kg_m3 must be positive.");
addCheck("frequency_positive", isPositiveScalar(f0), f0, 0, ...
    "f0_hz must be positive.");
addCheck("cfl_range", isPositiveScalar(cfg.grid.cfl) && cfg.grid.cfl <= 0.30, ...
    cfg.grid.cfl, 0.30, "CFL must be in (0, 0.30] for the validated 2D reference.");
addCheck("pml_outside", islogical(cfg.solver.pml_inside) && ...
    isscalar(cfg.solver.pml_inside) && ~cfg.solver.pml_inside, ...
    double(~cfg.solver.pml_inside), 1, ...
    "The validated 2D runs use an exterior PML so public coordinates exclude it.");
addCheck("pml_size", isIntegerScalar(cfg.solver.pml_size_points) && ...
    cfg.solver.pml_size_points >= 8, cfg.solver.pml_size_points, 8, ...
    "The exterior PML must contain at least eight grid points.");
addCheck("pml_alpha", isPositiveScalar(cfg.solver.pml_alpha), ...
    cfg.solver.pml_alpha, 0, "solver.pml_alpha must be positive.");
addCheck("cpu_backend", lower(string(cfg.solver.backend)) == "cpu", ...
    double(lower(string(cfg.solver.backend)) == "cpu"), 1, ...
    "The reproducible reference backend is CPU.");
addCheck("single_precision", lower(string(cfg.solver.data_cast)) == "single", ...
    double(lower(string(cfg.solver.data_cast)) == "single"), 1, ...
    "The reproducible reference uses single-precision solver arrays.");

if any(~[checks.pass])
    throwPreflight(checks);
end

switch lower(string(cfg.medium.cp_mode))
    case "reduced"
        [geometry_maps, geometry_metadata] = kwsim.two_d.buildGeometry(cfg);
        minimum_cs = geometry_metadata.minimum_cs_m_s;
        maximum_cs = geometry_metadata.maximum_cs_m_s;
        cp = cfg.medium.reduced_cp_factor * maximum_cs;
    case "physical"
        [geometry_maps, geometry_metadata] = kwsim.two_d.buildGeometry(cfg);
        minimum_cs = geometry_metadata.minimum_cs_m_s;
        maximum_cs = geometry_metadata.maximum_cs_m_s;
        cp = cfg.medium.physical_cp_m_s;
    otherwise
        error('kwsim:InvalidCpMode', ...
            'medium.cp_mode must be "reduced" or "physical".');
end

% Positive 3D bulk modulus requires cp/cs > sqrt(4/3). The 2D solver uses
% the same isotropic Lame parameters, so the same physical guard is applied.
cp_ratio = cp / maximum_cs;
addCheck("positive_bulk_modulus", cp_ratio > sqrt(4/3), cp_ratio, sqrt(4/3), ...
    "cp/cs must exceed sqrt(4/3) to avoid a non-physical bulk modulus.");

shear_wavelength_m = minimum_cs / f0;
shear_ppw = shear_wavelength_m / max(dx, dz);
addCheck("shear_ppw", shear_ppw >= cfg.grid.minimum_shear_ppw, ...
    shear_ppw, cfg.grid.minimum_shear_ppw, ...
    "Increase spatial resolution or reduce f0 to meet the shear PPW limit.");

radius_points = round(cfg.source.contact_radius_m / dx);
addCheck("source_resolution", radius_points >= 2, radius_points, 2, ...
    "The vibrator contact radius must span at least two grid points.");
if cfg.stage < 3
    addCheck("source_side", lower(string(cfg.source.side)) == "left", ...
        double(lower(string(cfg.source.side)) == "left"), 1, ...
        "Stages 1 and 2 implement the validated left-side source only.");
else
    valid_regime = any(lower(string(cfg.source.regime)) == ...
        ["directional", "partially_diffuse", "diffuse"]);
    addCheck("source_regime", valid_regime, double(valid_regime), 1, ...
        "Stage 3 source.regime must name a supported field regime.");
    valid_count = isIntegerScalar(cfg.source.vibrator_count) && ...
        cfg.source.vibrator_count >= 1;
    addCheck("vibrator_count", valid_count, cfg.source.vibrator_count, 1, ...
        "source.vibrator_count must be a positive integer.");
    fraction = cfg.source.coherent_power_fraction;
    valid_fraction = isnumeric(fraction) && isscalar(fraction) && ...
        isfinite(fraction) && fraction >= 0 && fraction <= 1;
    addCheck("coherent_power_fraction", valid_fraction, fraction, 1, ...
        "coherent_power_fraction must lie in [0,1].");
    addCheck("source_total_drive", ...
        isPositiveScalar(cfg.source.total_drive_rms_squared_m2_s2), ...
        cfg.source.total_drive_rms_squared_m2_s2, 0, ...
        "The prescribed total RMS-squared velocity drive must be positive.");
    contact_model = lower(string(cfg.source.contact_model));
    valid_contact_model = any(contact_model == ["point", "finite_segment"]);
    addCheck("source_contact_model", valid_contact_model, ...
        double(valid_contact_model), 1, ...
        "contact_model must be point or finite_segment.");
    valid_profile = any(lower(string(cfg.source.contact_profile)) == ...
        ["raised_cosine", "gaussian", "uniform"]);
    addCheck("source_contact_profile", valid_profile, ...
        double(valid_profile), 1, ...
        "contact_profile must be raised_cosine, gaussian, or uniform.");
    spacing_points = cfg.source.contact_node_spacing_points;
    if contact_model == "finite_segment"
        minimum_spacing = ...
            cfg.diagnostics.minimum_finite_contact_node_spacing_points;
    else
        minimum_spacing = 1;
    end
    valid_spacing = isIntegerScalar(spacing_points) && ...
        spacing_points >= minimum_spacing;
    addCheck("source_contact_node_spacing", valid_spacing, spacing_points, ...
        minimum_spacing, ...
        "Finite Dirichlet contact nodes are closer than the validated stable spacing.");
    resolved_node_count = 1 + 2*floor(radius_points/max(spacing_points, 1));
    finite_extent_resolved = contact_model ~= "finite_segment" || ...
        resolved_node_count >= 3;
    addCheck("source_finite_contact_resolution", finite_extent_resolved, ...
        resolved_node_count, 3, ...
        "A finite contact must contain a center and at least two tapered edge nodes.");
    symmetric_contact_grid = contact_model ~= "finite_segment" || ...
        mod(radius_points, max(spacing_points, 1)) == 0;
    addCheck("source_symmetric_contact_sampling", symmetric_contact_grid, ...
        double(symmetric_contact_grid), 1, ...
        "contact_radius_m must resolve to an integer multiple of contact-node spacing.");
    sampling = lower(string(cfg.source.contact_sampling));
    compatible_sampling = (contact_model == "point" && sampling == "point") || ...
        (contact_model == "finite_segment" && sampling == "sparse_patch");
    addCheck("source_contact_sampling_alias", compatible_sampling, ...
        double(compatible_sampling), 1, ...
        "contact_sampling must agree with the selected contact_model.");
end
addCheck("source_mode", lower(string(cfg.source.mode)) == "dirichlet", ...
    double(lower(string(cfg.source.mode)) == "dirichlet"), 1, ...
    "Stage 1 external vibrators use prescribed (dirichlet) velocity.");
addCheck("ramp_cycles", isPositiveScalar(cfg.source.ramp_cycles), ...
    cfg.source.ramp_cycles, 0, "source.ramp_cycles must be positive.");
addCheck("analysis_cycles", isPositiveScalar(cfg.time.analysis_cycles) && ...
    cfg.time.analysis_cycles >= 8, cfg.time.analysis_cycles, 8, ...
    "At least eight steady cycles are required for Stage 1 diagnostics.");

if any(~[checks.pass])
    throwPreflight(checks);
end

source_center_x = radius_points + 2;
% The physical mid-plane lies halfway between nodes for even Nz. Preserve
% that half-index in metadata and select a symmetric non-adjacent contact.
% This removes the former half-pixel symmetry bias without imposing adjacent
% Dirichlet nodes, which are unstable in pstdElastic2D 1.4.1.
source_center_z = (Nz + 1) / 2;
candidate_contact_z = find(abs((1:Nz) - source_center_z) <= radius_points);
contact_offset = abs(candidate_contact_z - source_center_z);
minimum_offset = min(contact_offset);
source_contact_z = candidate_contact_z(contact_offset == max(contact_offset));
if minimum_offset == 0
    source_contact_z = unique([source_contact_z, round(source_center_z)]);
end
source_contact_z = sort(source_contact_z);
source_x_max = source_center_x + radius_points;

boundary_x = round(cfg.sensor.boundary_margin_m / dx);
boundary_z = round(cfg.sensor.boundary_margin_m / dz);
buffer_x = round(cfg.sensor.source_buffer_m / dx);
x_start = source_x_max + buffer_x + 1;
x_end = Nx - boundary_x;
z_start = 1 + boundary_z;
z_end = Nz - boundary_z;

roi_valid = x_start < x_end && z_start < z_end;
addCheck("analysis_roi", roi_valid, double(roi_valid), 1, ...
    "The sensor ROI is empty; enlarge the grid or reduce margins/buffer.");
actual_source_roi_separation_m = (x_start - source_x_max) * dx;
addCheck("source_roi_separation", ...
    actual_source_roi_separation_m >= cfg.sensor.source_buffer_m, ...
    actual_source_roi_separation_m, cfg.sensor.source_buffer_m, ...
    "The realized source-to-ROI separation is smaller than requested.");
if ~roi_valid
    throwPreflight(checks);
end

x_indices = x_start:x_end;
z_indices = z_start:z_end;
x_m = (0:(Nx - 1)) * dx;
z_m = (0:(Nz - 1)) * dz;

source_position_m = [x_m(source_center_x), (source_center_z - 1) * dz];

% Stage 3 resolves every perimeter contact during preflight. The resulting
% labelled mask is reused by the solver, so the geometry and drive checks
% below describe exactly the sources that will be executed.
if cfg.stage >= 3
    source_bank = kwsim.two_d.generateVibratorBank(cfg);
    transverse_error = max(abs(arrayfun(@(v) dot( ...
        v.propagation_xz, v.polarization_xz), source_bank.vibrators)));
    addCheck("source_transverse_polarization", transverse_error <= 1e-12, ...
        transverse_error, 1e-12, ...
        "Every shear vibrator polarization must be transverse to propagation.");
    addCheck("source_drive_normalization", ...
        source_bank.drive_power_relative_error <= ...
        cfg.diagnostics.maximum_drive_power_relative_error, ...
        source_bank.drive_power_relative_error, ...
        cfg.diagnostics.maximum_drive_power_relative_error, ...
        "Realized prescribed drive differs from the requested total.");
    active_source = source_bank.solver_label_mask_xz > 0;
    adjacent_constraints = any(active_source(1:end-1,:) & ...
        active_source(2:end,:), 'all') || any(active_source(:,1:end-1) & ...
        active_source(:,2:end), 'all');
    addCheck("source_nonadjacent_dirichlet_nodes", ~adjacent_constraints, ...
        double(~adjacent_constraints), 1, ...
        "Adjacent prescribed-velocity nodes are disallowed by the validated elastic source model.");
    bank_inside_roi = source_bank.label_mask_xz(x_indices, z_indices) > 0;
    addCheck("source_outside_sensor_roi", ~any(bank_inside_roi, 'all'), ...
        double(~any(bank_inside_roi, 'all')), 1, ...
        "A perimeter vibrator overlaps the analysis ROI.");
else
    source_bank = struct();
end

% Geometry checks use the same rasterization that buildMedium later passes
% to k-Wave. This prevents a configuration from passing with one geometric
% interpretation and running with another.
objects = cfg.geometry.objects;
if isempty(objects)
    object_ids = zeros(0, 1, 'uint16');
else
    object_ids = reshape([objects.material_id], [], 1);
end
unique_object_ids = numel(unique(object_ids)) == numel(object_ids);
addCheck("geometry_material_ids_unique", unique_object_ids, ...
    double(unique_object_ids), 1, ...
    "Every geometry object must use a unique material ID.");

clearance = cfg.geometry.minimum_boundary_clearance_m;
if cfg.stage >= 3
    source_mask = source_bank.label_mask_xz > 0;
    geometry_overlaps_source = any( ...
        geometry_maps.material_id_xz(source_mask) ~= 1);
else
    geometry_overlaps_source = any( ...
        geometry_maps.material_id_xz(source_center_x, source_contact_z) ~= 1);
end
addCheck("geometry_source_separation", ~geometry_overlaps_source, ...
    double(~geometry_overlaps_source), 1, ...
    "A geometry object overlaps the prescribed source contact.");

for object_index = 1:numel(objects)
    object = objects(object_index);
    info = geometry_metadata.objects(object_index);
    prefix = "geometry_" + string(object_index) + "_";
    area_ok = info.area_relative_error <= ...
        cfg.diagnostics.maximum_geometry_area_relative_error;
    addCheck(prefix + "area", area_ok, info.area_relative_error, ...
        cfg.diagnostics.maximum_geometry_area_relative_error, ...
        "Discrete object area differs excessively from its requested physical area.");

    if lower(string(object.type)) == "circle"
        bounds = [object.center_m_xz(1) - object.radius_m, ...
            object.center_m_xz(1) + object.radius_m, ...
            object.center_m_xz(2) - object.radius_m, ...
            object.center_m_xz(2) + object.radius_m];
        boundary_ok = bounds(1) >= clearance && ...
            bounds(2) <= x_m(end) - clearance && ...
            bounds(3) >= clearance && bounds(4) <= z_m(end) - clearance;
        addCheck(prefix + "boundary_clearance", boundary_ok, ...
            double(boundary_ok), 1, ...
            "Geometry object violates the physical-domain boundary clearance.");

        if cfg.geometry.require_objects_inside_sensor_roi
            roi_contains_object = bounds(1) >= x_m(x_start) && ...
                bounds(2) <= x_m(x_end) && bounds(3) >= z_m(z_start) && ...
                bounds(4) <= z_m(z_end);
            addCheck(prefix + "inside_sensor_roi", roi_contains_object, ...
                double(roi_contains_object), 1, ...
                "Geometry object is not fully contained in the sensor ROI.");
        end
    end

    material_mask = geometry_maps.material_id_xz == object.material_id;
    property_assignment_ok = any(material_mask, 'all') && ...
        all(geometry_maps.cs_m_s_xz(material_mask) == object.cs_m_s) && ...
        all(geometry_maps.rho_kg_m3_xz(material_mask) == object.rho_kg_m3);
    addCheck(prefix + "material_assignment", property_assignment_ok, ...
        double(property_assignment_ok), 1, ...
        "Rasterized material properties do not match the object definition.");
end

if any(~[checks.pass])
    throwPreflight(checks);
end

[Xcorners, Zcorners] = ndgrid(x_m([x_start, x_end]), z_m([z_start, z_end]));
if cfg.stage >= 3
    source_positions_m = vertcat(source_bank.vibrators.center_m_xz);
else
    source_positions_m = source_position_m;
end
travel_distance_m = 0;
for source_index = 1:size(source_positions_m, 1)
    distance_m = hypot(Xcorners(:) - source_positions_m(source_index, 1), ...
        Zcorners(:) - source_positions_m(source_index, 2));
    travel_distance_m = max(travel_distance_m, max(distance_m));
end

ramp_duration_s = cfg.source.ramp_cycles / f0;
analysis_duration_s = cfg.time.analysis_cycles / f0;
settling_duration_s = cfg.time.settling_cycles / f0;
automatic_end_time_s = ramp_duration_s + travel_distance_m / minimum_cs + ...
    settling_duration_s + analysis_duration_s;
if isempty(cfg.time.end_time_s)
    end_time_s = automatic_end_time_s;
else
    end_time_s = cfg.time.end_time_s;
end
addCheck("simulation_duration", end_time_s >= automatic_end_time_s, ...
    end_time_s, automatic_end_time_s, ...
    "end_time_s is too short for ramp, propagation, settling, and analysis.");

estimated_dt_s = cfg.grid.cfl * min(dx, dz) / max(cp, cs);
estimated_Nt = ceil(end_time_s / estimated_dt_s) + 1;
estimated_recorded_samples = ceil(analysis_duration_s / estimated_dt_s) + 1;
sensor_points = numel(x_indices) * numel(z_indices);
bytes_per_value = 4; % All current reference runs use single precision.
split_fields_2d = 4;
estimated_sensor_bytes = sensor_points * estimated_recorded_samples * ...
    bytes_per_value * split_fields_2d;
memory_ok = estimated_sensor_bytes <= cfg.diagnostics.maximum_sensor_memory_bytes;
addCheck("sensor_memory", memory_ok, estimated_sensor_bytes, ...
    cfg.diagnostics.maximum_sensor_memory_bytes, ...
    "Estimated split-field sensor storage exceeds the configured limit.");

if any(~[checks.pass])
    throwPreflight(checks);
end

cfg.grid.Nx = round(Nx);
cfg.grid.Nz = round(Nz);
cfg.seed = round(cfg.seed);
cfg.medium.cp_m_s = cp;
cfg.medium.lambda_pa = rho * (cp^2 - 2 * cs^2);
cfg.medium.mu_pa = rho * cs^2;
cfg.medium.minimum_cs_m_s = minimum_cs;
cfg.medium.maximum_cs_m_s = maximum_cs;
cfg.geometry.resolved = rmfield(geometry_metadata, 'object_masks_xz');
cfg.source.contact_radius_points = radius_points;
cfg.source.center_index_xz = [source_center_x, source_center_z];
cfg.source.center_m_xz = source_position_m;
cfg.source.contact_z_indices = source_contact_z;
if cfg.stage >= 3
    cfg.source.resolved_bank = source_bank;
end
cfg.sensor.x_indices = x_indices;
cfg.sensor.z_indices = z_indices;
cfg.time.end_time_s_resolved = end_time_s;
cfg.time.automatic_minimum_end_time_s = automatic_end_time_s;

cfg.derived = struct();
cfg.derived.x_full_m = x_m;
cfg.derived.z_full_m = z_m;
cfg.derived.shear_wavelength_m = shear_wavelength_m;
cfg.derived.shear_points_per_wavelength = shear_ppw;
cfg.derived.travel_distance_m = travel_distance_m;
cfg.derived.source_roi_separation_m = actual_source_roi_separation_m;
cfg.derived.estimated_dt_s = estimated_dt_s;
cfg.derived.estimated_Nt = estimated_Nt;
cfg.derived.estimated_recorded_samples = estimated_recorded_samples;
cfg.derived.sensor_points = sensor_points;
cfg.derived.estimated_sensor_memory_bytes = estimated_sensor_bytes;

preflight = struct();
preflight.valid = all([checks.pass]);
preflight.checks = checks;
preflight.summary = sprintf(['PPW=%.2f, cp/cs=%.2f, estimated Nt=%d, ', ...
    'objects=%d, sensor memory=%.1f MiB'], shear_ppw, cp_ratio, estimated_Nt, ...
    geometry_metadata.object_count, ...
    estimated_sensor_bytes / 2^20);

    function addCheck(name, pass, value, threshold, message)
        check = emptyCheck();
        check.name = string(name);
        check.pass = logical(pass);
        check.value = double(value);
        check.threshold = double(threshold);
        check.message = string(message);
        checks(end + 1, 1) = check;
    end

end

function check = emptyCheck()
check = struct('name', "", 'pass', false, 'value', NaN, ...
    'threshold', NaN, 'message', "");
end

function tf = isPositiveScalar(value)
tf = isnumeric(value) && isscalar(value) && isreal(value) && ...
    isfinite(value) && value > 0;
end

function tf = isIntegerScalar(value)
tf = isnumeric(value) && isscalar(value) && isfinite(value) && ...
    value == round(value);
end

function throwPreflight(checks)
failed = checks(~[checks.pass]);
details_lines = strings(numel(failed), 1);
for index = 1:numel(failed)
    details_lines(index) = failed(index).name + ": " + failed(index).message;
end
details = strjoin(details_lines, newline);
error('kwsim:InvalidConfiguration', 'Preflight validation failed:\n%s', details);
end
