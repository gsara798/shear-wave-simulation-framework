function style = figureTemplate()
%FIGURETEMPLATE Return the shared publication-style figure configuration.
%
% k-Wave validation and public simulation figures use the same semantic
% palette and typography as the generic simulation visualization layer.

theme = simviz.paperTheme(FontSizePt=12,LineWidth=1.4,AxesLineWidth=0.8);

style = struct();
style.font_name = theme.style.font_name;
style.axes_font_size_pt = theme.style.font_size_pt;
style.label_font_size_pt = 12;
style.title_font_size_pt = 12;
style.figure_title_font_size_pt = 14;
style.legend_font_size_pt = 11;
style.axes_line_width_pt = theme.style.axes_line_width;
style.data_line_width_pt = theme.style.line_width;
style.export_resolution_dpi = theme.figure.resolution_dpi;
style.background_color = [1, 1, 1];
style.colors = theme.colors;
style.rgb = theme.rgb;
style.fills = theme.fills;
end
