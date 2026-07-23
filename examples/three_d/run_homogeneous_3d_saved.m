%RUN_HOMOGENEOUS_3D_SAVED Run, save, and visualize a compact 3D simulation.

clear;
clc;

script_directory = fileparts(mfilename("fullpath"));
repository_root = fileparts(fileparts(script_directory));

addpath(fullfile(repository_root, "src"));

%% Configuration

requested_cfg = kwsim.three_d.defaultConfig();

% Compact simulation
requested_cfg.grid.Nx = 32;
requested_cfg.grid.Ny = 24;
requested_cfg.grid.Nz = 32;

requested_cfg.source.ramp_cycles = 1;
requested_cfg.source.boundary_margin_m = 2e-3;

requested_cfg.time.settling_cycles = 1;
requested_cfg.time.analysis_cycles = 2;
requested_cfg.time.end_time_s = 8e-3;

requested_cfg.sensor.source_buffer_m = 2e-3;
requested_cfg.sensor.boundary_margin_m = 1.5e-3;

requested_cfg.solver.pml_size_points = [8, 8, 8];
requested_cfg.solver.plot_simulation = false;

% Harmonic extraction
requested_cfg.analysis.harmonic_method = "least_squares";
requested_cfg.analysis.temporal_window = "none";
requested_cfg.analysis.remove_mean = true;

% Output organization
requested_cfg.output.enabled = true;
requested_cfg.output.directory = ...
    fullfile(repository_root, "outputs");
requested_cfg.output.run_name = "homogeneous_cs2_f500";
requested_cfg.output.append_timestamp = true;
requested_cfg.output.overwrite = false;

requested_cfg.output.save_result = true;
requested_cfg.output.save_summary = true;
requested_cfg.output.save_config_mat = true;
requested_cfg.output.save_config_json = true;
requested_cfg.output.save_time_series = false;
requested_cfg.output.save_figures = true;
requested_cfg.output.save_matlab_figures = true;

%% Run simulation

fprintf("Running 3D homogeneous simulation...\n");

result = kwsim.three_d.run(requested_cfg);

fprintf("Solver finished in %.2f s.\n", ...
    result.metadata.elapsed_time_s);

%% Quantitative harmonic validation

report = ...
    kwsim.validation.evaluateDirectionalHarmonic3D( ...
        result);

result.valid = report.valid;
result.diagnostics = report;

fprintf("Validation: %s\n", ...
    report.summary);

%% Save configurations, data, and validation

paths = kwsim.io.saveSimulationResult(result);

validation_paths = ...
    kwsim.io.saveValidationReport( ...
        report, ...
        paths, ...
        Overwrite= ...
            result.config_resolved.output.overwrite);

fprintf("Saved simulation to:\n%s\n", paths.run);
fprintf("Validation summary:\n%s\n", ...
    validation_paths.summary);

%% Create and save the primary figure

if result.config_resolved.output.save_figures
    source_handles = ...
        kwsim.viz.plotSourceGeometry3D( ...
            result.config_resolved, ...
            Title="3D directional source geometry", ...
            FigureVisible="off", ...
            ShowContactNodes=true);

    source_figure_paths = ...
        kwsim.io.saveFigure( ...
            source_handles.figure, ...
            paths, ...
            "source_geometry_3d", ...
            SaveMatlabFigure= ...
                result.config_resolved.output.save_matlab_figures, ...
            Overwrite=result.config_resolved.output.overwrite);

    close(source_handles.figure);

    fprintf("Saved source-geometry PNG:\n%s\n", ...
        source_figure_paths.png);

    handles = kwsim.viz.plotHarmonicVolumeSlices( ...
        result.fields.harmonic_velocity.z_shear_zyx, ...
        result.axes.x_m, ...
        result.axes.y_m, ...
        result.axes.z_m, ...
        Title="3D z-polarized shear field", ...
        AmplitudeScale="normalized", ...
        FigureVisible="off");

    saved_figure_paths = kwsim.io.saveFigure( ...
        handles.figure, ...
        paths, ...
        "z_shear_slices", ...
        SaveMatlabFigure= ...
            result.config_resolved.output.save_matlab_figures, ...
        Overwrite=result.config_resolved.output.overwrite);

    close(handles.figure);

    fprintf("Saved PNG figure:\n%s\n", ...
        saved_figure_paths.png);

    if strlength(saved_figure_paths.fig) > 0
        fprintf("Saved MATLAB figure:\n%s\n", ...
            saved_figure_paths.fig);
    end
end

if ~report.valid && ...
        result.config_resolved.diagnostics.fail_on_invalid
    failed_names = strjoin( ...
        [report.checks(~[report.checks.pass]).name], ...
        ", ");

    error("kwsim:DirectionalHarmonic3DValidationFailed", ...
        "3D harmonic validation failed: %s", ...
        failed_names);
end

fprintf("Simulation completed successfully.\n");
