function files = generateSampleFigures(sample, figureDirectory, options)
%GENERATESAMPLEFIGURES Generate standard figures directly from a wavefield sample.
arguments
    sample (1,1) struct
    figureDirectory {mustBeTextScalar}
    options.Visible (1,1) string = "off"
    options.ResolutionDPI (1,1) double {mustBePositive} = 300
end

figureDirectory = string(figureDirectory);
if ~isfolder(figureDirectory), mkdir(figureDirectory); end

files = struct();
files.sws = fullfile(figureDirectory,"sws.png");
files.field = fullfile(figureDirectory,"wavefield_real.png");
files.phase = fullfile(figureDirectory,"wavefield_phase.png");
files.amplitude = fullfile(figureDirectory,"wavefield_amplitude.png");

exportOne(@() simviz.plotSws(sample,Visible=options.Visible),files.sws,options.ResolutionDPI);
exportOne(@() simviz.plotField(sample,Visible=options.Visible),files.field,options.ResolutionDPI);
exportOne(@() simviz.plotPhase(sample,Visible=options.Visible),files.phase,options.ResolutionDPI);
exportOne(@() simviz.plotAmplitude(sample,Visible=options.Visible),files.amplitude,options.ResolutionDPI);

if isfield(sample,"directions") && isfield(sample.directions,"xyz") && ~isempty(sample.directions.xyz)
    files.directions = fullfile(figureDirectory,"directions.png");
    exportOne(@() simviz.plotDirections(sample,Visible=options.Visible),files.directions,options.ResolutionDPI);
end

if double(sample.spatial_dimension) == 3
    files.sws_crossplanes = fullfile(figureDirectory,"sws_crossplanes.png");
    files.wavefield_amplitude_crossplanes = fullfile(figureDirectory,"wavefield_amplitude_crossplanes.png");
    files.wavefield_phase_crossplanes = fullfile(figureDirectory,"wavefield_phase_crossplanes.png");
    files.wavefield_real_crossplanes = fullfile(figureDirectory,"wavefield_real_crossplanes.png");

    exportOne(@() simviz.plotSwsCrossplanes(sample,Visible=options.Visible), ...
        files.sws_crossplanes,options.ResolutionDPI);
    exportOne(@() simviz.plotAmplitudeCrossplanes(sample,Visible=options.Visible), ...
        files.wavefield_amplitude_crossplanes,options.ResolutionDPI);
    exportOne(@() simviz.plotPhaseCrossplanes(sample,Visible=options.Visible), ...
        files.wavefield_phase_crossplanes,options.ResolutionDPI);
    exportOne(@() simviz.plotFieldCrossplanes(sample,Visible=options.Visible), ...
        files.wavefield_real_crossplanes,options.ResolutionDPI);
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
