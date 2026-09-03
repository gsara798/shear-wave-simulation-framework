function environment = setup_simulation_framework(options)
%SETUP_SIMULATION_FRAMEWORK Configure the framework for this MATLAB session.
%
% From the repository root:
%   setup_simulation_framework
%
% Optionally register an external k-Wave installation:
%   setup_simulation_framework( ...
%       KWavePath="/absolute/path/to/k-wave-toolbox-version-1.4.1")

arguments
    options.KWavePath {mustBeTextScalar} = ""
    options.Quiet (1,1) logical = false
end

repositoryRoot = string(fileparts(mfilename("fullpath")));
sourceDirectory = fullfile(repositoryRoot,"src");

if ~isfolder(sourceDirectory)
    error("simulation:InvalidRepositoryRoot", ...
        "Could not find the repository src directory: %s",sourceDirectory);
end

% Keep public root entry points and package sources available after cd.
addpath(repositoryRoot);
addpath(sourceDirectory);

kWavePath = string(options.KWavePath);
if strlength(kWavePath) > 0
    if ~isfolder(kWavePath)
        error("simulation:KWavePathNotFound", ...
            "The requested k-Wave directory does not exist: %s",kWavePath);
    end
    setenv("KWSIM_KWAVE_PATH",kWavePath);
else
    kWavePath = string(getenv("KWSIM_KWAVE_PATH"));
end

environment = struct();
environment.repository_root = repositoryRoot;
environment.src = sourceDirectory;
environment.examples = fullfile(repositoryRoot,"examples");
environment.configs = fullfile(repositoryRoot,"configs");
environment.kwave_path = kWavePath;

if ~options.Quiet
    fprintf("\nShear-wave simulation framework ready.\n");
    fprintf("Repository: %s\n",repositoryRoot);
    if strlength(kWavePath) > 0
        fprintf("k-Wave:     %s\n",kWavePath);
    else
        fprintf("k-Wave:     not configured (set KWSIM_KWAVE_PATH or use setup_simulation_framework(KWavePath=...))\n");
    end
    fprintf("\nRun any JSON configuration with:\n");
    fprintf('  outcome = run_simulation("path/to/config.json");\n\n');
end
end
