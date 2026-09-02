function files = generateRunFigures(runDirectory, options)
%GENERATERUNFIGURES Generate standard scientific figures for one saved run.
arguments
    runDirectory {mustBeTextScalar}
    options.Visible (1,1) string = "off"
    options.ResolutionDPI (1,1) double {mustBePositive} = 300
end

runDirectory = string(runDirectory);
sampleFile = fullfile(runDirectory,"data","wavefield_sample.mat");
if ~isfile(sampleFile)
    error("simviz:WavefieldSampleNotFound","Missing wavefield sample: %s",sampleFile);
end
loaded = load(sampleFile,"wavefield_sample");
sample = loaded.wavefield_sample;
figDir = fullfile(runDirectory,"figures");

files = simviz.generateSampleFigures( ...
    sample, figDir, ...
    Visible=options.Visible, ...
    ResolutionDPI=options.ResolutionDPI);

% k-Wave 3D runs have finite-distance source locations. Preserve that
% physical distinction: synthetic directional fields use directions.png,
% whereas k-Wave can additionally expose the actual source geometry.
configFile = fullfile(runDirectory,"config","resolved_config.json");
if isfile(configFile)
    try
        cfg = jsondecode(fileread(configFile));
        if isfield(cfg,"dimension") && double(cfg.dimension)==3 && isfield(cfg,"source")
            handles = kwsim.viz.plotSourceGeometry3D(cfg,FigureVisible=options.Visible);
            files.source_geometry = fullfile(figDir,"source_geometry.png");
            exportgraphics(handles.figure,files.source_geometry,"Resolution",options.ResolutionDPI);
            closeIfValid(handles.figure);
        end
    catch exception
        warning("simviz:SourceGeometrySkipped","Could not render source geometry: %s",exception.message);
    end
end
end

function closeIfValid(fig)
if isgraphics(fig,"figure"), close(fig); end
end
