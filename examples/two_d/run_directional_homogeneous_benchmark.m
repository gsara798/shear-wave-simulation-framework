%RUN_DIRECTIONAL_HOMOGENEOUS_BENCHMARK
% Execute, validate, visualize, and save the full homogeneous 2D reference.

clear;
clc;

example_directory = fileparts(mfilename("fullpath"));
project_root = fileparts(fileparts(example_directory));

addpath(fullfile(project_root, "src"));
addpath(fullfile(project_root, "benchmarks"));

%% Configuration

cfg = ...
    kwsim_benchmarks.directional_homogeneous_2d.config();

cfg.output.enabled = true;
cfg.output.directory = fullfile( ...
    project_root, ...
    "outputs");

cfg.output.run_name = ...
    "directional_homogeneous_2d";

cfg.output.append_timestamp = true;
cfg.output.overwrite = false;

cfg.output.save_result = true;
cfg.output.save_summary = true;
cfg.output.save_config_mat = true;
cfg.output.save_config_json = true;
cfg.output.save_time_series = false;
cfg.output.save_figures = true;
cfg.output.save_matlab_figures = true;

%% Run and validate

fprintf("Running directional homogeneous 2D benchmark...\n");

[result, report] = ...
    kwsim_benchmarks.directional_homogeneous_2d.run(cfg);

fprintf("%s\n", report.summary);

%% Save reproducible result

paths = kwsim.io.saveSimulationResult(result);

validation_paths = kwsim.io.saveValidationReport( ...
    report, ...
    paths, ...
    Overwrite=result.config_resolved.output.overwrite);

%% Save diagnostic figures

if result.config_resolved.output.save_figures
    figure_paths = kwsim.viz.plotRun( ...
        result, ...
        report, ...
        paths.figures);
else
    figure_paths = struct();
end

fprintf("\nSaved benchmark to:\n%s\n", paths.run);
fprintf("Validation summary:\n%s\n", ...
    validation_paths.summary);

if isfield(figure_paths, "field")
    fprintf("Field figure:\n%s\n", ...
        figure_paths.field);
end

if ~report.valid
    error( ...
        "kwsim:DirectionalHomogeneousBenchmarkFailed", ...
        "The directional homogeneous benchmark failed validation.");
end

fprintf("Directional homogeneous 2D benchmark completed successfully.\n");
