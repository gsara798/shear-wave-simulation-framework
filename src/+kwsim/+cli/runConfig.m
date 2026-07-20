function outcome = runConfig(config_file, options)
%RUNCONFIG Validate or execute one 2D/3D configuration from a JSON file.
%
% Dry run:
%
%   outcome = kwsim.cli.runConfig(file, DryRun=true)
%
% Real execution:
%
%   outcome = kwsim.cli.runConfig(file)
%
% The dispatcher selects kwsim.two_d or kwsim.three_d from cfg.dimension.

arguments
    config_file {mustBeTextScalar}
    options.DryRun (1,1) logical = false
end

[requested_cfg, config_metadata] = ...
    kwsim.io.loadConfigJson(config_file);

requested_cfg = resolveProjectPaths(requested_cfg);

[resolved_cfg, preflight] = ...
    validateDimensionConfig(requested_cfg);

printConfigurationSummary( ...
    resolved_cfg, ...
    config_metadata.config_file, ...
    options.DryRun);

outcome = struct();
outcome.config_file = config_metadata.config_file;
outcome.dimension = resolved_cfg.dimension;
outcome.scenario = string(resolved_cfg.scenario);
outcome.config_requested = requested_cfg;
outcome.config_resolved = resolved_cfg;
outcome.preflight = preflight;
outcome.result = struct();
outcome.report = struct();
outcome.paths = struct();
outcome.validation_paths = struct();
outcome.figure_paths = struct();
outcome.req_validation_sample = struct();
outcome.req_validation_sample_path = "";

if options.DryRun
    outcome.status = "dry_run_valid";

    fprintf("\nDry run completed successfully.\n");
    fprintf("No solver was executed and no outputs were created.\n");
    return
end

%% Execute without throwing before outputs can be saved

fail_on_invalid = logical( ...
    requested_cfg.diagnostics.fail_on_invalid);

execution_cfg = requested_cfg;
execution_cfg.diagnostics.fail_on_invalid = false;

[result, report] = executeDimensionConfig( ...
    execution_cfg);

% Restore the user's requested post-validation failure policy.
result.config_requested = requested_cfg;
result.config_resolved.diagnostics.fail_on_invalid = ...
    fail_on_invalid;

if isfield(result, "cfg")
    result.cfg = result.config_resolved;
end

result.valid = report.valid;
result.diagnostics = report;

%% Save standardized outputs

paths = struct();
validation_paths = struct();
figure_paths = struct();

if outputFlag( ...
        result.config_resolved, ...
        "enabled", ...
        false)

    paths = kwsim.io.saveSimulationResult(result);

    validation_paths = ...
        kwsim.io.saveValidationReport( ...
            report, ...
            paths, ...
            Overwrite=outputFlag( ...
                result.config_resolved, ...
                "overwrite", ...
                false));

    if outputFlag( ...
            result.config_resolved, ...
            "save_req_validation_sample", ...
            false)

        req_validation_sample = ...
            kwsim.req.createValidationSample( ...
                result, ...
                Quantity=string( ...
                    result.config_resolved. ...
                    req_validation.quantity));

        req_readiness = ...
            kwsim.req.assessValidationSample( ...
                req_validation_sample, ...
                CsGuessMPerS= ...
                    result.config_resolved. ...
                    req_validation.cs_guess_m_s, ...
                WindowWavelengths= ...
                    result.config_resolved. ...
                    req_validation.window_wavelengths, ...
                MinimumPlacementsPerAxis= ...
                    result.config_resolved. ...
                    req_validation. ...
                    minimum_placements_per_axis);

        req_validation_sample.req_readiness = ...
            req_readiness;

        fprintf("REQ readiness: %s\n", ...
            req_readiness.summary);

        req_validation_sample_path = ...
            kwsim.req.saveValidationSample( ...
                req_validation_sample, ...
                paths, ...
                Overwrite=outputFlag( ...
                    result.config_resolved, ...
                    "overwrite", ...
                    false));

        fprintf("REQ validation sample:\n%s\n", ...
            req_validation_sample_path);
    else
        req_validation_sample = struct();
        req_validation_sample_path = "";
    end

    if outputFlag( ...
            result.config_resolved, ...
            "save_figures", ...
            false)

        figure_paths = saveConfiguredFigures( ...
            result, ...
            report, ...
            paths);
    end

    fprintf("\nSaved run to:\n%s\n", ...
        paths.run);

    if isfield(validation_paths, "summary")
        fprintf("Validation summary:\n%s\n", ...
            validation_paths.summary);
    end
else
    fprintf("\nOutput saving is disabled by output.enabled.\n");
end

outcome.status = resolveStatus(report.valid);
outcome.result = result;
outcome.report = report;
outcome.paths = paths;
outcome.validation_paths = validation_paths;
outcome.figure_paths = figure_paths;
outcome.req_validation_sample = req_validation_sample;
outcome.req_validation_sample_path = ...
    req_validation_sample_path;

fprintf("\nValidation:\n%s\n", ...
    report.summary);

if ~report.valid && fail_on_invalid
    failed_names = strjoin( ...
        [report.checks(~[report.checks.pass]).name], ...
        ", ");

    error("kwsim:ConfiguredRunValidationFailed", ...
        "Simulation was saved but failed validation: %s", ...
        failed_names);
end

fprintf("\nConfigured simulation completed successfully.\n");

end


function [resolved_cfg, preflight] = ...
    validateDimensionConfig(cfg)

switch double(cfg.dimension)
    case 2
        [resolved_cfg, preflight] = ...
            kwsim.two_d.validateConfig(cfg);

    case 3
        [resolved_cfg, preflight] = ...
            kwsim.three_d.validateConfig(cfg);

    otherwise
        error("kwsim:UnsupportedDimension", ...
            "Only dimensions 2 and 3 are supported.");
end

end


function [result, report] = ...
    executeDimensionConfig(cfg)

switch double(cfg.dimension)
    case 2
        [result, report] = ...
            kwsim.two_d.run(cfg);

    case 3
        result = ...
            kwsim.three_d.run(cfg);

        report = evaluate3DResult(result);

    otherwise
        error("kwsim:UnsupportedDimension", ...
            "Only dimensions 2 and 3 are supported.");
end

end


function report = evaluate3DResult(result)

scenario = lower(string( ...
    result.config_resolved.scenario));

switch scenario
    case "homogeneous_directional_3d"
        report = ...
            kwsim.validation. ...
            evaluateDirectionalHarmonic3D(result);

    case "homogeneous_partial_diffuse8_3d"
        report = ...
            kwsim.validation. ...
            evaluateMultiSourceHarmonic3D(result);

    otherwise
        error( ...
            "kwsim:Unsupported3DValidation", ...
            "No physical 3D validation routine is registered " + ...
            "for scenario '%s'.", ...
            scenario);
end

end


function figure_paths = ...
    saveConfiguredFigures(result, report, paths)

switch double(result.dimension)
    case 2
        figure_paths = kwsim.viz.plotRun( ...
            result, ...
            report, ...
            paths.figures);

    case 3
        figure_title = ...
            "3D shear-wave field";

        if isfield(report, "scope")
            switch string(report.scope)
                case "homogeneous_directional_harmonic_3d"
                    figure_title = ...
                        "3D directional shear-wave field";

                case "homogeneous_multi_source_harmonic_3d"
                    figure_title = ...
                        "3D partial-diffuse shear-wave field";
            end
        end

        handles = ...
            kwsim.viz.plotHarmonicVolumeSlices( ...
                result.fields.harmonic_velocity. ...
                    z_shear_zyx, ...
                result.axes.x_m, ...
                result.axes.y_m, ...
                result.axes.z_m, ...
                Title=figure_title, ...
                AmplitudeScale="normalized", ...
                FigureVisible="off");

        cleanup = onCleanup( ...
            @() closeFigureIfOpen(handles.figure));

        figure_paths = kwsim.io.saveFigure( ...
            handles.figure, ...
            paths, ...
            "z_shear_slices", ...
            SaveMatlabFigure=outputFlag( ...
                result.config_resolved, ...
                "save_matlab_figures", ...
                false), ...
            Overwrite=outputFlag( ...
                result.config_resolved, ...
                "overwrite", ...
                false));

        clear cleanup

    otherwise
        error("kwsim:UnsupportedDimension", ...
            "Cannot save figures for dimension %g.", ...
            result.dimension);
end

end


function cfg = resolveProjectPaths(cfg)

repository_root = resolveRepositoryRoot();

if isfield(cfg, "output") && ...
        isfield(cfg.output, "directory")

    cfg.output.directory = resolveRelativePath( ...
        cfg.output.directory, ...
        repository_root);
end

if isfield(cfg, "solver") && ...
        isfield(cfg.solver, "kwave_path") && ...
        strlength(string(cfg.solver.kwave_path)) > 0

    cfg.solver.kwave_path = resolveRelativePath( ...
        cfg.solver.kwave_path, ...
        repository_root);
end

end


function repository_root = resolveRepositoryRoot()

% Current file:
%   repository/src/+kwsim/+cli/runConfig.m

repository_root = fileparts( ...
    fileparts( ...
    fileparts( ...
    fileparts(mfilename("fullpath")))));

repository_root = string(repository_root);

end


function path_value = ...
    resolveRelativePath(path_value, repository_root)

path_value = string(path_value);

if strlength(path_value) == 0
    return
end

if ~isAbsolutePath(path_value)
    path_value = fullfile( ...
        repository_root, ...
        path_value);
end

end


function tf = isAbsolutePath(path_value)

characters = char(string(path_value));

if ispc
    tf = ~isempty(regexp( ...
        characters, ...
        '^[A-Za-z]:[\\/]|^\\\\', ...
        'once'));
else
    tf = startsWith(characters, filesep);
end

end


function printConfigurationSummary( ...
    cfg, config_file, dry_run)

fprintf("\n============================================\n");
fprintf("KWSIM configured run\n");
fprintf("============================================\n");

fprintf("Configuration: %s\n", config_file);
fprintf("Dimension:     %dD\n", cfg.dimension);
fprintf("Scenario:      %s\n", string(cfg.scenario));
fprintf("Shear speed:   %.6g m/s\n", cfg.medium.cs_m_s);
fprintf("Frequency:     %.6g Hz\n", cfg.source.f0_hz);

if cfg.dimension == 2
    fprintf("Grid:          %d x %d\n", ...
        cfg.grid.Nx, ...
        cfg.grid.Nz);
else
    fprintf("Grid:          %d x %d x %d\n", ...
        cfg.grid.Nx, ...
        cfg.grid.Ny, ...
        cfg.grid.Nz);
end

fprintf("Mode:          %s\n", ...
    chooseText(dry_run, "dry run", "solver execution"));

end


function value = outputFlag(cfg, field_name, default_value)

value = default_value;

if isfield(cfg, "output") && ...
        isfield(cfg.output, field_name)

    value = logical(cfg.output.(field_name));
end

end


function status = resolveStatus(valid)

if valid
    status = "completed_valid";
else
    status = "completed_invalid";
end

end


function text = chooseText(condition, true_text, false_text)

if condition
    text = true_text;
else
    text = false_text;
end

end


function closeFigureIfOpen(figure_handle)

if isgraphics(figure_handle)
    close(figure_handle);
end

end
