function environment = setup(options)
%SETUP Configure shear-wave-simulation-framework for the current MATLAB session.
%
% From the repository root:
%   setup
%
% Optionally register an external k-Wave installation:
%   setup(KWavePath="/absolute/path/to/k-wave-toolbox-version-1.4.1")

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

% Keep the public root entry points (setup/run_simulation) and package
% source available even after the user changes the MATLAB working folder.
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
        fprintf("k-Wave:     not configured (set KWSIM_KWAVE_PATH or use setup(KWavePath=...))\n");
    end
    fprintf("\nRun any JSON configuration with:\n");
    fprintf("  outcome = run_simulation(\"path/to/config.json\");\n\n");
end
end
