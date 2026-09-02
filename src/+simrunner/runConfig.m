function outcome = runConfig(configFile, options)
%RUNCONFIG Run any public simulation JSON with a common output contract.
%
% The backend is detected automatically from the JSON structure:
%   kwsim   -> cfg.dimension is present
%   swsynth -> cfg.domain is present
%
% By default outputs are written next to the JSON file:
%
%   <config-folder>/outputs/<scenario>_<timestamp>/
%       config/
%       data/
%       figures/
%       validation/
%       report/        (when GeneratePdf=true)
%
% Examples:
%   simrunner.runConfig("examples/kwave/2d/inclusion/config.json")
%   simrunner.runConfig("examples/swsynth/volumetric3d/inclusion/config.json")
%
arguments
    configFile {mustBeTextScalar}
    options.Backend {mustBeTextScalar} = "auto"
    options.OutputRoot {mustBeTextScalar} = ""
    options.DryRun (1,1) logical = false
    options.PlotFigures (1,1) logical = true
    options.FigureVisible = "off"
    options.GeneratePdf (1,1) logical = false
end

configFile = string(configFile);
if ~isfile(configFile)
    error("simrunner:ConfigFileNotFound", ...
        "Configuration file not found: %s",configFile);
end

configFile = absolutePath(configFile);
config = jsondecode(fileread(configFile));
backend = resolveBackend(config,options.Backend);

outputRoot = string(options.OutputRoot);
if strlength(outputRoot) == 0
    outputRoot = fullfile(fileparts(configFile),"outputs");
elseif ~isAbsolutePath(outputRoot)
    outputRoot = absolutePath(outputRoot);
end

visibility = simviz.normalizeVisible(options.FigureVisible);

if options.DryRun
    outcome = validateOnly(configFile,config,backend,outputRoot);
    return
end

config = normalizeConfigForExecution(config,backend);

outcome = simcampaigns.runSingle( ...
    config,backend, ...
    OutputRoot=outputRoot, ...
    PlotFigures=options.PlotFigures, ...
    FigureVisible=visibility, ...
    GeneratePdf=options.GeneratePdf);

outcome.config_file = configFile;
outcome.backend = backend;
outcome.output_root = outputRoot;

fprintf("\nUnified simulation run completed.\n");
fprintf("Backend: %s\n",backend);
fprintf("Run:     %s\n",outcome.run_directory);
end

function outcome = validateOnly(configFile,config,backend,outputRoot)

switch backend
    case "kwsim"
        outcome = kwsim.cli.runConfig( ...
            configFile, ...
            DryRun=true, ...
            OutputDirectory=outputRoot);

    case "swsynth"
        config = normalizeSwsynthObjects(config);
        if isVolumetricSwsynth(config)
            [resolved,validation] = swsynth.validateConfig3D(config);
        else
            [resolved,validation] = swsynth.validateConfig(config);
        end
        outcome = struct();
        outcome.status = "dry_run_valid";
        outcome.backend = "swsynth";
        outcome.config_file = configFile;
        outcome.config_resolved = resolved;
        outcome.validation = validation;
        outcome.output_root = outputRoot;
        fprintf("\nSWSYNTH configuration validated successfully.\n");
        fprintf("Scenario: %s\n",string(resolved.scenario));
        fprintf("Dry run: no outputs were created.\n");

    otherwise
        error("simrunner:UnsupportedBackend","Unsupported backend: %s",backend);
end
end

function config = normalizeConfigForExecution(config,backend)

switch backend
    case "kwsim"
        if ~isfield(config,"output") || ~isstruct(config.output)
            config.output = struct();
        end
        config.output.enabled = true;
        config.output.save_wavefield_sample = true;

    case "swsynth"
        config = normalizeSwsynthObjects(config);
end
end

function config = normalizeSwsynthObjects(config)
if isfield(config,"medium") && isfield(config.medium,"objects") && ...
        isstruct(config.medium.objects) && ~isempty(config.medium.objects)
    config.medium.objects = num2cell(config.medium.objects);
end
end

function backend = resolveBackend(config,requested)
requested = lower(string(requested));
if requested ~= "auto"
    if ~ismember(requested,["kwsim","swsynth"])
        error("simrunner:InvalidBackend", ...
            "Backend must be auto, kwsim, or swsynth.");
    end
    backend = requested;
    return
end

if isfield(config,"dimension")
    backend = "kwsim";
elseif isfield(config,"domain") && isfield(config,"wavefield")
    backend = "swsynth";
else
    error("simrunner:BackendDetectionFailed", ...
        "Could not infer the simulation backend from the JSON configuration.");
end
end

function tf = isVolumetricSwsynth(config)
tf = isfield(config,"domain") && ...
    isfield(config.domain,"Ly_m") && ...
    isfield(config.domain,"dy_m");
end

function value = absolutePath(value)
value = string(value);
if isAbsolutePath(value)
    return
end
value = string(fullfile(pwd,value));
end

function tf = isAbsolutePath(value)
characters = char(string(value));
if ispc
    tf = ~isempty(regexp(characters,'^[A-Za-z]:[\\/]|^\\\\','once'));
else
    tf = startsWith(characters,filesep);
end
end
