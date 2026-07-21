function [cfg, preflight] = validateConfig(requested_cfg)
%VALIDATECONFIG Validate and resolve a 3D elastic simulation configuration.
%
% This function performs no simulation. It resolves the compressional
% speed, physical axes, source-contact sampling, sensor ROI, spatial
% resolution, and memory preflight before invoking k-Wave.

arguments
    requested_cfg struct
end

cfg = requested_cfg;

required_top_level = [
    "schema_version"
    "dimension"
    "scenario"
    "seed"
    "grid"
    "medium"
    "geometry"
    "source"
    "time"
    "sensor"
    "solver"
    "execution"
    "output"
    "analysis"
    "attenuation"
    "diagnostics"
];

for name = required_top_level.'
    assertField(cfg, name, "configuration");
end

if cfg.dimension ~= 3
    error("kwsim:Invalid3DConfig", ...
        "three_d configurations must set dimension to 3.");
end

%% Grid

positiveInteger(cfg.grid.Nx, "grid.Nx");
positiveInteger(cfg.grid.Ny, "grid.Ny");
positiveInteger(cfg.grid.Nz, "grid.Nz");

if any([cfg.grid.Nx, cfg.grid.Ny, cfg.grid.Nz] < 16)
    error("kwsim:Invalid3DConfig", ...
        "Every 3D grid dimension must contain at least 16 points.");
end

positiveScalar(cfg.grid.dx_m, "grid.dx_m");
positiveScalar(cfg.grid.dy_m, "grid.dy_m");
positiveScalar(cfg.grid.dz_m, "grid.dz_m");
positiveScalar(cfg.grid.cfl, "grid.cfl");
positiveScalar(cfg.grid.minimum_shear_ppw, ...
    "grid.minimum_shear_ppw");

if cfg.grid.cfl > 0.30
    error("kwsim:Invalid3DConfig", ...
        "The validated 3D foundation requires grid.cfl <= 0.30.");
end

%% Medium

positiveScalar(cfg.medium.cs_m_s, "medium.cs_m_s");
positiveScalar(cfg.medium.rho_kg_m3, "medium.rho_kg_m3");

cp_mode = lower(string(cfg.medium.cp_mode));

switch cp_mode
    case "reduced"
        positiveScalar(cfg.medium.reduced_cp_factor, ...
            "medium.reduced_cp_factor");

        cfg.medium.cp_m_s = ...
            cfg.medium.reduced_cp_factor * cfg.medium.cs_m_s;

    case "physical"
        positiveScalar(cfg.medium.physical_cp_m_s, ...
            "medium.physical_cp_m_s");

        cfg.medium.cp_m_s = cfg.medium.physical_cp_m_s;

    otherwise
        error("kwsim:Invalid3DConfig", ...
            "medium.cp_mode must be 'reduced' or 'physical'.");
end

% Positive isotropic bulk modulus requires cp/cs > sqrt(4/3).
cp_to_cs_ratio = cfg.medium.cp_m_s / cfg.medium.cs_m_s;

if cp_to_cs_ratio <= sqrt(4/3)
    error("kwsim:Invalid3DConfig", ...
        "medium.cp_m_s / medium.cs_m_s must exceed sqrt(4/3).");
end

%% Source physical parameters

positiveScalar(cfg.source.f0_hz, "source.f0_hz");
positiveScalar(cfg.source.velocity_amplitude_m_s, ...
    "source.velocity_amplitude_m_s");
positiveScalar(cfg.source.contact_radius_m, ...
    "source.contact_radius_m");
positiveScalar(cfg.source.ramp_cycles, ...
    "source.ramp_cycles");
positiveScalar(cfg.source.boundary_margin_m, ...
    "source.boundary_margin_m");
positiveInteger(cfg.source.contact_node_spacing_points, ...
    "source.contact_node_spacing_points");

source_layout = ...
    lower(string(cfg.source.layout));

valid_source_layouts = [
    "single_contact"
    "vibrator_bank"
];

if ~any(source_layout == valid_source_layouts)
    error( ...
        "kwsim:Invalid3DConfig", ...
        "source.layout must be single_contact or vibrator_bank.");
end

if lower(string(cfg.source.side)) ~= "left"
    error( ...
        "kwsim:Invalid3DConfig", ...
        "The current 3D source layouts require source.side=left.");
end

if lower(string(cfg.source.contact_model)) ~= "finite_disk"
    error( ...
        "kwsim:Invalid3DConfig", ...
        "The 3D contact_model must be finite_disk.");
end

if lower(string(cfg.source.contact_sampling)) ~= "sparse_patch"
    error( ...
        "kwsim:Invalid3DConfig", ...
        "Finite disks must use sparse_patch sampling.");
end

if lower(string(cfg.source.contact_profile)) ~= "uniform"
    error( ...
        "kwsim:Invalid3DConfig", ...
        "Finite contacts currently use a uniform velocity profile.");
end

if lower(string(cfg.source.mode)) ~= "dirichlet"
    error( ...
        "kwsim:Invalid3DConfig", ...
        "The current 3D contacts require dirichlet velocity.");
end

if source_layout == "single_contact"
    polarization = ...
        double(cfg.source.polarization_xyz(:));

    direction = ...
        double(cfg.source.target_direction_xyz(:));

    if numel(polarization) ~= 3 || ...
            any(~isfinite(polarization)) || ...
            norm(polarization) == 0
        error( ...
            "kwsim:Invalid3DConfig", ...
            "source.polarization_xyz must be a finite nonzero 3-vector.");
    end

    if numel(direction) ~= 3 || ...
            any(~isfinite(direction)) || ...
            norm(direction) == 0
        error( ...
            "kwsim:Invalid3DConfig", ...
            "source.target_direction_xyz must be a finite nonzero 3-vector.");
    end

    polarization = ...
        polarization / norm(polarization);

    direction = ...
        direction / norm(direction);

    if abs(dot(polarization, direction)) > 1e-12
        error( ...
            "kwsim:Invalid3DConfig", ...
            "The source polarization must be transverse to propagation.");
    end

    cfg.source.polarization_xyz = ...
        polarization.';

    cfg.source.target_direction_xyz = ...
        direction.';
else
    positiveInteger( ...
        cfg.source.vibrator_count, ...
        "source.vibrator_count");
end

%% Wavelength and spatial resolution

lambda_s_m = cfg.medium.cs_m_s / cfg.source.f0_hz;

ppw_xyz = lambda_s_m ./ [
    cfg.grid.dx_m, ...
    cfg.grid.dy_m, ...
    cfg.grid.dz_m
];

if any(ppw_xyz < cfg.grid.minimum_shear_ppw)
    error("kwsim:Invalid3DConfig", ...
        "The 3D grid does not satisfy minimum shear points per wavelength.");
end

%% Physical axes

cfg.derived = struct();

cfg.derived.x_full_m = ...
    (0:(cfg.grid.Nx - 1)) * cfg.grid.dx_m;

cfg.derived.y_full_m = ...
    (0:(cfg.grid.Ny - 1)) * cfg.grid.dy_m;

cfg.derived.z_full_m = ...
    (0:(cfg.grid.Nz - 1)) * cfg.grid.dz_m;

cfg.derived.domain_size_m_xyz = [
    (cfg.grid.Nx - 1) * cfg.grid.dx_m, ...
    (cfg.grid.Ny - 1) * cfg.grid.dy_m, ...
    (cfg.grid.Nz - 1) * cfg.grid.dz_m
];

%% Resolve the configured source layout

switch source_layout
    case "single_contact"
        [cfg, source_x] = ...
            kwsim.three_d.resolveSingleContactConfig(cfg);

    case "vibrator_bank"
        [cfg, source_x] = ...
            kwsim.three_d.resolveVibratorBankConfig(cfg);

    otherwise
        error( ...
            "kwsim:Invalid3DConfig", ...
            "Unsupported source layout after validation.");
end

%% Resolve the cuboidal analysis sensor

positiveScalar(cfg.sensor.source_buffer_m, ...
    "sensor.source_buffer_m");
positiveScalar(cfg.sensor.boundary_margin_m, ...
    "sensor.boundary_margin_m");

boundary_x = ...
    round(cfg.sensor.boundary_margin_m / cfg.grid.dx_m);
boundary_y = ...
    round(cfg.sensor.boundary_margin_m / cfg.grid.dy_m);
boundary_z = ...
    round(cfg.sensor.boundary_margin_m / cfg.grid.dz_m);

source_buffer_x = ...
    round(cfg.sensor.source_buffer_m / cfg.grid.dx_m);

x_start = source_x + source_buffer_x + 1;
x_end = cfg.grid.Nx - boundary_x;

y_start = 1 + boundary_y;
y_end = cfg.grid.Ny - boundary_y;

z_start = 1 + boundary_z;
z_end = cfg.grid.Nz - boundary_z;

if x_start > x_end || y_start > y_end || z_start > z_end
    error("kwsim:Invalid3DConfig", ...
        "The 3D sensor ROI is empty; enlarge the grid or reduce margins.");
end

cfg.sensor.x_indices = x_start:x_end;
cfg.sensor.y_indices = y_start:y_end;
cfg.sensor.z_indices = z_start:z_end;

cfg.derived.sensor_size_xyz = [
    numel(cfg.sensor.x_indices), ...
    numel(cfg.sensor.y_indices), ...
    numel(cfg.sensor.z_indices)
];

cfg.derived.sensor_points = prod(cfg.derived.sensor_size_xyz);

actual_source_buffer_m = ...
    (x_start - source_x) * cfg.grid.dx_m;

if actual_source_buffer_m < cfg.sensor.source_buffer_m
    error("kwsim:Invalid3DConfig", ...
        "The realized source-to-sensor buffer is smaller than requested.");
end

%% Solver configuration

if ~(islogical(cfg.solver.pml_inside) && ...
        isscalar(cfg.solver.pml_inside) && ...
        ~cfg.solver.pml_inside)
    error("kwsim:Invalid3DConfig", ...
        "The validated 3D foundation requires an exterior PML.");
end

pml_size = double(cfg.solver.pml_size_points);

if ~(isnumeric(pml_size) && numel(pml_size) == 3 && ...
        all(isfinite(pml_size)) && ...
        all(pml_size == fix(pml_size)) && ...
        all(pml_size >= 8))
    error("kwsim:Invalid3DConfig", ...
        "solver.pml_size_points must contain three integers >= 8.");
end

cfg.solver.pml_size_points = reshape(pml_size, 1, 3);

positiveScalar(cfg.solver.pml_alpha, ...
    "solver.pml_alpha");

if lower(string(cfg.solver.backend)) ~= "cpu"
    error("kwsim:Invalid3DConfig", ...
        "The reproducible 3D foundation currently requires the CPU backend.");
end

if lower(string(cfg.solver.data_cast)) ~= "single"
    error("kwsim:Invalid3DConfig", ...
        "The reproducible 3D foundation uses single precision.");
end

%% Harmonic analysis configuration

assertField(cfg.analysis, "harmonic_method", "analysis");
assertField(cfg.analysis, "temporal_window", "analysis");
assertField(cfg.analysis, "remove_mean", "analysis");

harmonic_method = lower(string(cfg.analysis.harmonic_method));

valid_harmonic_methods = [
    "least_squares"
    "fourier_projection"
    "fft_bin"
];

if ~any(harmonic_method == valid_harmonic_methods)
    error("kwsim:Invalid3DConfig", ...
        "analysis.harmonic_method must be least_squares, " + ...
        "fourier_projection, or fft_bin.");
end

temporal_window = lower(string(cfg.analysis.temporal_window));

valid_temporal_windows = [
    "none"
    "hann"
];

if ~any(temporal_window == valid_temporal_windows)
    error("kwsim:Invalid3DConfig", ...
        "analysis.temporal_window must be none or hann.");
end

if ~(islogical(cfg.analysis.remove_mean) && ...
        isscalar(cfg.analysis.remove_mean))
    error("kwsim:Invalid3DConfig", ...
        "analysis.remove_mean must be a logical scalar.");
end

cfg.analysis.harmonic_method = harmonic_method;
cfg.analysis.temporal_window = temporal_window;

%% Memory preflight

memory = kwsim.three_d.estimateMemory(cfg);

if ~memory.within_limit && cfg.execution.fail_on_memory_limit
    error("kwsim:MemoryLimitExceeded", ...
        "Estimated 3D solver memory %.3f GB exceeds the configured " + ...
        "limit of %.3f GB.", ...
        memory.estimated_solver_gb, ...
        memory.maximum_allowed_bytes / 1e9);
end

%% Preflight report

preflight = struct();
preflight.lambda_s_m = lambda_s_m;
preflight.shear_ppw_xyz = ppw_xyz;
preflight.domain_size_m_xyz = cfg.derived.domain_size_m_xyz;
preflight.cp_m_s = cfg.medium.cp_m_s;
preflight.cs_m_s = cfg.medium.cs_m_s;
preflight.cp_to_cs_ratio = cp_to_cs_ratio;
preflight.memory = memory;

preflight.source = struct();
preflight.source.center_index_xyz = ...
    cfg.source.center_index_xyz;
preflight.source.center_m_xyz = ...
    cfg.source.center_m_xyz;
preflight.source.contact_node_count = ...
    cfg.source.contact_node_count;
preflight.source.realized_radius_y_m = ...
    cfg.source.realized_radius_y_m;
preflight.source.realized_radius_z_m = ...
    cfg.source.realized_radius_z_m;

preflight.sensor = struct();
preflight.sensor.size_xyz = cfg.derived.sensor_size_xyz;
preflight.sensor.point_count = cfg.derived.sensor_points;
preflight.sensor.actual_source_buffer_m = ...
    actual_source_buffer_m;

preflight.public_orientation = "[Nz,Ny,Nx]";
preflight.internal_orientation = "[Nx,Ny,Nz]";

end

function assertField(value, field_name, parent_name)
if ~isfield(value, field_name)
    error("kwsim:Invalid3DConfig", ...
        "%s is missing required field '%s'.", parent_name, field_name);
end
end

function positiveScalar(value, name)
if ~(isnumeric(value) && isscalar(value) && ...
        isfinite(value) && value > 0)
    error("kwsim:Invalid3DConfig", ...
        "%s must be a finite positive scalar.", name);
end
end

function positiveInteger(value, name)
positiveScalar(value, name);

if value ~= fix(value)
    error("kwsim:Invalid3DConfig", ...
        "%s must be a positive integer.", name);
end
end
