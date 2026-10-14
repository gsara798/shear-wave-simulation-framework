function outcomes = run_example(options)
%RUN_EXAMPLE Framework-native point and finite coherent line apertures.
arguments
    options.DryRun (1,1) logical = false
    options.PlotFigures (1,1) logical = true
    options.FigureVisible = "off"
    options.GeneratePdf (1,1) logical = false
end
exampleDir=string(fileparts(mfilename("fullpath")));
repositoryRoot=string(fileparts(fileparts(fileparts(fileparts(exampleDir)))));
addpath(repositoryRoot);
setup(Quiet=true);
names=["point","line_4mm","line_8mm"];
outcomes=cell(size(names));
for j=1:numel(names)
    outcomes{j}=run_simulation(fullfile(exampleDir,"config",names(j)+".json"), ...
        OutputRoot=fullfile(exampleDir,"outputs"), ...
        DryRun=options.DryRun,PlotFigures=options.PlotFigures, ...
        FigureVisible=options.FigureVisible,GeneratePdf=options.GeneratePdf);
end
end
