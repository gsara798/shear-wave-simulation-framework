function results = run_all(options)
%RUN_ALL Run lightweight public examples from the reorganized tree.

arguments
    options.RunKWave (1,1) logical = false
    options.ShowPlots (1,1) logical = true
end

examples_root = fileparts(mfilename("fullpath"));

results = struct();
results.swsynth_2d = call_example( ...
    fullfile(examples_root,"swsynth","2d","homogeneous"), ...
    @() run_example(ShowPlot=options.ShowPlots));

results.projected3d_inclusion = call_example( ...
    fullfile(examples_root,"swsynth","projected3d","inclusion"), ...
    @() run_example(ShowPlot=options.ShowPlots));

results.projected3d_bilayer = call_example( ...
    fullfile(examples_root,"swsynth","projected3d","bilayer"), ...
    @() run_example(ShowPlot=options.ShowPlots));

results.volumetric3d = call_example( ...
    fullfile(examples_root,"swsynth","volumetric3d","homogeneous"), ...
    @() run_example(ShowPlot=options.ShowPlots));

results.field_regime_campaign = call_example( ...
    fullfile(examples_root,"swsynth","projected3d","campaign_field_regimes"), ...
    @() run_campaign(Execute=false));

if options.RunKWave
    results.kwave_2d = call_example( ...
        fullfile(examples_root,"kwave","2d","homogeneous"), ...
        @() run_example(DryRun=false,ShowValidationPlot=options.ShowPlots));

    results.kwave_3d = call_example( ...
        fullfile(examples_root,"kwave","3d","homogeneous"), ...
        @() run_example(DryRun=false,ShowValidationPlot=options.ShowPlots));
end
end

function value = call_example(folder,callback)
addpath(folder);
cleanup = onCleanup(@() rmpath(folder)); %#ok<NASGU>
value = callback();
end
