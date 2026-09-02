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
if ~isfolder(figDir), mkdir(figDir); end

files = struct();
files.sws = fullfile(figDir,"sws.png");
files.field = fullfile(figDir,"wavefield_real.png");
files.phase = fullfile(figDir,"wavefield_phase.png");
files.amplitude = fullfile(figDir,"wavefield_amplitude.png");
files.directions = fullfile(figDir,"directions.png");

exportOne(@() simviz.plotSws(sample,Visible=options.Visible),files.sws,options.ResolutionDPI);
exportOne(@() simviz.plotField(sample,Visible=options.Visible),files.field,options.ResolutionDPI);
exportOne(@() simviz.plotPhase(sample,Visible=options.Visible),files.phase,options.ResolutionDPI);
exportOne(@() simviz.plotAmplitude(sample,Visible=options.Visible),files.amplitude,options.ResolutionDPI);
exportOne(@() simviz.plotDirections(sample,Visible=options.Visible),files.directions,options.ResolutionDPI);

% k-Wave 3D runs have finite-distance source locations. Preserve that
% physical distinction: synthetic directional fields do not invent source
% positions and therefore use directions.png only.
configFile = fullfile(runDirectory,"config","resolved_config.json");
if isfile(configFile)
    try
        cfg = jsondecode(fileread(configFile));
        if isfield(cfg,"dimension") && double(cfg.dimension)==3 && isfield(cfg,"source")
            handles = kwsim.viz.plotSourceGeometry3D(cfg,FigureVisible=options.Visible);
            files.source_geometry = fullfile(figDir,"source_geometry.png");
            exportgraphics(handles.figure,files.source_geometry,"Resolution",options.ResolutionDPI);
            if options.Visible=="off", close(handles.figure); end
        end
    catch exception
        warning("simviz:SourceGeometrySkipped","Could not render source geometry: %s",exception.message);
    end
end
end

function exportOne(factory,pathValue,resolution)
fig = factory();
cleanup = onCleanup(@() closeIfValid(fig));
exportgraphics(fig,pathValue,"Resolution",resolution);
clear cleanup
closeIfValid(fig);
end

function closeIfValid(fig)
if isgraphics(fig,"figure"), close(fig); end
end
