function paths = saveSimulationResult( ...
    result, requested_cfg, options)
%SAVESIMULATIONRESULT Save a reproducible 2D or 3D simulation result.
%
% The preferred result contract is:
%
%   result.config_requested
%   result.config_resolved
%
% During the 3D transition, result.cfg is accepted as a compatibility alias.
%
% requested_cfg is optional. When omitted, result.config_requested is used.

arguments
    result struct
    requested_cfg struct = struct()
    options.Timestamp = datetime("now")
end

resolved_cfg = resolveResolvedConfig(result);

if isempty(fieldnames(requested_cfg))
    if isfield(result, "config_requested")
        requested_cfg = result.config_requested;
    else
        requested_cfg = resolved_cfg;
    end
end

paths = kwsim.io.createRunDirectory( ...
    resolved_cfg, ...
    Timestamp=options.Timestamp);

%% Configurations

if outputFlag(resolved_cfg, "save_config_mat", true)
    requested_config_path = fullfile( ...
        paths.config, ...
        "requested_config.mat");

    resolved_config_path = fullfile( ...
        paths.config, ...
        "resolved_config.mat");

    save(requested_config_path, ...
        "requested_cfg", ...
        "-v7.3");

    save(resolved_config_path, ...
        "resolved_cfg", ...
        "-v7.3");
end

if outputFlag(resolved_cfg, "save_config_json", true)
    json_path = fullfile( ...
        paths.config, ...
        "resolved_config.json");

    json_text = jsonencode( ...
        resolved_cfg, ...
        PrettyPrint=true);

    writeTextFile(json_path, json_text);
end

%% Main result

if outputFlag(resolved_cfg, "save_result", true)
    result_path = fullfile( ...
        paths.data, ...
        "result.mat");

    save(result_path, ...
        "result", ...
        "-v7.3");
end

%% Lightweight summary

summary = buildSummary( ...
    result, ...
    resolved_cfg, ...
    paths, ...
    options.Timestamp);

if outputFlag(resolved_cfg, "save_summary", true)
    summary_path = fullfile( ...
        paths.data, ...
        "summary.mat");

    save(summary_path, "summary");
end

%% Human-readable manifest

manifest_text = buildManifest( ...
    result, ...
    resolved_cfg, ...
    summary);

writeTextFile( ...
    paths.manifest, ...
    manifest_text);

end


function cfg = resolveResolvedConfig(result)

if isfield(result, "config_resolved")
    cfg = result.config_resolved;
elseif isfield(result, "cfg")
    cfg = result.cfg;
else
    error("kwsim:InvalidSimulationResult", ...
        ["result must contain the resolved configuration in " ...
         "result.config_resolved or result.cfg."]);
end

end


function summary = buildSummary( ...
    result, cfg, paths, timestamp)

dimension = resolveDimension(result, cfg);

[grid_size, spacing_m, ...
    grid_size_label, spacing_label] = ...
    gridSummary(cfg, dimension);

summary = struct();

summary.created = string(datetime( ...
    timestamp, ...
    "Format", "yyyy-MM-dd HH:mm:ss Z"));

summary.run_directory = paths.run;
summary.scenario = textField(cfg, "scenario", "simulation");
summary.dimension = dimension;

summary.grid_size = grid_size;
summary.spacing_m = spacing_m;
summary.grid_size_label = grid_size_label;
summary.spacing_label = spacing_label;

summary.source_frequency_hz = nestedNumericField( ...
    cfg, "source", "f0_hz", NaN);

summary.shear_speed_m_s = nestedNumericField( ...
    cfg, "medium", "cs_m_s", NaN);

summary.compression_speed_m_s = nestedNumericField( ...
    cfg, "medium", "cp_m_s", NaN);

summary.density_kg_m3 = nestedNumericField( ...
    cfg, "medium", "rho_kg_m3", NaN);

summary.harmonic_method = "least_squares";
summary.temporal_window = "none";

if isfield(cfg, "analysis")
    if isfield(cfg.analysis, "harmonic_method")
        summary.harmonic_method = string( ...
            cfg.analysis.harmonic_method);
    end

    if isfield(cfg.analysis, "temporal_window")
        summary.temporal_window = string( ...
            cfg.analysis.temporal_window);
    end
end

summary.save_time_series = logical( ...
    nestedField(cfg, ...
        "output", ...
        "save_time_series", ...
        false));

summary.elapsed_solver_time_s = resolveRuntime(result);

if isfield(result, "metadata") && ...
        isfield(result.metadata, "public_volume_size_zyx")
    summary.public_volume_size = ...
        result.metadata.public_volume_size_zyx;
elseif isfield(result, "fields") && dimension == 2
    summary.public_volume_size = infer2DFieldSize(result);
else
    summary.public_volume_size = [];
end

if isfield(result, "provenance")
    summary.provenance = result.provenance;
end

end


function text = buildManifest(result, cfg, summary)

provenance = struct();

if isfield(result, "provenance")
    provenance = result.provenance;
end

solver_name = textField( ...
    provenance, ...
    "solver", ...
    "not available");

kwave_root = textField( ...
    provenance, ...
    "kwave_root", ...
    "not available");

lines = [
    "Shear Wave Simulation Framework"
    "================================"
    ""
    "Created: " + summary.created
    "Scenario: " + summary.scenario
    "Dimension: " + string(summary.dimension)
    ""
    "Solver"
    "------"
    "Name: " + solver_name
    "k-Wave root: " + kwave_root
    "Elapsed solver time: " + ...
        formatNumber(summary.elapsed_solver_time_s) + " s"
    ""
    "Grid"
    "----"
    summary.grid_size_label + ": " + ...
        vectorText(summary.grid_size)
    summary.spacing_label + ": " + ...
        vectorText(summary.spacing_m) + " m"
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


function dimension = resolveDimension(result, cfg)

if isfield(result, "dimension")
    dimension = double(result.dimension);
elseif isfield(cfg, "dimension")
    dimension = double(cfg.dimension);
elseif isfield(cfg, "grid") && ...
        isfield(cfg.grid, "Ny")
    dimension = 3;
else
    dimension = 2;
end

if ~ismember(dimension, [2, 3])
    error("kwsim:InvalidSimulationDimension", ...
        "Simulation dimension must be 2 or 3.");
end

end


function [grid_size, spacing_m, ...
    grid_size_label, spacing_label] = ...
    gridSummary(cfg, dimension)

if ~isfield(cfg, "grid")
    error("kwsim:InvalidSimulationResult", ...
        "Resolved configuration is missing cfg.grid.");
end

if dimension == 3
    grid_size = [
        cfg.grid.Nx, ...
        cfg.grid.Ny, ...
        cfg.grid.Nz
    ];

    spacing_m = [
        cfg.grid.dx_m, ...
        cfg.grid.dy_m, ...
        cfg.grid.dz_m
    ];

    grid_size_label = "Size [Nx Ny Nz]";
    spacing_label = "Spacing [dx dy dz]";
else
    grid_size = [
        cfg.grid.Nx, ...
        cfg.grid.Nz
    ];

    spacing_m = [
        cfg.grid.dx_m, ...
        cfg.grid.dz_m
    ];

    grid_size_label = "Size [Nx Nz]";
    spacing_label = "Spacing [dx dz]";
end

end


function runtime_s = resolveRuntime(result)

if isfield(result, "runtime_s")
    runtime_s = double(result.runtime_s);
elseif isfield(result, "metadata") && ...
        isfield(result.metadata, "elapsed_time_s")
    runtime_s = double( ...
        result.metadata.elapsed_time_s);
else
    runtime_s = NaN;
end

end


function field_size = infer2DFieldSize(result)

field_size = [];

if ~isfield(result.fields, "velocity")
    return
end

candidate_names = [
    "axial_shear_zx"
    "lateral_shear_zx"
    "axial_total_zx"
];

for candidate = candidate_names.'
    if isfield(result.fields.velocity, candidate)
        field_size = size( ...
            result.fields.velocity.(candidate));
        return
    end
end

end


function value = outputFlag(cfg, field_name, default_value)

value = logical(nestedField( ...
    cfg, ...
    "output", ...
    field_name, ...
    default_value));

end


function value = nestedField( ...
    structure, parent_name, field_name, default_value)

if isfield(structure, parent_name) && ...
        isfield(structure.(parent_name), field_name)
    value = structure.(parent_name).(field_name);
else
    value = default_value;
end

end


function value = nestedNumericField( ...
    structure, parent_name, field_name, default_value)

value = nestedField( ...
    structure, ...
    parent_name, ...
    field_name, ...
    default_value);

value = double(value);

end


function value = textField( ...
    structure, field_name, default_value)

if isfield(structure, field_name)
    value = string(structure.(field_name));
else
    value = string(default_value);
end

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
