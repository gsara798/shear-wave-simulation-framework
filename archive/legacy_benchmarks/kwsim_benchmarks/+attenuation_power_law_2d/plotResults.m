function [fig, output_file] = plotResults(sweep, output_file)
%PLOTRESULTS Summarize target recovery across monofrequency runs.

arguments
    sweep struct
    output_file {mustBeTextScalar} = ""
end

style = kwsim.viz.figureTemplate();
fig = figure('Visible', 'off', 'Color', style.background_color, ...
    'Position', [80, 80, 1350, 850]);
layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
frequencies = sweep.frequencies_hz;

ax = nexttile(layout);
loglog(ax, frequencies, sweep.target_attenuation_db_cm, 'o-', ...
    'LineWidth', style.data_line_width_pt, 'DisplayName', 'Target');
hold(ax, 'on');
loglog(ax, frequencies, sweep.recovered_attenuation_db_cm, 's--', ...
    'LineWidth', style.data_line_width_pt, 'DisplayName', 'Estimated');
hold(ax, 'off'); grid(ax, 'on'); legend(ax, 'Location', 'best');
xlabel(ax, 'Frequency, f_0 (Hz)'); ylabel(ax, '\alpha_S (dB cm^{-1})');
title(ax, sprintf('Power-law fit: target y = %.3f; estimated y = %.3f', ...
    sweep.requested_power_y, sweep.recovered_power_y));

ax = nexttile(layout);
plot(ax, frequencies, 100*sweep.relative_errors, 'o-', ...
    'LineWidth', style.data_line_width_pt); grid(ax, 'on');
yline(ax, 100*sweep.base_configuration.diagnostics.maximum_attenuation_relative_error, ...
    '--', 'Acceptance limit');
xlabel(ax, 'Frequency, f_0 (Hz)'); ylabel(ax, 'Attenuation error (%)');
title(ax, 'Per-frequency attenuation error');

ax = nexttile(layout);
speed_changes = arrayfun(@(p) 100*p.estimate.speed_relative_difference, ...
    sweep.pairs);
plot(ax, frequencies, speed_changes, 'o-', ...
    'LineWidth', style.data_line_width_pt); grid(ax, 'on');
speed_limit = sweep.base_configuration.diagnostics.maximum_attenuated_speed_relative_difference;
yline(ax, 100*speed_limit, '--', 'Acceptance limit');
xlabel(ax, 'Frequency, f_0 (Hz)');
ylabel(ax, '|c_{S,att}-c_{S,0}|/c_{S,0} (%)');
title(ax, 'Shear phase-speed change');

ax = nexttile(layout);
pair = sweep.pairs(end);
fit = pair.estimate.vector_shear;
plot(ax, fit.distance_cm, fit.measured_loss_db, '.', ...
    'DisplayName', 'Matched loss'); hold(ax, 'on');
plot(ax, fit.distance_cm, fit.predicted_loss_db, '-', ...
    'LineWidth', style.data_line_width_pt, 'DisplayName', 'Linear fit');
hold(ax, 'off'); grid(ax, 'on'); legend(ax, 'Location', 'best');
xlabel(ax, 'Propagation distance (cm)'); ylabel(ax, 'Amplitude loss (dB)');
title(ax, sprintf('Spatial fit at %.1f Hz (R^2 = %.4f)', ...
    pair.frequency_hz, fit.r_squared));

heading = title(layout, { ...
    'Monofrequency power-law attenuation validation'; ...
    sprintf('|y_{estimated} - y_{target}| = %.4f; valid = %d', ...
        sweep.power_y_absolute_error, sweep.valid)});
kwsim.viz.applyFigureStyle(fig, style);
heading.FontName = char(style.font_name);
heading.FontSize = style.figure_title_font_size_pt;

output_file = string(output_file);
if strlength(output_file) > 0
    exportgraphics(fig, output_file, 'Resolution', style.export_resolution_dpi, ...
        'BackgroundColor', style.background_color);
end

end
