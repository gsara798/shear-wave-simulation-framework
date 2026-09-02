function results = run_all(options)
%RUN_ALL Run public examples from the organized example tree.
arguments
    options.RunKWave (1,1) logical = false
    options.PlotFigures (1,1) logical = true
end

examples_root = fileparts(mfilename("fullpath"));
results = struct();

results.swsynth_2d = call_example( ...
    fullfile(examples_root,"swsynth","2d","homogeneous"), ...
    @() run_example(ShowPlot=options.PlotFigures));
results.projected3d_inclusion = call_example( ...
    fullfile(examples_root,"swsynth","projected3d","inclusion"), ...
    @() run_example(ShowPlot=options.PlotFigures));
results.projected3d_bilayer = call_example( ...
    fullfile(examples_root,"swsynth","projected3d","bilayer"), ...
    @() run_example(ShowPlot=options.PlotFigures));

for name = ["homogeneous","inclusion","bilayer"]
    field = matlab.lang.makeValidName("volumetric3d_" + name);
    results.(field) = call_example( ...
        fullfile(examples_root,"swsynth","volumetric3d",name), ...
        @() run_example(PlotFigures=options.PlotFigures));
end

results.field_regime_campaign = call_example( ...
    fullfile(examples_root,"swsynth","projected3d","campaign_field_regimes"), ...
    @() run_campaign(Execute=false));

if options.RunKWave
    for dimension = ["2d","3d"]
        for name = ["homogeneous","inclusion","bilayer"]
            field = matlab.lang.makeValidName("kwave_" + dimension + "_" + name);
            results.(field) = call_example( ...
                fullfile(examples_root,"kwave",dimension,name), ...
                @() run_example(DryRun=false,PlotFigures=options.PlotFigures));
        end
    end
end
end

function value = call_example(folder,callback)
addpath(folder);
cleanup = onCleanup(@() rmpath(folder)); %#ok<NASGU>
value = callback();
end
