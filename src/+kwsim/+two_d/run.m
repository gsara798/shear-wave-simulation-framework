function [result, report] = run(requested_cfg)
%RUN Execute and diagnose one configured 2D elastic simulation.
%
% [result, report] = kwsim.two_d.run(cfg)
%
% Public arrays are [Nz,Nx], with x lateral and z axial/depth. k-Wave's
% internal [Nx,Ny] arrays are exposed only in explicitly suffixed truth and
% mask fields. The measured axial field is returned both as total velocity
% and as its shear/compressional split.

arguments
    requested_cfg struct = kwsim.two_d.defaultConfig()
end

[cfg, preflight] = kwsim.two_d.validateConfig(requested_cfg);
kwave_root = kwsim.io.locateKWave(cfg.solver.kwave_path);
rng(cfg.seed, 'twister');

[kgrid, cfg] = kwsim.two_d.buildGrid(cfg);
[medium, truth_internal] = kwsim.two_d.buildMedium(cfg);
if lower(string(cfg.source.layout)) == "vibrator_bank"
    [source, source_metadata] = ...
        kwsim.two_d.buildVibratorBankSource(cfg, kgrid);
else
    [source, source_metadata] = kwsim.two_d.buildSingleContactSource(cfg, kgrid);
end
[sensor, sensor_metadata] = kwsim.two_d.buildSensor(cfg);

input_args = {'PMLInside', logical(cfg.solver.pml_inside), ...
    'PMLSize', cfg.solver.pml_size_points, ...
    'PMLAlpha', cfg.solver.pml_alpha, ...
    'PlotPML', false, ...
    'PlotSim', logical(cfg.solver.plot_simulation), ...
    'DisplayMask', 'off', ...
    'DataCast', char(cfg.solver.data_cast)};

timer = tic;
sensor_data = pstdElastic2D(kgrid, medium, source, sensor, input_args{:});
runtime_s = toc(timer);

raw = struct();
raw.ux_split_s = toHost(sensor_data.ux_split_s);
raw.ux_split_p = toHost(sensor_data.ux_split_p);
raw.uy_split_s = toHost(sensor_data.uy_split_s);
raw.uy_split_p = toHost(sensor_data.uy_split_p);
raw.t_record_s = double(kgrid.t_array(sensor.record_start_index:end));

f0 = cfg.source.f0_hz;
fit_lateral_s = kwsim.signal.fitHarmonic(raw.ux_split_s, raw.t_record_s, f0);
fit_lateral_p = kwsim.signal.fitHarmonic(raw.ux_split_p, raw.t_record_s, f0);
fit_axial_s = kwsim.signal.fitHarmonic(raw.uy_split_s, raw.t_record_s, f0);
fit_axial_p = kwsim.signal.fitHarmonic(raw.uy_split_p, raw.t_record_s, f0);

nx_roi = numel(sensor_metadata.x_indices);
nz_roi = numel(sensor_metadata.z_indices);
velocity = struct();
velocity.lateral_shear_zx = toPublicMap(fit_lateral_s.phasor, nx_roi, nz_roi);
velocity.lateral_compression_zx = toPublicMap(fit_lateral_p.phasor, nx_roi, nz_roi);
velocity.lateral_total_zx = velocity.lateral_shear_zx + ...
    velocity.lateral_compression_zx;
velocity.axial_shear_zx = toPublicMap(fit_axial_s.phasor, nx_roi, nz_roi);
velocity.axial_compression_zx = toPublicMap(fit_axial_p.phasor, nx_roi, nz_roi);
velocity.axial_total_zx = velocity.axial_shear_zx + velocity.axial_compression_zx;
velocity.units = "m/s";
velocity.phasor_convention = fit_axial_s.convention;

displacement = struct();
displacement.lateral_shear_zx = velocity.lateral_shear_zx / (1i*2*pi*f0);
displacement.lateral_compression_zx = ...
    velocity.lateral_compression_zx / (1i*2*pi*f0);
displacement.lateral_total_zx = velocity.lateral_total_zx / (1i*2*pi*f0);
displacement.axial_shear_zx = velocity.axial_shear_zx / (1i*2*pi*f0);
displacement.axial_compression_zx = velocity.axial_compression_zx / (1i*2*pi*f0);
displacement.axial_total_zx = velocity.axial_total_zx / (1i*2*pi*f0);
displacement.units = "m";
displacement.phasor_convention = velocity.phasor_convention;

analysis_start_s = raw.t_record_s(1);
source_metadata.diagnostics = kwsim.analysis.sourceMetrics( ...
    source_metadata, analysis_start_s);

truth = struct();
truth.cp_m_s_zx = truth_internal.cp_m_s_xz.';
truth.cs_m_s_zx = truth_internal.cs_m_s_xz.';
truth.rho_kg_m3_zx = truth_internal.rho_kg_m3_xz.';
truth.material_id_zx = truth_internal.material_id_xz.';
truth.attenuation_db_cm_zx = truth_internal.attenuation_db_cm_xz.';
truth.attenuation = truth_internal.attenuation;
attenuation_map_names = ["shear_alpha_at_f0_db_cm", ...
    "compression_alpha_at_f0_db_cm", "shear_kv_db_mhz2_cm", ...
    "compression_kv_db_mhz2_cm", "eta_pa_s", "chi_pa_s"];
for attenuation_name = attenuation_map_names
    internal_name = attenuation_name + "_xz";
    public_name = attenuation_name + "_zx";
    truth.attenuation.(public_name) = ...
        truth_internal.attenuation.(internal_name).';
    truth.attenuation = rmfield(truth.attenuation, internal_name);
end
truth.geometry = rmfield(truth_internal.geometry, 'object_masks_xz');
truth.geometry.object_masks_zx = cellfun(@transpose, ...
    truth_internal.geometry.object_masks_xz, 'UniformOutput', false);
truth.orientation = "[Nz,Nx]";

result = struct();
result.schema_version = cfg.schema_version;
result.config_requested = requested_cfg;
result.config_resolved = cfg;
result.axes = struct('x_m', sensor_metadata.x_m, 'z_m', sensor_metadata.z_m, ...
    't_record_s', raw.t_record_s, 'dx_m', cfg.grid.dx_m, ...
    'dz_m', cfg.grid.dz_m, 'dt_s', kgrid.dt, 'f0_hz', f0, ...
    'orientation', "fields are [Nz,Nx]");
result.truth = truth;
result.source = source_metadata;
result.sensor = sensor_metadata;
result.fields = struct('velocity', velocity, 'displacement', displacement);
result.runtime_s = runtime_s;
result.provenance = kwsim.io.provenance(cfg, kwave_root);

if cfg.output.save_time_series
    result.time_series = struct();
    result.time_series.axial_shear_zxt = toPublicTime(raw.uy_split_s, nx_roi, nz_roi);
    result.time_series.axial_compression_zxt = toPublicTime(raw.uy_split_p, nx_roi, nz_roi);
    result.time_series.units = "m/s";
else
    result.time_series = struct('saved', false, ...
        'reason', "Disabled by output.save_time_series to control file size.");
end

report = kwsim.validation.evaluateRun(result, raw, preflight);
result.valid = report.valid;
result.diagnostics = report;

if strlength(string(cfg.output.directory)) > 0
    kwsim.io.saveRun(result, report, cfg.output.directory, ...
        'Overwrite', logical(cfg.output.overwrite));
end

if ~report.valid && cfg.diagnostics.fail_on_invalid
    failed_names = strjoin([report.checks(~[report.checks.pass]).name], ', ');
    error('kwsim:DiagnosticsFailed', ...
        'Simulation completed but failed diagnostics: %s', ...
        failed_names);
end

end

function host = toHost(value)
if isa(value, 'gpuArray')
    host = gather(value);
else
    host = value;
end
end

function map_zx = toPublicMap(values, nx, nz)
map_xz = reshape(values, nx, nz);
map_zx = map_xz.';
end

function field_zxt = toPublicTime(values, nx, nz)
field_xzt = reshape(values, nx, nz, []);
field_zxt = permute(field_xzt, [2, 1, 3]);
end
