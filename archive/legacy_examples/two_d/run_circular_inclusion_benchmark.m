%RUN_CIRCULAR_INCLUSION_BENCHMARK
% Execute, evaluate, visualize, and save the circular-inclusion benchmark.

clear;
clc;

example_directory = fileparts(mfilename("fullpath"));
project_root = fileparts(fileparts(example_directory));

addpath(fullfile(project_root, "src"));
addpath(fullfile(project_root, "benchmarks"));

%% Configuration

cfg = ...
    kwsim_benchmarks.circular_inclusion_2d.config();

cfg.output.enabled = true;
cfg.output.directory = fullfile( ...
    project_root, ...
    "outputs");

cfg.output.run_name = ...
    "circular_inclusion_2d";

cfg.output.append_timestamp = true;
cfg.output.overwrite = false;

cfg.output.save_result = true;
cfg.output.save_summary = true;
cfg.output.save_config_mat = true;
cfg.output.save_config_json = true;
cfg.output.save_time_series = false;
cfg.output.save_figures = true;

% The current 2D visualization functions export PNG files only.
cfg.output.save_matlab_figures = false;

%% Run benchmark suite

fprintf("Running circular-inclusion 2D benchmark...\n");

validation = ...
    kwsim_benchmarks.circular_inclusion_2d.run(cfg);

fprintf("%s\n", validation.summary);

contrast = validation.results.contrast;
contrast_report = validation.reports.contrast;

%% Save the primary simulation

paths = kwsim.io.saveSimulationResult(contrast);

%% Save complete cross-run validation

benchmark_paths = ...
    kwsim_benchmarks.circular_inclusion_2d.saveResults( ...
        validation, ...
        paths, ...
        Overwrite=contrast.config_resolved.output.overwrite);

%% Save figures

figure_paths = struct();
comparison_file = "";

if contrast.config_resolved.output.save_figures
    % Generic diagnostics for the primary contrast simulation.
    figure_paths = kwsim.viz.plotRun( ...
        contrast, ...
        contrast_report, ...
        paths.figures);

    % Benchmark-specific contrast-versus-reference visualization.
    comparison_file = fullfile( ...
        paths.figures, ...
        "inclusion_comparison.png");

    [~, comparison_file] = ...
        kwsim_benchmarks.circular_inclusion_2d.plotResults( ...
            contrast, ...
            validation.results.homogeneous, ...
            comparison_file, ...
            Visible=false, ...
            CloseAfterExport=true);
end

%% Console summary

fprintf("\nSaved benchmark to:\n%s\n", ...
    paths.run);

fprintf("Cross-run validation:\n%s\n", ...
    benchmark_paths.mat_file);

fprintf("Validation summary:\n%s\n", ...
    benchmark_paths.summary_file);

if strlength(string(comparison_file)) > 0
    fprintf("Comparison figure:\n%s\n", ...
        comparison_file);
end

if isfield(figure_paths, "field")
    fprintf("Primary field diagnostics:\n%s\n", ...
        figure_paths.field);
end

%% Acceptance status

if ~validation.valid
    error( ...
        "kwsim:CircularInclusionBenchmarkFailed", ...
        "One or more circular-inclusion acceptance checks failed.");
end

fprintf( ...
    "Circular-inclusion 2D benchmark completed successfully.\n");
