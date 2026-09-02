function results = run_all(options)
%RUN_ALL Run representative public examples through the unified runner.
arguments
    options.RunKWave (1,1) logical = false
    options.PlotFigures (1,1) logical = true
end

examplesRoot = string(fileparts(mfilename("fullpath")));
repositoryRoot = fileparts(examplesRoot);
addpath(repositoryRoot);
setup(Quiet=true);

results = struct();

results.swsynth_2d = run_simulation( ...
    fullfile(examplesRoot,"swsynth","2d","homogeneous","config.json"), ...
    PlotFigures=options.PlotFigures);

results.projected3d_inclusion = run_simulation( ...
    fullfile(examplesRoot,"swsynth","projected3d","inclusion","config.json"), ...
    PlotFigures=options.PlotFigures);

results.projected3d_bilayer = run_simulation( ...
    fullfile(examplesRoot,"swsynth","projected3d","bilayer","config.json"), ...
    PlotFigures=options.PlotFigures);

for name = ["homogeneous","inclusion","bilayer"]
    field = matlab.lang.makeValidName("volumetric3d_" + name);
    results.(field) = run_simulation( ...
        fullfile(examplesRoot,"swsynth","volumetric3d",name,"config.json"), ...
        PlotFigures=options.PlotFigures);
end

if options.RunKWave
    for dimension = ["2d","3d"]
        for name = ["homogeneous","inclusion","bilayer"]
            field = matlab.lang.makeValidName("kwave_" + dimension + "_" + name);
            results.(field) = run_simulation( ...
                fullfile(examplesRoot,"kwave",dimension,name,"config.json"), ...
                PlotFigures=options.PlotFigures);
        end
    end
end
end
