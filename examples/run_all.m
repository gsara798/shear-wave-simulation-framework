function results = run_all(options)
%RUN_ALL Run the user-facing framework examples.
%
% k-Wave examples default to dry-run mode because full 3D solver execution
% can be expensive. Set RunKWave=true to execute them.

arguments
    options.RunKWave (1,1) logical = false
    options.ShowValidationPlots (1,1) logical = true
end

examples_root = fileparts(mfilename("fullpath"));
addpath(examples_root);
addpath(fullfile(examples_root, "kwave"));
addpath(fullfile(examples_root, "swsynth"));

results = struct();
results.swsynth = run_swsynth_homogeneous();
results.kwave_2d = run_homogeneous_2d( ...
    DryRun=~options.RunKWave, ...
    ShowValidationPlot=options.ShowValidationPlots);
results.kwave_3d = run_homogeneous_3d( ...
    DryRun=~options.RunKWave, ...
    ShowValidationPlot=options.ShowValidationPlots);
end
