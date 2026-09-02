function result = run_example(options)
%RUN_EXAMPLE Run a true volumetric 3D synthetic homogeneous example.
arguments
    options.PlotFigures (1,1) logical = true
    options.FigureVisible (1,1) string = "off"
end

example_root = fileparts(mfilename("fullpath"));
repo_root = fileparts(fileparts(fileparts(fileparts(example_root))));
addpath(fullfile(repo_root,"src"));

config = jsondecode(fileread(fullfile(example_root,"config.json")));
result = swsynth.run3D(config);

if options.PlotFigures
    result.figure_files = simviz.generateSampleFigures( ...
        result.sample, fullfile(example_root,"figures"), ...
        Visible=options.FigureVisible);
end
end
