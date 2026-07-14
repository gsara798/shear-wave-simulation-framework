function applyFigureStyle(figure_handle, style)
%APPLYFIGURESTYLE Apply the shared typography to a completed MATLAB figure.
%
% kwsim.common.applyFigureStyle(fig)
%
% Call this function after creating axes, labels, titles, legends, and
% colorbars. It applies the template recursively, including objects created
% internally by tiledlayout and colorbar.

arguments
    figure_handle (1,1) matlab.ui.Figure
    style struct = kwsim.common.figureTemplate()
end

figure_handle.Color = style.background_color;

font_objects = findall(figure_handle, '-property', 'FontName');
set(font_objects, 'FontName', char(style.font_name));

text_objects = findall(figure_handle, '-property', 'FontSize');
set(text_objects, 'FontSize', style.axes_font_size_pt);

axes_handles = findall(figure_handle, 'Type', 'axes');
for index = 1:numel(axes_handles)
    axis_handle = axes_handles(index);
    axis_handle.FontName = char(style.font_name);
    axis_handle.FontSize = style.axes_font_size_pt;
    axis_handle.LineWidth = style.axes_line_width_pt;
    axis_handle.TickDir = 'out';
    axis_handle.Layer = 'top';
    axis_handle.XLabel.FontSize = style.label_font_size_pt;
    axis_handle.YLabel.FontSize = style.label_font_size_pt;
    axis_handle.Title.FontSize = style.title_font_size_pt;
    axis_handle.Title.FontWeight = 'bold';
end

legend_handles = findall(figure_handle, 'Type', 'legend');
set(legend_handles, 'FontSize', style.legend_font_size_pt);

end
