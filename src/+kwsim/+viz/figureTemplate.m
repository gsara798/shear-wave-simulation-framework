function style = figureTemplate()
%FIGURETEMPLATE Return the shared publication-style figure configuration.
%
% style = kwsim.viz.figureTemplate()
%
% Every project figure should obtain typography and export settings from
% this function. Keeping these values in one place prevents inconsistent
% fonts, undersized labels, and different export resolutions across
% simulation stages. Times New Roman is used because it is widely available
% and provides the requested Times-style scientific typography.

style = struct();
style.font_name = "Times New Roman";
style.axes_font_size_pt = 12;
style.label_font_size_pt = 12;
style.title_font_size_pt = 12;
style.figure_title_font_size_pt = 14;
style.legend_font_size_pt = 11;
style.axes_line_width_pt = 0.8;
style.data_line_width_pt = 1.4;
style.export_resolution_dpi = 300;
style.background_color = [1, 1, 1];

end
