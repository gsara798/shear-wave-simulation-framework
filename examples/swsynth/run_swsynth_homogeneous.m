function outcome = run_swsynth_homogeneous(options)
%RUN_SWSYNTH_HOMOGENEOUS Run a lightweight homogeneous synthetic example.

arguments
    options.DryRun (1,1) logical = false
    options.OutputDirectory {mustBeTextScalar} = ""
end

repo_root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(repo_root, "src"));

config_file = fullfile(repo_root, "configs", "swsynth", ...
    "homogeneous_campaign_base.json");

outcome = swsynth.cli.runConfig( ...
    config_file, ...
    DryRun=options.DryRun, ...
    OutputDirectory=options.OutputDirectory);
end
