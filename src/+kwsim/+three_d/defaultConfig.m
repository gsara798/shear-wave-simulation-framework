function cfg = defaultConfig()
%DEFAULTCONFIG Baseline configuration for reusable 3D elastic simulations.
%
% All physical values use SI units.
%
% Public coordinates:
%   x: lateral
%   y: elevational / out-of-plane
%   z: axial / depth
%
% k-Wave solver arrays use [Nx,Ny,Nz]. Public result arrays use [Nz,Ny,Nx]
% and carry a _zyx suffix.

cfg = struct();
cfg.schema_version = "3.0";
cfg.dimension = 3;
cfg.scenario = "homogeneous_directional_3d";
cfg.seed = 1001;

% Compact baseline: cs=2 m/s and f0=500 Hz give lambda_s=4 mm.
% A 0.5 mm isotropic grid therefore gives 8 points per shear wavelength.
cfg.grid = struct();
cfg.grid.Nx = 48;
cfg.grid.Ny = 32;
cfg.grid.Nz = 48;
cfg.grid.dx_m = 0.5e-3;
cfg.grid.dy_m = 0.5e-3;
cfg.grid.dz_m = 0.5e-3;
cfg.grid.cfl = 0.20;
cfg.grid.minimum_shear_ppw = 8;

cfg.medium = struct();
cfg.medium.cs_m_s = 2.0;
cfg.medium.rho_kg_m3 = 1000;
cfg.medium.cp_mode = "reduced";
cfg.medium.reduced_cp_factor = 10;
cfg.medium.physical_cp_m_s = 1540;

object_template = struct( ...
    'type', "", ...
    'name', "", ...
    'center_m_xyz', [NaN, NaN, NaN], ...
    'radius_m', NaN, ...
    'material_id', uint16(0), ...
    'cs_m_s', NaN, ...
    'rho_kg_m3', NaN);

cfg.geometry = struct();
cfg.geometry.objects = repmat(object_template, 0, 1);
cfg.geometry.minimum_boundary_clearance_m = 2e-3;
cfg.geometry.require_objects_inside_sensor_roi = true;

% Initial 3D benchmark: one finite surface contact on the left x-face.
% Polarization is axial (+z), transverse to the principal +x propagation.
cfg.source = struct();
cfg.source.layout = "single_contact";
cfg.source.side = "left";
cfg.source.f0_hz = 500;
cfg.source.velocity_amplitude_m_s = 1e-6;
cfg.source.contact_model = "finite_disk";
cfg.source.contact_radius_m = 1e-3;
cfg.source.contact_profile = "uniform";
cfg.source.contact_sampling = "sparse_patch";
cfg.source.contact_node_spacing_points = 2;
cfg.source.ramp_cycles = 3;
cfg.source.phase_rad = 0;
cfg.source.mode = "dirichlet";
cfg.source.polarization_xyz = [0, 0, 1];
cfg.source.target_direction_xyz = [1, 0, 0];
cfg.source.regime = "single";
cfg.source.vibrator_count = 1;
cfg.source.boundary_margin_m = 4e-3;

cfg.time = struct();
cfg.time.analysis_cycles = 8;
cfg.time.settling_cycles = 2;
cfg.time.end_time_s = [];

% The baseline records a central cuboid ROI, not the entire PML region.
cfg.sensor = struct();
cfg.sensor.source_buffer_m = 4e-3;
cfg.sensor.boundary_margin_m = 2e-3;
cfg.sensor.save_full_volume = true;

cfg.solver = struct();
cfg.solver.backend = "cpu";
cfg.solver.data_cast = "single";
cfg.solver.pml_inside = false;
cfg.solver.pml_size_points = [12, 12, 12];
cfg.solver.pml_alpha = 2;
cfg.solver.plot_simulation = false;
cfg.solver.kwave_path = "";

cfg.execution = struct();
cfg.execution.maximum_memory_bytes = 8e9;
cfg.execution.fail_on_memory_limit = true;

cfg.output = struct();

% Output organization
cfg.output.enabled = false;
cfg.output.directory = "outputs";
cfg.output.run_name = "";
cfg.output.append_timestamp = true;
cfg.output.overwrite = false;

% Saved products
cfg.output.save_result = true;
cfg.output.save_summary = true;
cfg.output.save_config_mat = true;
cfg.output.save_config_json = true;
cfg.output.save_time_series = false;

% Export a lightweight 2D complex field for external REQ validation.
cfg.output.save_req_validation_sample = false;

cfg.output.save_figures = true;
cfg.output.save_matlab_figures = true;

% Temporal reduction from simulated time series to complex fields at f0.
cfg.analysis = struct();
cfg.analysis.harmonic_method = "least_squares";
cfg.analysis.temporal_window = "none";
cfg.analysis.remove_mean = true;

% Parameters used only to assess whether an exported field is large
% enough for the external REQ validation pipeline.
cfg.req_validation = struct();
cfg.req_validation.quantity = "displacement";
cfg.req_validation.cs_guess_m_s = 3.0;
cfg.req_validation.window_wavelengths = 2.0;
cfg.req_validation.minimum_placements_per_axis = 5;

cfg.attenuation = struct();
cfg.attenuation.enabled = false;
cfg.attenuation.model = "monofrequency_power_law";
cfg.attenuation.materials = kwsim.materials.makeAttenuationMaterial(1);

cfg.diagnostics = struct();
cfg.diagnostics.fail_on_invalid = true;
cfg.diagnostics.maximum_speed_relative_error = 0.05;
cfg.diagnostics.maximum_frequency_relative_error = 0.005;
cfg.diagnostics.maximum_cross_polarization_ratio = 0.05;
cfg.diagnostics.maximum_longitudinal_leakage_ratio = 0.05;
cfg.diagnostics.maximum_symmetry_error = 0.05;
cfg.diagnostics.maximum_repeat_relative_error = 1e-7;
cfg.diagnostics.minimum_source_fundamental_fraction = 0.999;

end
