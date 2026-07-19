function paths = saveSimulationResult( ...
    result, requested_cfg, options)
%SAVESIMULATIONRESULT Save a reproducible simulation result to disk.
%
% Saves requested and resolved configurations, result data, a lightweight
% summary, JSON configuration, and a human-readable manifest.

arguments
    result struct
    requested_cfg struct
    options.Timestamp = datetime("now")
end

if ~isfield(result, "cfg")
    error("kwsim:InvalidSimulationResult", ...
        "result must contain the resolved configuration in result.cfg.");
end

resolved_cfg = result.cfg;

paths = kwsim.io.createRunDirectory( ...
    resolved_cfg, ...
    Timestamp=options.Timestamp);

%% Configurations

if resolved_cfg.output.save_config_mat
    requested_config_path = ...
        fullfile(paths.config, "requested_config.mat");

    resolved_config_path = ...
        fullfile(paths.config, "resolved_config.mat");

    save(requested_config_path, ...
        "requested_cfg", ...
        "-v7.3");

    save(resolved_config_path, ...
        "resolved_cfg", ...
        "-v7.3");
end

if resolved_cfg.output.save_config_json
    json_path = ...
        fullfile(paths.config, "resolved_config.json");

    json_text = jsonencode( ...
        resolved_cfg, ...
        PrettyPrint=true);

    writeTextFile(json_path, json_text);
end

%% Main result

if resolved_cfg.output.save_result
    result_path = fullfile(paths.data, "result.mat");

    save(result_path, "result", "-v7.3");
end

%% Lightweight summary

summary = buildSummary(result, paths, options.Timestamp);

if resolved_cfg.output.save_summary
    summary_path = fullfile(paths.data, "summary.mat");

    save(summary_path, "summary");
end

%% Manifest

manifest_text = buildManifest(result, summary);
writeTextFile(paths.manifest, manifest_text);

end


function summary = buildSummary(result, paths, timestamp)

cfg = result.cfg;

summary = struct();

summary.created = string(datetime(timestamp, ...
    "Format", "yyyy-MM-dd HH:mm:ss Z"));

summary.run_directory = paths.run;
summary.scenario = string(cfg.scenario);
summary.dimension = result.dimension;

summary.grid_size_xyz = [
    cfg.grid.Nx, ...
    cfg.grid.Ny, ...
    cfg.grid.Nz
];

summary.spacing_m_xyz = [
    cfg.grid.dx_m, ...
    cfg.grid.dy_m, ...
    cfg.grid.dz_m
];

summary.source_frequency_hz = cfg.source.f0_hz;
summary.shear_speed_m_s = cfg.medium.cs_m_s;
summary.compression_speed_m_s = cfg.medium.cp_m_s;
summary.density_kg_m3 = cfg.medium.rho_kg_m3;

summary.harmonic_method = ...
    string(cfg.analysis.harmonic_method);

summary.temporal_window = ...
    string(cfg.analysis.temporal_window);

summary.save_time_series = ...
    cfg.output.save_time_series;

if isfield(result, "metadata") && ...
        isfield(result.metadata, "elapsed_time_s")
    summary.elapsed_solver_time_s = ...
        result.metadata.elapsed_time_s;
else
    summary.elapsed_solver_time_s = NaN;
end

if isfield(result, "metadata") && ...
        isfield(result.metadata, "public_volume_size_zyx")
    summary.public_volume_size_zyx = ...
        result.metadata.public_volume_size_zyx;
end

if isfield(result, "provenance")
    summary.provenance = result.provenance;
end

end


function text = buildManifest(result, summary)

cfg = result.cfg;

lines = [
    "Shear Wave Simulation Framework"
    "================================"
    ""
    "Created: " + summary.created
    "Scenario: " + string(cfg.scenario)
    "Dimension: " + string(result.dimension)
    ""
    "Solver"
    "------"
    "Name: " + string(result.provenance.solver)
    "k-Wave root: " + string(result.provenance.kwave_root)
    "Elapsed solver time: " + ...
        formatNumber(summary.elapsed_solver_time_s) + " s"
    ""
    "Grid"
    "----"
    "Size [Nx Ny Nz]: " + ...
        vectorText(summary.grid_size_xyz)
    "Spacing [dx dy dz]: " + ...
        vectorText(summary.spacing_m_xyz) + " m"
    ""
    "Medium"
    "------"
    "Shear speed: " + ...
        formatNumber(summary.shear_speed_m_s) + " m/s"
    "Compression speed: " + ...
        formatNumber(summary.compression_speed_m_s) + " m/s"
    "Density: " + ...
        formatNumber(summary.density_kg_m3) + " kg/m^3"
    ""
    "Excitation and analysis"
    "-----------------------"
    "Frequency: " + ...
        formatNumber(summary.source_frequency_hz) + " Hz"
    "Harmonic method: " + summary.harmonic_method
    "Temporal window: " + summary.temporal_window
    "Saved native time series: " + ...
        string(summary.save_time_series)
    ""
    "Output"
    "------"
    "Directory: " + summary.run_directory
];

text = strjoin(lines, newline);

end


function text = vectorText(values)

text = "[" + ...
    strjoin(string(values), " ") + ...
    "]";

end


function text = formatNumber(value)

if isfinite(value)
    text = string(sprintf("%.9g", value));
else
    text = "not available";
end

end


function writeTextFile(path, text)

file_id = fopen(path, "w");

if file_id < 0
    error("kwsim:OutputWriteFailed", ...
        "Could not open file for writing: %s", path);
end

cleanup = onCleanup(@() fclose(file_id));

fprintf(file_id, "%s", text);

end
