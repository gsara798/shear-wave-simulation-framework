function cfg = defaultConfig()
%DEFAULTCONFIG Baseline configuration for reusable 2D elastic simulations.
%
% All physical values use SI units. Public fields use x for the lateral
% coordinate and z for depth. k-Wave calls its second 2D coordinate y; that
% naming difference is confined to the solver adapter in this package.

cfg = struct();
cfg.schema_version = "3.0";
cfg.scenario = "homogeneous_directional";
cfg.seed = 1001;

% Grid defaults give eight points per 4 mm shear wavelength at 500 Hz.
cfg.grid = struct();
cfg.grid.Nx = 96;
cfg.grid.Nz = 96;
cfg.grid.dx_m = 0.5e-3;
cfg.grid.dz_m = 0.5e-3;
cfg.grid.cfl = 0.20;
cfg.grid.minimum_shear_ppw = 8;

% The baseline configuration is lossless; attenuation is enabled explicitly.
cfg.medium = struct();
cfg.medium.cs_m_s = 2.0;
cfg.medium.rho_kg_m3 = 1000;
cfg.medium.cp_mode = "reduced";
cfg.medium.reduced_cp_factor = 10;
cfg.medium.physical_cp_m_s = 1540;

% Geometry objects are applied in array order over this homogeneous
% background. The baseline contains no objects; benchmarks may add geometry
% without changing the solver-facing API.
object_template = struct('type', "", 'name', "", ...
    'center_m_xz', [NaN, NaN], 'radius_m', NaN, ...
    'material_id', uint16(0), 'cs_m_s', NaN, 'rho_kg_m3', NaN);
cfg.geometry = struct();
cfg.geometry.objects = repmat(object_template, 0, 1);
cfg.geometry.minimum_boundary_clearance_m = 2e-3;
cfg.geometry.require_objects_inside_sensor_roi = true;

% The source is a prescribed axial velocity over a small contact region.
% A left-side source with axial motion is transverse to its main (+x)
% propagation direction and therefore preferentially launches shear waves.
cfg.source = struct();
% Source layout is independent of the project stage. This allows later
% physics stages to reuse the validated single-contact benchmark without
% being forced to construct a perimeter vibrator bank.
cfg.source.layout = "single_contact";
cfg.source.side = "left";
cfg.source.f0_hz = 500;
cfg.source.velocity_amplitude_m_s = 1e-6;
% A 1 mm half-extent gives an approximately 2 mm total contact height.
cfg.source.contact_radius_m = 1e-3;
cfg.source.contact_model = "finite_segment";
cfg.source.contact_sampling = "sparse_patch";
cfg.source.contact_profile = "uniform";
cfg.source.contact_node_spacing_points = 2;
cfg.source.ramp_cycles = 3;
cfg.source.phase_rad = 0;
cfg.source.mode = "dirichlet";
cfg.source.regime = "single";
cfg.source.vibrator_count = 1;
cfg.source.target_angle_deg = 0;
cfg.source.coherent_power_fraction = 1;
cfg.source.total_drive_rms_squared_m2_s2 = 1.5e-12;
cfg.source.perimeter_margin_m = 4e-3;

cfg.time = struct();
cfg.time.analysis_cycles = 8;
cfg.time.settling_cycles = 2;
cfg.time.end_time_s = [];  % Empty selects the conservative automatic value.

cfg.sensor = struct();
cfg.sensor.source_buffer_m = 4e-3;
cfg.sensor.boundary_margin_m = 2e-3;

cfg.solver = struct();
cfg.solver.backend = "cpu";
cfg.solver.data_cast = "single";
cfg.solver.pml_inside = false;
cfg.solver.pml_size_points = 20;
cfg.solver.pml_alpha = 2;
cfg.solver.plot_simulation = false;
cfg.solver.kwave_path = "";

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
cfg.output.save_figures = true;
cfg.output.save_matlab_figures = true;

% pstdElastic2D implements f^2 Kelvin-Voigt absorption. The attenuation benchmark reproduces
% an arbitrary target power law across independent monofrequency runs by
% recalibrating this coefficient at each source frequency. Disabled means
% the absorption fields are omitted entirely from the solver medium.
cfg.attenuation = struct();
cfg.attenuation.enabled = false;
cfg.attenuation.model = "monofrequency_power_law";
cfg.attenuation.materials = kwsim.materials.makeAttenuationMaterial(1);

% Thresholds are part of the result contract, so every reported pass/fail
% can be reconstructed from the saved configuration.
cfg.diagnostics = struct();
cfg.diagnostics.fail_on_invalid = true;
cfg.diagnostics.maximum_sensor_memory_bytes = 2e9;
cfg.diagnostics.minimum_source_fundamental_fraction = 0.999;
cfg.diagnostics.maximum_p_to_s_energy_ratio = 0.05;
cfg.diagnostics.maximum_steady_state_change = 0.01;
cfg.diagnostics.maximum_speed_relative_error = 0.02;
cfg.diagnostics.minimum_grid_correlation = 0.98;
cfg.diagnostics.maximum_pml_relative_difference = 0.01;
cfg.diagnostics.maximum_repeat_relative_error = 1e-7;
cfg.diagnostics.maximum_geometry_area_relative_error = 0.05;
cfg.diagnostics.maximum_axial_symmetry_error = 0.02;
cfg.diagnostics.maximum_zero_contrast_relative_error = 1e-6;
cfg.diagnostics.angular_bin_width_deg = 5;
cfg.diagnostics.angular_annulus_relative_halfwidth = 0.35;
cfg.diagnostics.directional_half_angle_deg = 15;
cfg.diagnostics.minimum_directional_concentration = 0.80;
cfg.diagnostics.minimum_diffuse_angular_entropy = 0.75;
cfg.diagnostics.minimum_partial_metric_margin = 0.10;
cfg.diagnostics.maximum_drive_power_relative_error = 0.01;
% pstdElastic2D Dirichlet contacts became non-stationary below this spacing
% in finite-contact sweeps. Point contacts are exempt because they own one node.
cfg.diagnostics.minimum_finite_contact_node_spacing_points = 4;
cfg.diagnostics.maximum_contact_span_relative_error = 0.05;
cfg.diagnostics.maximum_contact_profile_symmetry_error = 1e-12;
cfg.diagnostics.maximum_attenuation_relative_error = 0.05;
cfg.diagnostics.maximum_power_law_exponent_absolute_error = 0.05;
cfg.diagnostics.maximum_attenuated_speed_relative_difference = 0.02;
cfg.diagnostics.minimum_attenuation_fit_r_squared = 0.98;
cfg.diagnostics.minimum_attenuation_fit_points = 8;
cfg.diagnostics.attenuation_fit_relative_amplitude_floor = 0.20;
cfg.diagnostics.attenuation_fit_half_width_m = 1e-3;
cfg.diagnostics.attenuation_fit_downstream_wavelengths = 1.5;

end
