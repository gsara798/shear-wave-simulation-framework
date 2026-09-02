function outcome = run_example(options)
%RUN_EXAMPLE Run and persist a volumetric 3D synthetic homogeneous example.
arguments
    options.PlotFigures (1,1) logical = true
    options.FigureVisible (1,1) string = "off"
    options.GeneratePdf (1,1) logical = false
end

example_root = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(fileparts(example_root))));
addpath(fullfile(repo_root,"src"));

config = jsondecode(fileread(fullfile(example_root,"config.json")));
outcome = simcampaigns.runSingle( ...
    config,"swsynth", ...
    OutputRoot=fullfile(example_root,"outputs"), ...
    PlotFigures=options.PlotFigures, ...
    FigureVisible=options.FigureVisible, ...
    GeneratePdf=options.GeneratePdf);
end
