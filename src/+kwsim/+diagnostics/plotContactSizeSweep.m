function [fig, output_file] = plotContactSizeSweep(sweep, output_file)
%PLOTCONTACTSIZESWEEP Visualize point-limit sensitivity of finite contacts.

arguments
    sweep struct
    output_file {mustBeTextScalar} = ""
end

style = kwsim.common.figureTemplate();
results = [{sweep.point_result}; sweep.finite_results(:)];
count = numel(results);
if count ~= 3
    error('kwsim:ContactSweepFigureCount', ...
        'The standard figure expects point, 4 mm, and 8 mm results.');
end

maximum_amplitude_nm = 0;
for index = 1:count
    amplitude_nm = abs( ...
        results{index}.fields.displacement.axial_total_zx)*1e9;
    maximum_amplitude_nm = max(maximum_amplitude_nm, max(amplitude_nm, [], 'all'));
end

fig = figure('Visible', 'off', 'Color', style.background_color, ...
    'Position', [80, 80, 1450, 850]);
layout = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
for index = 1:count
    result = results{index};
    nexttile(layout, index);
    imagesc(result.axes.x_m*1e3, result.axes.z_m*1e3, ...
        abs(result.fields.displacement.axial_total_zx)*1e9);
    axis image; set(gca, 'YDir', 'reverse'); clim([0, maximum_amplitude_nm]);
    colorbar; xlabel('Lateral position, x (mm)');
    ylabel('Axial position, z (mm)');
    title(sprintf('$|U_{z,\\mathrm{total}}|$, span = %.1f mm', ...
        1e3*sweep.contact_span_m(index)), 'Interpreter', 'latex');
end

nexttile(layout, 4);
hold on;
for index = 2:count
    vibrator = results{index}.source.vibrators(1);
    tangent_mm = linspace(-0.5, 0.5, vibrator.contact_node_count).' * ...
        vibrator.realized_contact_span_m*1e3;
    plot(tangent_mm, vibrator.contact_node_weights, '-o', 'LineWidth', 1.4, ...
        'DisplayName', sprintf('%.1f mm', 1e3*sweep.contact_span_m(index)));
end
hold off; grid on; legend('Location', 'best');
xlabel('Tangential contact coordinate (mm)'); ylabel('Relative velocity weight');
title('Finite-contact profiles');

nexttile(layout, 5);
plot(1e3*sweep.contact_span_m, sweep.correlation_magnitude_to_point, ...
    '-o', 'LineWidth', 1.4); grid on; ylim([0, 1.05]);
xlabel('Contact span (mm)'); ylabel('Complex correlation magnitude');
title('Similarity to point-source field');

nexttile(layout, 6);
plot(1e3*sweep.contact_span_m, ...
    sweep.optimal_scaled_shape_relative_error, '-o', 'LineWidth', 1.4);
grid on; ylim([0, 1.05]); xlabel('Contact span (mm)');
ylabel('Relative shape error'); title('Error after optimal complex scaling');

title(layout, sprintf('Contact-size sensitivity at f_0 = %.1f Hz | valid = %d', ...
    sweep.point_result.axes.f0_hz, sweep.valid));
kwsim.common.applyFigureStyle(fig, style);

output_file = string(output_file);
if strlength(output_file) > 0
    exportgraphics(fig, output_file, 'Resolution', style.export_resolution_dpi, ...
        'BackgroundColor', style.background_color);
end

end
