function raw = runRaw(requested_cfg)
%RUNRAW Execute pstdElastic3D and return its native sensor output.
%
% This is the low-level k-Wave adapter. It intentionally preserves the
% solver-native sensor layout:
%
%     [sensor_point, recorded_time]
%
% No public [Nz,Ny,Nx] volume reconstruction or harmonic fitting is
% performed here. Those transformations belong to kwsim.three_d.run.
%
% Output:
%   raw.cfg             resolved configuration
%   raw.preflight       validation and memory information
%   raw.sensor_data     native pstdElastic3D output
%   raw.truth_internal  truth maps in internal [Nx,Ny,Nz] orientation
%   raw.metadata        grid, source, sensor, solver, and timing metadata

arguments
    requested_cfg struct
end

%% Validate and locate k-Wave

[cfg, preflight] = ...
    kwsim.three_d.validateConfig(requested_cfg);

kwave_root = ...
    kwsim.io.locateKWave(cfg.solver.kwave_path);

solver_path = which('pstdElastic3D');

if isempty(solver_path)
    error("kwsim:MissingPstdElastic3D", ...
        "pstdElastic3D was not found after locating k-Wave.");
end

%% Build solver inputs

[kgrid, cfg, grid_metadata] = ...
    kwsim.three_d.buildGrid(cfg);

[medium, truth_internal] = ...
    kwsim.three_d.buildMedium(cfg);

[source, source_metadata] = ...
    kwsim.three_d.buildSingleContactSource(cfg, kgrid);

[sensor, sensor_metadata] = ...
    kwsim.three_d.buildSensor(cfg);

%% Execute solver

solver_arguments = {
    'PMLSize', cfg.solver.pml_size_points
    'PMLAlpha', cfg.solver.pml_alpha
    'PMLInside', cfg.solver.pml_inside
    'DataCast', char(cfg.solver.data_cast)
    'PlotSim', cfg.solver.plot_simulation
};

solver_arguments = reshape(solver_arguments.', 1, []);

solver_start = tic;

sensor_data = pstdElastic3D( ...
    kgrid, ...
    medium, ...
    source, ...
    sensor, ...
    solver_arguments{:});

elapsed_time_s = toc(solver_start);

%% Validate native solver output

expected_fields = [
    "ux_split_p"
    "ux_split_s"
    "uy_split_p"
    "uy_split_s"
    "uz_split_p"
    "uz_split_s"
];

if ~isstruct(sensor_data)
    error("kwsim:Unexpected3DSolverOutput", ...
        "pstdElastic3D did not return a structure.");
end

for field_name = expected_fields.'
    if ~isfield(sensor_data, field_name)
        error("kwsim:Unexpected3DSolverOutput", ...
            "pstdElastic3D output is missing field '%s'.", ...
            field_name);
    end

    values = sensor_data.(field_name);

    expected_size = [
        cfg.derived.sensor_points, ...
        cfg.time.recorded_samples
    ];

    if ~isequal(size(values), expected_size)
        error("kwsim:Unexpected3DSolverOutput", ...
            "Field '%s' has size [%s]; expected [%s].", ...
            field_name, ...
            num2str(size(values)), ...
            num2str(expected_size));
    end

    if any(~isfinite(values), "all")
        error("kwsim:NonFinite3DField", ...
            "Field '%s' contains NaN or Inf values.", ...
            field_name);
    end
end

%% Package native result

raw = struct();

raw.cfg = cfg;
raw.preflight = preflight;
raw.sensor_data = sensor_data;
raw.truth_internal = truth_internal;

raw.metadata = struct();

raw.metadata.kwave_root = string(kwave_root);
raw.metadata.solver_path = string(solver_path);
raw.metadata.solver_name = "pstdElastic3D";
raw.metadata.elapsed_time_s = elapsed_time_s;

raw.metadata.grid = grid_metadata;
raw.metadata.source = source_metadata;
raw.metadata.sensor = sensor_metadata;

raw.metadata.output = struct();
raw.metadata.output.expected_fields = expected_fields;
raw.metadata.output.sensor_point_count = ...
    cfg.derived.sensor_points;
raw.metadata.output.recorded_samples = ...
    cfg.time.recorded_samples;
raw.metadata.output.native_layout = ...
    "[sensor_point,time]";
raw.metadata.output.sensor_mask_orientation = ...
    "[Nx,Ny,Nz]";

end
