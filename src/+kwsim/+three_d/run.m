function result = run(requested_cfg)
%RUN Execute and package a public 3D harmonic elastic simulation.
%
% This is the high-level reusable 3D API:
%
%   result = kwsim.three_d.run(cfg)
%
% Processing chain:
%
%   pstdElastic3D time series
%           ->
%   harmonic extraction at source.f0_hz
%           ->
%   public complex volumes [Nz_roi,Ny_roi,Nx_roi]
%
% Public spatial arrays use [Nz,Ny,Nx] orientation and carry a _zyx suffix.
% Solver-native temporal output is retained only when
% cfg.output.save_time_series is true.

arguments
    requested_cfg struct
end

%% Run the low-level solver adapter

raw = kwsim.three_d.runRaw(requested_cfg);
cfg = raw.cfg;

%% Define native-to-public component mapping

component_map = {
    "ux_split_p", "x_compression_zyx"
    "ux_split_s", "x_shear_zyx"
    "uy_split_p", "y_compression_zyx"
    "uy_split_s", "y_shear_zyx"
    "uz_split_p", "z_compression_zyx"
    "uz_split_s", "z_shear_zyx"
};

harmonic_velocity = struct();
offset_summary = struct();
common_harmonic_metadata = struct();

for component_index = 1:size(component_map, 1)
    native_name = component_map{component_index, 1};
    public_name = component_map{component_index, 2};

    sensor_values = raw.sensor_data.(native_name);

    [phasor_points, extraction_metadata] = ...
        kwsim.three_d.extractHarmonicSensorData( ...
            sensor_values, ...
            cfg.time.t_record_s, ...
            cfg.source.f0_hz, ...
            Method=cfg.analysis.harmonic_method, ...
            Window=cfg.analysis.temporal_window, ...
            RemoveMean=cfg.analysis.remove_mean);

    harmonic_velocity.(public_name) = ...
        kwsim.three_d.restoreSensorVolume( ...
            phasor_points, ...
            raw.metadata.sensor);

    component_offset = extraction_metadata.offset;

    offset_summary.(public_name) = struct( ...
        'mean', mean(component_offset), ...
        'rms', sqrt(mean(abs(component_offset).^2)), ...
        'maximum_absolute', max(abs(component_offset)));

    if component_index == 1
        common_harmonic_metadata = ...
            rmfield(extraction_metadata, "offset");
    end
end

%% Build dimension-independent velocity and displacement contracts

harmonic_velocity.x_total_zyx = ...
    harmonic_velocity.x_shear_zyx + ...
    harmonic_velocity.x_compression_zyx;

harmonic_velocity.y_total_zyx = ...
    harmonic_velocity.y_shear_zyx + ...
    harmonic_velocity.y_compression_zyx;

harmonic_velocity.z_total_zyx = ...
    harmonic_velocity.z_shear_zyx + ...
    harmonic_velocity.z_compression_zyx;

harmonic_velocity.units = "m/s";
harmonic_velocity.phasor_convention = ...
    "v(t) = real{V exp(i 2*pi*f*t)}";

harmonic_displacement = struct();

spatial_field_names = {
    "x_shear_zyx"
    "x_compression_zyx"
    "x_total_zyx"
    "y_shear_zyx"
    "y_compression_zyx"
    "y_total_zyx"
    "z_shear_zyx"
    "z_compression_zyx"
    "z_total_zyx"
};

angular_frequency_rad_s = ...
    2*pi*cfg.source.f0_hz;

for field_index = 1:numel(spatial_field_names)
    field_name = spatial_field_names{field_index};

    harmonic_displacement.(field_name) = ...
        harmonic_velocity.(field_name) / ...
        (1i * angular_frequency_rad_s);
end

harmonic_displacement.units = "m";
harmonic_displacement.phasor_convention = ...
    "u(t) = real{U exp(i 2*pi*f*t)}";

%% Crop and orient truth maps to the public sensor ROI

x_indices = cfg.sensor.x_indices;
y_indices = cfg.sensor.y_indices;
z_indices = cfg.sensor.z_indices;

truth = struct();

truth.cp_m_s_zyx = toPublicRoi( ...
    raw.truth_internal.cp_m_s_xyz, ...
    x_indices, y_indices, z_indices);

truth.cs_m_s_zyx = toPublicRoi( ...
    raw.truth_internal.cs_m_s_xyz, ...
    x_indices, y_indices, z_indices);

truth.rho_kg_m3_zyx = toPublicRoi( ...
    raw.truth_internal.rho_kg_m3_xyz, ...
    x_indices, y_indices, z_indices);

truth.material_id_zyx = toPublicRoi( ...
    raw.truth_internal.material_id_xyz, ...
    x_indices, y_indices, z_indices);

truth.homogeneous = raw.truth_internal.homogeneous;
truth.attenuation = raw.truth_internal.attenuation;
truth.orientation = "[Nz,Ny,Nx]";
truth.roi = "sensor";

%% Package public result

result = struct();

result.schema_version = cfg.schema_version;
result.dimension = 3;

% Dimension-independent public configuration contract.
result.config_requested = requested_cfg;
result.config_resolved = cfg;

% Temporary compatibility alias. Remove after all callers use
% result.config_resolved.
result.cfg = cfg;

result.preflight = raw.preflight;
result.runtime_s = raw.metadata.elapsed_time_s;

result.axes = struct();
result.axes.x_m = raw.metadata.sensor.x_m;
result.axes.y_m = raw.metadata.sensor.y_m;
result.axes.z_m = raw.metadata.sensor.z_m;
result.axes.t_record_s = cfg.time.t_record_s;
result.axes.spatial_orientation = "[Nz,Ny,Nx]";
result.axes.temporal_units = "s";
result.axes.spatial_units = "m";

result.fields = struct();

% Preferred dimension-independent containers.
result.fields.velocity = harmonic_velocity;
result.fields.displacement = harmonic_displacement;

% Compatibility aliases for existing 3D validation and visualization code.
result.fields.harmonic_velocity = harmonic_velocity;
result.fields.harmonic_displacement = harmonic_displacement;

result.fields.phasor_convention = ...
    harmonic_displacement.phasor_convention;

result.fields.frequency_hz = cfg.source.f0_hz;
result.fields.spatial_orientation = "[Nz,Ny,Nx]";

result.truth = truth;

result.metadata = raw.metadata;
result.metadata.harmonic_extraction = common_harmonic_metadata;
result.metadata.harmonic_offset_summary = offset_summary;
result.metadata.public_volume_size_zyx = [
    numel(result.axes.z_m), ...
    numel(result.axes.y_m), ...
    numel(result.axes.x_m)
];
result.metadata.native_time_series_retained = ...
    cfg.output.save_time_series;

result.provenance = struct();
result.provenance.framework = ...
    "shear-wave-simulation-framework";
result.provenance.dimension = 3;
result.provenance.solver = raw.metadata.solver_name;
result.provenance.solver_path = raw.metadata.solver_path;
result.provenance.kwave_root = raw.metadata.kwave_root;
result.provenance.harmonic_method = ...
    cfg.analysis.harmonic_method;
result.provenance.temporal_window = ...
    cfg.analysis.temporal_window;

if cfg.output.save_time_series
    result.time_series = struct();
    result.time_series.sensor_data = raw.sensor_data;
    result.time_series.native_layout = ...
        "[sensor_point,time]";
end

end


function roi_zyx = toPublicRoi( ...
    full_xyz, x_indices, y_indices, z_indices)

roi_xyz = full_xyz( ...
    x_indices, ...
    y_indices, ...
    z_indices);

roi_zyx = permute(roi_xyz, [3, 2, 1]);

end
