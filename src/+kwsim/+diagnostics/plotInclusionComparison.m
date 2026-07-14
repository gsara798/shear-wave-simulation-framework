function [figure_handle, output_file] = plotInclusionComparison(contrast, reference, output_file, options)
%PLOTINCLUSIONCOMPARISON Plot truth and axial-field effects of an inclusion.
%
% The figure combines full-domain material maps with ROI displacement maps.
% The inclusion boundary is overlaid on all field panels. Amplitude and
% phase use total axial displacement U_z, matching the public ultrasound
% elastography measurement contract.

arguments
    contrast struct
    reference struct
    output_file {mustBeTextScalar} = ""
    options.Visible (1,1) logical = true
    options.CloseAfterExport (1,1) logical = false
end

style = kwsim.common.figureTemplate();
full_x_mm = contrast.config_resolved.derived.x_full_m * 1e3;
full_z_mm = contrast.config_resolved.derived.z_full_m * 1e3;
x_mm = contrast.axes.x_m * 1e3;
z_mm = contrast.axes.z_m * 1e3;
material_roi = contrast.truth.material_id_zx( ...
    contrast.sensor.z_indices, contrast.sensor.x_indices);
inclusion_roi = material_roi > 1;

field = contrast.fields.displacement.axial_total_zx;
reference_field = reference.fields.displacement.axial_total_zx;
difference = field - reference_field;
reference_maximum = max(abs(reference_field), [], 'all');
relative_difference_db = 20*log10((abs(difference) + eps) ./ ...
    max(reference_maximum, eps));

visibility = char(matlab.lang.OnOffSwitchState(options.Visible));
figure_handle = figure('Visible', visibility, 'Color', style.background_color, ...
    'Position', [40, 80, 1800, 900]);
layout = tiledlayout(figure_handle, 2, 4, ...
    'TileSpacing', 'compact', 'Padding', 'compact');
figure_title = title(layout, sprintf([ ...
    'Circular-inclusion benchmark at f_0 = %.1f Hz ', ...
    '(background c_s = %.1f m s^{-1})'], ...
    contrast.axes.f0_hz, contrast.config_resolved.medium.cs_m_s));
figure_title.FontName = char(style.font_name);
figure_title.FontSize = style.figure_title_font_size_pt;

axis_handle = nexttile(layout);
imagesc(axis_handle, full_x_mm, full_z_mm, contrast.truth.cs_m_s_zx);
formatSpatialAxis(axis_handle); colormap(axis_handle, parula); colorbar(axis_handle);
title(axis_handle, 'Shear-wave speed, c_s (m s^{-1})');

axis_handle = nexttile(layout);
imagesc(axis_handle, full_x_mm, full_z_mm, contrast.truth.rho_kg_m3_zx);
formatSpatialAxis(axis_handle); colormap(axis_handle, parula); colorbar(axis_handle);
title(axis_handle, 'Density, \rho (kg m^{-3})');

axis_handle = nexttile(layout);
imagesc(axis_handle, full_x_mm, full_z_mm, contrast.truth.material_id_zx);
formatSpatialAxis(axis_handle);
clim(axis_handle, [0.5, 2.5]);
colormap(axis_handle, [0.20, 0.45, 0.70; 0.65, 0.15, 0.80]);
material_colorbar = colorbar(axis_handle);
material_colorbar.Ticks = [1, 2];
title(axis_handle, 'Material identifier');

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, 1e9*abs(field));
formatSpatialAxis(axis_handle); colormap(axis_handle, parula); colorbar(axis_handle);
overlayBoundary(axis_handle, x_mm, z_mm, inclusion_roi);
title(axis_handle, 'Total axial amplitude, |U_z| (nm)');

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, angle(field));
formatSpatialAxis(axis_handle); clim(axis_handle, [-pi, pi]);
colormap(axis_handle, hsv); colorbar(axis_handle);
overlayBoundary(axis_handle, x_mm, z_mm, inclusion_roi);
title(axis_handle, 'Total axial phase, \angle U_z (rad)');

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, 1e9*abs(difference));
formatSpatialAxis(axis_handle); colormap(axis_handle, parula); colorbar(axis_handle);
overlayBoundary(axis_handle, x_mm, z_mm, inclusion_roi);
title(axis_handle, 'Complex-field difference, |U_z-U_{z,ref}| (nm)');

axis_handle = nexttile(layout);
imagesc(axis_handle, x_mm, z_mm, max(relative_difference_db, -80));
formatSpatialAxis(axis_handle); clim(axis_handle, [-80, 0]);
colormap(axis_handle, turbo); colorbar(axis_handle);
overlayBoundary(axis_handle, x_mm, z_mm, inclusion_roi);
title(axis_handle, {'Difference relative to reference maximum', ...
    '20 log_{10}(|U_z-U_{z,ref}|/max|U_{z,ref}|) (dB)'});

axis_handle = nexttile(layout);
[~, source_row] = min(abs(contrast.axes.z_m - contrast.source.center_m_xz(2)));
plot(axis_handle, x_mm, 1e9*abs(field(source_row, :)), '-', ...
    'LineWidth', style.data_line_width_pt, 'DisplayName', 'Inclusion');
hold(axis_handle, 'on');
plot(axis_handle, x_mm, 1e9*abs(reference_field(source_row, :)), '--', ...
    'LineWidth', style.data_line_width_pt, 'DisplayName', 'Homogeneous reference');
hold(axis_handle, 'off'); grid(axis_handle, 'on');
xlabel(axis_handle, 'Lateral position, x (mm)');
ylabel(axis_handle, 'Axial amplitude (nm)');
legend(axis_handle, 'Location', 'best');
title(axis_handle, sprintf('Profiles at source depth, z = %.2f mm', ...
    contrast.axes.z_m(source_row)*1e3));

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

function overlayBoundary(axis_handle, x_mm, z_mm, mask)
hold(axis_handle, 'on');
contour(axis_handle, x_mm, z_mm, double(mask), [0.5, 0.5], ...
    'w-', 'LineWidth', 1.2);
hold(axis_handle, 'off');
end

function formatSpatialAxis(axis_handle)
axis(axis_handle, 'image');
axis_handle.YDir = 'reverse';
xlabel(axis_handle, 'Lateral position, x (mm)');
ylabel(axis_handle, 'Axial position, z (mm)');
end
