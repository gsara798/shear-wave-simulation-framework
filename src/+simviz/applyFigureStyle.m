function applyFigureStyle(fig, theme)
%APPLYFIGURESTYLE Apply shared typography to a completed figure.
arguments
    fig (1,1) matlab.ui.Figure
    theme struct = simviz.paperTheme()
end
fig.Color = [1 1 1];
fontObjects = findall(fig,'-property','FontName');
set(fontObjects,'FontName',char(theme.style.font_name));
axesHandles = findall(fig,'Type','axes');
for i = 1:numel(axesHandles)
    ax = axesHandles(i);
    ax.FontName = char(theme.style.font_name);
    ax.FontSize = theme.style.font_size_pt;
    ax.LineWidth = theme.style.axes_line_width;
    ax.TickDir = 'out';
    ax.Layer = 'top';
    ax.Box = 'on';
end
end
