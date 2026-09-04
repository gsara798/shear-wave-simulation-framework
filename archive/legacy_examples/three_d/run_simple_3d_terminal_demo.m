%% Simple 3D shear-wave simulation launched from the terminal

clear;
clc;

script_directory = ...
    fileparts(mfilename("fullpath"));

repository_root = ...
    fileparts(fileparts(script_directory));

addpath(fullfile(repository_root, "src"));

%% 1. Start from the default 3D configuration

cfg = kwsim.three_d.defaultConfig();

%% 2. Define the physical problem

% Homogeneous elastic medium
cfg.medium.cs_m_s = 2.0;
cfg.medium.rho_kg_m3 = 1000;

% Reduced compressional speed for a faster demonstration
cfg.medium.cp_mode = "reduced";
cfg.medium.reduced_cp_factor = 10;

% Harmonic excitation
cfg.source.f0_hz = 500;
cfg.source.velocity_amplitude_m_s = 1e-6;

% Wave propagates nominally along +x.
% Particle motion is imposed along +z, transverse to +x.
cfg.source.target_direction_xyz = [1, 0, 0];
cfg.source.polarization_xyz = [0, 0, 1];

% Finite circular contact
cfg.source.contact_radius_m = 1e-3;
cfg.source.ramp_cycles = 1;
cfg.source.boundary_margin_m = 2e-3;

%% 3. Define the numerical grid

cfg.grid.Nx = 32;
cfg.grid.Ny = 24;
cfg.grid.Nz = 32;

cfg.grid.dx_m = 0.5e-3;
cfg.grid.dy_m = 0.5e-3;
cfg.grid.dz_m = 0.5e-3;

cfg.grid.cfl = 0.20;

%% 4. Define simulation and recording times

cfg.time.settling_cycles = 1;
cfg.time.analysis_cycles = 2;
cfg.time.end_time_s = 8e-3;

cfg.sensor.source_buffer_m = 2e-3;
cfg.sensor.boundary_margin_m = 1.5e-3;

cfg.solver.pml_size_points = [8, 8, 8];
cfg.solver.plot_simulation = false;

%% 5. Harmonic extraction

cfg.analysis.harmonic_method = "least_squares";
cfg.analysis.temporal_window = "none";
cfg.analysis.remove_mean = true;

%% 6. Configure saved outputs

cfg.output.enabled = true;
cfg.output.directory = fullfile(repository_root, "outputs");
cfg.output.run_name = "advisor_simple_3d_demo";

% A timestamp creates a new folder for every execution.
cfg.output.append_timestamp = true;
cfg.output.overwrite = false;

cfg.output.save_result = true;
cfg.output.save_summary = true;
cfg.output.save_config_mat = true;
cfg.output.save_config_json = true;

% Native time series are large, so this demonstration saves only phasors.
cfg.output.save_time_series = false;

cfg.output.save_figures = true;
cfg.output.save_matlab_figures = true;

%% 7. Run the simulation

fprintf("\nRunning simple 3D shear-wave simulation...\n");
fprintf("  Shear-wave speed: %.2f m/s\n", cfg.medium.cs_m_s);
fprintf("  Frequency:        %.1f Hz\n", cfg.source.f0_hz);
fprintf("  Expected lambda:  %.2f mm\n\n", ...
    1e3 * cfg.medium.cs_m_s / cfg.source.f0_hz);

result = kwsim.three_d.run(cfg);

fprintf("\nSolver completed in %.2f s.\n", ...
    result.runtime_s);

%% 8. Quantitative validation

report = ...
    kwsim.validation.evaluateDirectionalHarmonic3D(result);

result.valid = report.valid;
result.diagnostics = report;

fprintf("\nValidation result:\n%s\n", report.summary);

%% 9. Save result, configuration, and validation

paths = kwsim.io.saveSimulationResult(result);

validation_paths = kwsim.io.saveValidationReport( ...
    report, ...
    paths, ...
    Overwrite=result.config_resolved.output.overwrite);

%% 10. Generate and save a central-slice visualization

if result.config_resolved.output.save_figures
    source_handles = ...
        kwsim.viz.plotSourceGeometry3D( ...
            result.config_resolved, ...
            Title="Simple 3D source geometry", ...
            FigureVisible="off", ...
            ShowContactNodes=true);

    source_figure_paths = ...
        kwsim.io.saveFigure( ...
            source_handles.figure, ...
            paths, ...
            "source_geometry_3d", ...
            SaveMatlabFigure= ...
                result.config_resolved.output.save_matlab_figures, ...
            Overwrite= ...
                result.config_resolved.output.overwrite);

    close(source_handles.figure);

    handles = kwsim.viz.plotHarmonicVolumeSlices( ...
        result.fields.harmonic_velocity.z_shear_zyx, ...
        result.axes.x_m, ...
        result.axes.y_m, ...
        result.axes.z_m, ...
        Title="Simple 3D z-polarized shear-wave simulation", ...
        AmplitudeScale="normalized", ...
        FigureVisible="off");

    figure_paths = kwsim.io.saveFigure( ...
        handles.figure, ...
        paths, ...
        "z_shear_central_slices", ...
        SaveMatlabFigure= ...
            result.config_resolved.output.save_matlab_figures, ...
        Overwrite= ...
            result.config_resolved.output.overwrite);

    close(handles.figure);
end

%% 11. Print output locations

fprintf("\n============================================\n");
fprintf("Simulation finished\n");
fprintf("============================================\n");

fprintf("Output directory:\n%s\n\n", paths.run);

fprintf("Resolved configuration:\n%s\n", ...
    fullfile(paths.config, "resolved_config.json"));

fprintf("Simulation result:\n%s\n", ...
    fullfile(paths.data, "result.mat"));

fprintf("Validation summary:\n%s\n", ...
    validation_paths.summary);

if exist("source_figure_paths", "var")
    fprintf("Source-geometry PNG:\n%s\n", ...
        source_figure_paths.png);
end

if exist("figure_paths", "var")
    fprintf("Field PNG:\n%s\n", figure_paths.png);

    if strlength(figure_paths.fig) > 0
        fprintf("MATLAB figure:\n%s\n", figure_paths.fig);
    end
end

if report.valid
    fprintf("\nAll physical validation checks passed.\n");
else
    warning("The simulation was saved, but one or more validation checks failed.");
end
