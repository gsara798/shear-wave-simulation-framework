function [figure_handle, output_file] = plotAxialField(result, report, output_file, options)
%PLOTAXIALFIELD Visualize the complex axial field used as the measurement.
%
% kwsim.diagnostics.plotAxialField(result, report)
% kwsim.diagnostics.plotAxialField(result, report, output_file)
%
% By default, the plotted quantity is axial displacement, because this is
% the field most directly associated with ultrasound elastography motion.
% Set Quantity="velocity" to inspect particle velocity instead. Public maps
% follow the project convention [Nz,Nx], with x lateral and z axial/depth.
%
% The first row contains the amplitude and wrapped phase of the total axial
% measurement plus the shear-only amplitude. The second row exposes the
% compressional contribution, the local axial P/S ratio, and the spatial
% phase fit used to estimate shear-wave speed. Phase is displayed over the
% complete ROI; its reliability should be judged together with amplitude.
%
% Inputs
%   result       Output from kwsim.two_d.run.
%   report       Diagnostic report returned by the same run.
%   output_file  Optional PNG/PDF path. No file is written when empty.
%
% Name-value options
%   Quantity          "displacement" (default) or "velocity".
%   Visible           Whether to show the MATLAB figure (default true).
%   CloseAfterExport  Close the figure after writing (default false).

arguments
    result struct
    report struct
    output_file {mustBeTextScalar} = ""
    options.Quantity (1,1) string = "displacement"
    options.Visible (1,1) logical = true
    options.CloseAfterExport (1,1) logical = false
end

quantity = lower(options.Quantity);
style = kwsim.common.figureTemplate();
switch quantity
    case "displacement"
        fields = result.fields.displacement;
        display_scale = 1e9;
        display_units = "nm";
        symbol = "U_z";
    case "velocity"
        fields = result.fields.velocity;
        display_scale = 1e6;
        display_units = "\mum/s";
        symbol = "V_z";
    otherwise
        error('kwsim:InvalidPlotQuantity', ...
            'Quantity must be "displacement" or "velocity".');
end

total = fields.axial_total_zx;
shear = fields.axial_shear_zx;
compression = fields.axial_compression_zx;
amplitude = abs(total);
maximum_amplitude = max(amplitude, [], 'all');

% The ratio is computed from axial components because the figure diagnoses
% the public axial measurement. The run-level acceptance metric separately
% uses both vector components and is therefore not biased by axial projection.
axial_p_to_s_db = 20*log10((abs(compression) + eps) ./ (abs(shear) + eps));
compression_relative_db = 20*log10((abs(compression) + eps) ./ ...
    max(maximum_amplitude, eps));

x_mm = result.axes.x_m * 1e3;
z_mm = result.axes.z_m * 1e3;
visibility = char(matlab.lang.OnOffSwitchState(options.Visible));
figure_handle = figure('Visible', visibility, 'Color', style.background_color, ...
    'Position', [80, 80, 1450, 850]);
layout = tiledlayout(figure_handle, 2, 3, ...
    'TileSpacing', 'compact', 'Padding', 'compact');
if result.config_resolved.stage == 1
    heading = sprintf([ ...
        'Axial %s phasor at f_0 = %.1f Hz ', ...
        '(estimated c_s = %.4f m s^{-1})'], ...
        quantity, result.axes.f0_hz, report.metrics.shear_speed.speed_m_s);
else
    heading = sprintf('Axial %s phasor at f_0 = %.1f Hz (heterogeneous medium)', ...
        quantity, result.axes.f0_hz);
end
figure_title = title(layout, heading);
figure_title.FontSize = style.figure_title_font_size_pt;
figure_title.FontName = char(style.font_name);

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, display_scale * amplitude);
formatSpatialAxis(axis_handle);
colormap(axis_handle, parula);
colorbar(axis_handle);
title(axis_handle, sprintf('Total axial amplitude, |%s| (%s)', ...
    symbol, display_units));

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, angle(total));
formatSpatialAxis(axis_handle);
clim(axis_handle, [-pi, pi]);
colormap(axis_handle, hsv);
colorbar(axis_handle);
title(axis_handle, sprintf('Total axial phase, \\angle %s (rad)', symbol));

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, display_scale * abs(shear));
formatSpatialAxis(axis_handle);
colormap(axis_handle, parula);
colorbar(axis_handle);
title(axis_handle, sprintf('Shear-component amplitude, |%s^{(S)}| (%s)', ...
    symbol, display_units));

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, max(compression_relative_db, -80));
formatSpatialAxis(axis_handle);
clim(axis_handle, [-80, 0]);
colormap(axis_handle, turbo);
colorbar(axis_handle);
title(axis_handle, {'Relative compressional amplitude', ...
    '20 log_{10}(|U_z^{(P)}|/max|U_z|) (dB)'});

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, min(max(axial_p_to_s_db, -80), 20));
formatSpatialAxis(axis_handle);
clim(axis_handle, [-80, 20]);
colormap(axis_handle, turbo);
colorbar(axis_handle);
title(axis_handle, {'Local axial P/S amplitude ratio', ...
    '20 log_{10}(|U_z^{(P)}|/|U_z^{(S)}|) (dB)'});

axis_handle = nexttile(layout);
speed = report.metrics.shear_speed;
plot(axis_handle, speed.x_fit_m * 1e3, speed.phase_fit_rad, '.', ...
    'DisplayName', 'Unwrapped shear phase');
hold(axis_handle, 'on');
plot(axis_handle, speed.x_fit_m * 1e3, speed.phase_prediction_rad, '-', ...
    'LineWidth', style.data_line_width_pt, ...
    'DisplayName', 'Least-squares linear fit');
hold(axis_handle, 'off');
grid(axis_handle, 'on');
legend(axis_handle, 'Location', 'best');
xlabel(axis_handle, 'Lateral position, x (mm)');
ylabel(axis_handle, 'Unwrapped phase (rad)');
if result.config_resolved.stage == 1
    title(axis_handle, sprintf('Shear-phase fit (c_s error = %.3f%%)', ...
        100*report.metrics.shear_speed_relative_error));
else
    title(axis_handle, 'Global shear-phase trend (descriptive only)');
end

kwsim.common.applyFigureStyle(figure_handle, style);
figure_title.FontSize = style.figure_title_font_size_pt;

output_file = string(output_file);
if strlength(output_file) > 0
    output_directory = fileparts(output_file);
    if strlength(string(output_directory)) > 0 && ~isfolder(output_directory)
        mkdir(output_directory);
    end
    exportgraphics(figure_handle, output_file, ...
        'Resolution', style.export_resolution_dpi, ...
        'BackgroundColor', style.background_color);
end

if options.CloseAfterExport
    close(figure_handle);
end

end

function formatSpatialAxis(axis_handle)
%FORMATSPATIALAXIS Apply the public x-lateral/z-depth display convention.
axis(axis_handle, 'image');
axis_handle.YDir = 'reverse';
xlabel(axis_handle, 'Lateral position, x (mm)');
ylabel(axis_handle, 'Axial position, z (mm)');
end
