function [figure_handle, output_file] = plotMotionComponents(result, report, output_file, options)
%PLOTMOTIONCOMPONENTS Compare axial and lateral complex motion fields.
%
% kwsim.viz.plotMotionComponents(result, report)
% kwsim.viz.plotMotionComponents(result, report, output_file)
%
% The source is polarized axially (+z). This figure compares the resulting
% total axial component with the total lateral (+x) component using a common
% amplitude scale. It also displays wrapped phase, the local lateral/axial
% amplitude ratio, and profiles along the source depth. Public fields follow
% the project convention [Nz,Nx], with x lateral and z axial/depth.
%
% Quantity="displacement" is the default for ultrasound elastography.
% Quantity="velocity" displays the corresponding particle velocities.
% Older MAT files without explicit lateral displacement fields are
% supported by deriving them from velocity using U = V/(i*2*pi*f0).

arguments
    result struct
    report struct
    output_file {mustBeTextScalar} = ""
    options.Quantity (1,1) string = "displacement"
    options.Visible (1,1) logical = true
    options.CloseAfterExport (1,1) logical = false
end

quantity = lower(options.Quantity);
style = kwsim.viz.figureTemplate();
fields = resolveFields(result, quantity);

switch quantity
    case "displacement"
        display_scale = 1e9;
        display_units = "nm";
        symbol = "U";
    case "velocity"
        display_scale = 1e6;
        display_units = "\mum/s";
        symbol = "V";
    otherwise
        error('kwsim:InvalidPlotQuantity', ...
            'Quantity must be "displacement" or "velocity".');
end

axial = fields.axial_total_zx;
lateral = fields.lateral_total_zx;
axial_amplitude = abs(axial);
lateral_amplitude = abs(lateral);
shared_maximum = max([axial_amplitude(:); lateral_amplitude(:)]);
lateral_to_axial_db = 20*log10((lateral_amplitude + eps) ./ ...
    (axial_amplitude + eps));

x_mm = result.axes.x_m * 1e3;
z_mm = result.axes.z_m * 1e3;
visibility = char(matlab.lang.OnOffSwitchState(options.Visible));
figure_handle = figure('Visible', visibility, 'Color', style.background_color, ...
    'Position', [80, 80, 1450, 850]);
layout = tiledlayout(figure_handle, 2, 3, ...
    'TileSpacing', 'compact', 'Padding', 'compact');
attenuation_enabled = isfield(result.truth, 'attenuation') && ...
    result.truth.attenuation.enabled;

has_geometry_objects = ...
    result.config_resolved.geometry.resolved.object_count > 0;

uses_vibrator_bank = ...
    isfield(result.config_resolved.source, 'layout') && ...
    lower(string(result.config_resolved.source.layout)) == "vibrator_bank";

is_homogeneous_single_contact = ...
    ~attenuation_enabled && ...
    ~has_geometry_objects && ...
    ~uses_vibrator_bank;

if is_homogeneous_single_contact
    heading = sprintf([ ...
        'Total %s components from an axially polarized source at ', ...
        'f_0 = %.1f Hz (estimated c_s = %.4f m s^{-1})'], ...
        quantity, result.axes.f0_hz, report.metrics.shear_speed.speed_m_s);
elseif attenuation_enabled
    heading = sprintf([ ...
        'Total %s components from an axially polarized source at ', ...
        'f_0 = %.1f Hz (attenuating medium)'], quantity, result.axes.f0_hz);
elseif has_geometry_objects
    heading = sprintf([ ...
        'Total %s components from an axially polarized source at ', ...
        'f_0 = %.1f Hz (heterogeneous medium)'], quantity, result.axes.f0_hz);
else
    heading = sprintf([ ...
        'Total %s components from an axially polarized source at ', ...
        'f_0 = %.1f Hz (homogeneous medium)'], quantity, result.axes.f0_hz);
end
figure_title = title(layout, heading);
figure_title.FontSize = style.figure_title_font_size_pt;
figure_title.FontName = char(style.font_name);

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, display_scale * axial_amplitude);
formatSpatialAxis(axis_handle);
clim(axis_handle, [0, display_scale * shared_maximum]);
colormap(axis_handle, parula);
colorbar(axis_handle);
title(axis_handle, sprintf('Axial amplitude, |%s_z| (%s)', ...
    symbol, display_units));

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, display_scale * lateral_amplitude);
formatSpatialAxis(axis_handle);
clim(axis_handle, [0, display_scale * shared_maximum]);
colormap(axis_handle, parula);
colorbar(axis_handle);
title(axis_handle, sprintf('Lateral amplitude, |%s_x| (%s)', ...
    symbol, display_units));

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, min(max(lateral_to_axial_db, -80), 20));
formatSpatialAxis(axis_handle);
clim(axis_handle, [-80, 20]);
colormap(axis_handle, turbo);
colorbar(axis_handle);
title(axis_handle, {'Local lateral/axial amplitude ratio', ...
    sprintf('20 log_{10}(|%s_x|/|%s_z|) (dB)', symbol, symbol)});

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, angle(axial));
formatSpatialAxis(axis_handle);
clim(axis_handle, [-pi, pi]);
colormap(axis_handle, hsv);
colorbar(axis_handle);
title(axis_handle, sprintf('Axial phase, \\angle %s_z (rad)', symbol));

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, angle(lateral));
formatSpatialAxis(axis_handle);
clim(axis_handle, [-pi, pi]);
colormap(axis_handle, hsv);
colorbar(axis_handle);
title(axis_handle, sprintf('Lateral phase, \\angle %s_x (rad)', symbol));

axis_handle = nexttile(layout);
[~, source_row] = min(abs(result.axes.z_m - result.source.center_m_xz(2)));
plot(axis_handle, x_mm, display_scale * axial_amplitude(source_row, :), ...
    '-', 'LineWidth', style.data_line_width_pt, ...
    'DisplayName', sprintf('|%s_z|', symbol));
hold(axis_handle, 'on');
plot(axis_handle, x_mm, display_scale * lateral_amplitude(source_row, :), ...
    '--', 'LineWidth', style.data_line_width_pt, ...
    'DisplayName', sprintf('|%s_x|', symbol));
hold(axis_handle, 'off');
grid(axis_handle, 'on');
legend(axis_handle, 'Location', 'best');
xlabel(axis_handle, 'Lateral position, x (mm)');
ylabel(axis_handle, sprintf('Amplitude (%s)', display_units));
title(axis_handle, sprintf('Profiles at source depth, z = %.2f mm', ...
    1e3*result.axes.z_m(source_row)));

kwsim.viz.applyFigureStyle(figure_handle, style);
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

function fields = resolveFields(result, quantity)
%RESOLVEFIELDS Support current results and previously saved legacy files.
switch quantity
    case "velocity"
        fields = result.fields.velocity;
        if ~isfield(fields, 'lateral_total_zx')
            fields.lateral_total_zx = fields.lateral_shear_zx + ...
                fields.lateral_compression_zx;
        end
    case "displacement"
        fields = result.fields.displacement;
        if ~isfield(fields, 'lateral_total_zx')
            angular_frequency = 2*pi*result.axes.f0_hz;
            velocity = result.fields.velocity;
            fields.lateral_shear_zx = ...
                velocity.lateral_shear_zx / (1i*angular_frequency);
            fields.lateral_compression_zx = ...
                velocity.lateral_compression_zx / (1i*angular_frequency);
            fields.lateral_total_zx = fields.lateral_shear_zx + ...
                fields.lateral_compression_zx;
        end
    otherwise
        error('kwsim:InvalidPlotQuantity', ...
            'Quantity must be "displacement" or "velocity".');
end
end

function formatSpatialAxis(axis_handle)
%FORMATSPATIALAXIS Apply the public x-lateral/z-axial convention.
axis(axis_handle, 'image');
axis_handle.YDir = 'reverse';
xlabel(axis_handle, 'Lateral position, x (mm)');
ylabel(axis_handle, 'Axial position, z (mm)');
end
