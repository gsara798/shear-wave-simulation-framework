function pdfFile = generateRunPdf(runDirectory, options)
%GENERATERUNPDF Build a lightweight PDF report for one simulation run.
arguments
    runDirectory {mustBeTextScalar}
    options.RegenerateFigures (1,1) logical = false
end

runDirectory = string(runDirectory);
figDir = fullfile(runDirectory,"figures");
baseRequired = ["sws.png","wavefield_real.png","wavefield_phase.png","wavefield_amplitude.png"];

if options.RegenerateFigures || ~all(isfile(fullfile(figDir,baseRequired)))
    simviz.generateRunFigures(runDirectory);
end

reportDir = fullfile(runDirectory,"report");
if ~isfolder(reportDir), mkdir(reportDir); end
pdfFile = fullfile(reportDir,"run_report.pdf");
if isfile(pdfFile), delete(pdfFile); end

summary = readJsonIfPresent(fullfile(runDirectory,"data","run_summary.json"));
if isempty(fieldnames(summary))
    summary = readJsonIfPresent(fullfile(runDirectory,"run_summary.json"));
end
config = readJsonIfPresent(fullfile(runDirectory,"config","resolved_config.json"));

cover = figure("Visible","off","Color","w","Position",[100 100 900 1150]);
cleanup = onCleanup(@() closeIfValid(cover));
ax = axes(cover,"Position",[0.08 0.08 0.84 0.84]); axis(ax,"off");

frequency = nestedNumber(config,["wavefield","frequency_hz"]);
if ~isfinite(frequency), frequency = nestedNumber(config,["source","f0_hz"]); end
backgroundSws = nestedNumber(config,["medium","background_cs_m_s"]);
if ~isfinite(backgroundSws), backgroundSws = nestedNumber(config,["medium","cs_m_s"]); end

lines = [
    "Simulation run report"
    ""
    "Run: " + string(lastPathPart(runDirectory))
    "Scenario: " + textValue(config,"scenario")
    "Backend: " + textValue(summary,"backend")
    "Dimension: " + numberText(nestedNumber(config,["dimension"])) + "D"
    "Frequency: " + numberText(frequency) + " Hz"
    "Background SWS: " + numberText(backgroundSws) + " m/s"
    "Directions: " + numberText(nestedNumber(config,["directions","count"]))
    "Direction space: " + nestedText(config,["directions","space"])
    "Propagation model: " + nestedText(config,["propagation","model"])
    "Phase model: " + nestedText(config,["propagation","phase_model"])
];
text(ax,0,1,strjoin(lines,newline),"VerticalAlignment","top", ...
    "Interpreter","none","FontName","Times New Roman","FontSize",14);
exportgraphics(cover,pdfFile,"ContentType","vector");
clear cleanup
closeIfValid(cover);

figureNames = [ ...
    "sws.png", ...
    "wavefield_real.png", ...
    "wavefield_phase.png", ...
    "wavefield_amplitude.png", ...
    "directions.png", ...
    "sws_crossplanes.png", ...
    "wavefield_real_crossplanes.png", ...
    "wavefield_phase_crossplanes.png", ...
    "wavefield_amplitude_crossplanes.png", ...
    "source_geometry.png"];

for name = figureNames
    pathValue = fullfile(figDir,name);
    if isfile(pathValue), appendImagePage(pathValue,pdfFile); end
end
end

function appendImagePage(imageFile,pdfFile)
img = imread(imageFile);
fig = figure("Visible","off","Color","w","Position",[100 100 900 1150]);
cleanup = onCleanup(@() closeIfValid(fig));
ax = axes(fig,"Position",[0.03 0.03 0.94 0.94]); image(ax,img); axis(ax,"image"); axis(ax,"off");
exportgraphics(fig,pdfFile,"ContentType","image","Append",true,"Resolution",200);
clear cleanup
closeIfValid(fig);
end

function closeIfValid(fig)
if isgraphics(fig,"figure"), close(fig); end
end

function value = readJsonIfPresent(pathValue)
if isfile(pathValue), value=jsondecode(fileread(pathValue)); else, value=struct(); end
end
function value = textValue(s,name)
if isstruct(s)&&isfield(s,name), value=string(s.(name)); else, value=""; end
end
function value = nestedText(s,path)
value=""; current=s;
for p=path
    if ~isstruct(current)||~isfield(current,p), return; end
    current=current.(p);
end
if ischar(current)||isstring(current), value=string(current); end
end
function value = nestedNumber(s,path)
value=NaN; current=s;
for p=path
    if ~isstruct(current)||~isfield(current,p), return; end
    current=current.(p);
end
if (isnumeric(current)||islogical(current))&&isscalar(current), value=double(current); end
end
function textValueOut = numberText(value)
if isfinite(value), textValueOut=string(sprintf("%.6g",value)); else, textValueOut="n/a"; end
end
function part = lastPathPart(pathValue)
[~,part]=fileparts(pathValue);
end
