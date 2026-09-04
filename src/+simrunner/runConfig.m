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
outcome = ensureStandardArtifacts(outcome,config,backend);

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

function outcome = ensureStandardArtifacts(outcome,config,backend)
runDirectory = string(outcome.run_directory);
for folder = ["config","data","figures","validation"]
    pathValue = fullfile(runDirectory,folder);
    if ~isfolder(pathValue), mkdir(pathValue); end
end

summaryPath = fullfile(runDirectory,"data","run_summary.json");
if ~isfile(summaryPath)
    summary = buildStandardSummary(outcome,config,backend);
    writeJson(summaryPath,summary);
end
outcome.paths.run_summary = summaryPath;
end

function summary = buildStandardSummary(outcome,config,backend)
summary = struct();
summary.schema_version = "1.0";
summary.backend = backend;
summary.status = string(outcome.status);
summary.scenario = textField(config,"scenario","");

if backend == "kwsim"
    summary.spatial_dimension = numericField(config,"dimension",NaN);
    summary.frequency_hz = nestedNumeric(config,["source","f0_hz"]);
    summary.background_cs_m_s = nestedNumeric(config,["medium","cs_m_s"]);
    if isfield(outcome,"result") && isfield(outcome.result,"runtime_s")
        summary.elapsed_solver_time_s = double(outcome.result.runtime_s);
    else
        summary.elapsed_solver_time_s = NaN;
    end
    if isfield(outcome,"report") && isfield(outcome.report,"valid")
        summary.valid = logical(outcome.report.valid);
    else
        summary.valid = true;
    end
else
    if isfield(config,"domain") && isfield(config.domain,"Ly_m")
        summary.spatial_dimension = 3;
    else
        summary.spatial_dimension = 2;
    end
    summary.frequency_hz = nestedNumeric(config,["wavefield","frequency_hz"]);
    summary.background_cs_m_s = nestedNumeric(config,["medium","background_cs_m_s"]);
    if isfield(outcome,"validation") && isfield(outcome.validation,"valid")
        summary.valid = logical(outcome.validation.valid);
    else
        summary.valid = true;
    end
end
summary.run_directory = string(outcome.run_directory);
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
if isAbsolutePath(value), return, end
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

function value = textField(s,name,defaultValue)
if isstruct(s) && isfield(s,name)
    value = string(s.(name));
else
    value = string(defaultValue);
end
end

function value = numericField(s,name,defaultValue)
if isstruct(s) && isfield(s,name)
    value = double(s.(name));
else
    value = double(defaultValue);
end
end

function value = nestedNumeric(s,path)
value = NaN;
current = s;
for name = path
    if ~isstruct(current) || ~isfield(current,name), return, end
    current = current.(name);
end
if (isnumeric(current) || islogical(current)) && isscalar(current)
    value = double(current);
end
end

function writeJson(pathValue,value)
fileId = fopen(pathValue,"w");
if fileId < 0
    error("simrunner:OutputWriteFailed","Could not write %s",pathValue);
end
cleanup = onCleanup(@() fclose(fileId));
fprintf(fileId,"%s",jsonencode(value,PrettyPrint=true));
end
