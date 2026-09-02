function theme = paperTheme(options)
%PAPERTHEME Shared publication-style colors and typography.
%
% The palette mirrors the public REQ-ML paper theme so figures across the
% simulation and estimator repositories use consistent visual semantics.

arguments
    options.FontName (1,1) string = "Times New Roman"
    options.FontSizePt (1,1) double {mustBePositive} = 9
    options.LineWidth (1,1) double {mustBePositive} = 1.5
    options.MarkerSize (1,1) double {mustBePositive} = 5
    options.AxesLineWidth (1,1) double {mustBePositive} = 0.8
    options.ResolutionDPI (1,1) double {mustBePositive} = 300
end

colors = struct( ...
    "blue", struct("main","#4834D4","light","#686DE0"), ...
    "red", struct("main","#EB4D4B","light","#FF7979"), ...
    "green", struct("main","#6AB04C","light","#BADC58"), ...
    "teal", struct("main","#22A6B3","light","#7ED6DF"), ...
    "orange", struct("main","#F0932B","light","#FFBE76"), ...
    "gray", struct("main","#535C68","light","#95AFC0","dark","#130F40"));

roles = string(fieldnames(colors));
rgb = struct();
fills = struct();
for role = roles'
    variants = string(fieldnames(colors.(role)));
    for variant = variants'
        value = hexToRgb(colors.(role).(variant));
        rgb.(role).(variant) = value;
        fills.(role).(variant) = 0.22*value + 0.78*[1 1 1];
    end
end

theme = struct();
theme.schema_name = "simulation_paper_theme";
theme.schema_version = "1.0";
theme.colors = colors;
theme.rgb = rgb;
theme.fills = fills;
theme.style = struct( ...
    "font_name",options.FontName, ...
    "font_size_pt",options.FontSizePt, ...
    "line_width",options.LineWidth, ...
    "marker_size",options.MarkerSize, ...
    "axes_line_width",options.AxesLineWidth);
theme.figure = struct("resolution_dpi",options.ResolutionDPI);
end

function rgb = hexToRgb(value)
text = erase(string(value),"#");
parts = sscanf(char(text),"%2x%2x%2x");
if numel(parts) ~= 3
    error("simviz:InvalidThemeColor","Could not parse theme color '%s'.",value);
end
rgb = double(parts(:)')/255;
end
