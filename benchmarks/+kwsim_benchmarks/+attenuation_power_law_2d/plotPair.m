function [fig, output_file] = plotPair(pair, output_file)
%PLOTPAIR Visualize one matched attenuation measurement at f0.
%
% Panels show requested shear attenuation, the converted Kelvin-Voigt map,
% measured axial amplitude and phase, loss after cancelling the lossless
% reference, and the spatial fit used to recover attenuation.

arguments
    pair struct
    output_file {mustBeTextScalar} = ""
end

style = kwsim.viz.figureTemplate();
result = pair.attenuated;
x_mm = result.axes.x_m*1e3;
z_mm = result.axes.z_m*1e3;
truth_x_mm = result.config_resolved.derived.x_full_m*1e3;
truth_z_mm = result.config_resolved.derived.z_full_m*1e3;
fig = figure('Visible', 'off', 'Color', style.background_color, ...
    'Position', [60, 60, 1500, 900]);
layout = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

ax = nexttile(layout);
requested_alpha = result.truth.attenuation.shear_alpha_at_f0_db_cm_zx;
imagesc(ax, truth_x_mm, truth_z_mm, requested_alpha);
formatSpatial(ax); colorbar(ax); colormap(ax, parula);
setInformativeColorLimits(ax, requested_alpha);
title(ax, {'Target shear attenuation at f_0'; '(dB cm^{-1})'});

ax = nexttile(layout);
kelvin_voigt_coefficient = ...
    result.truth.attenuation.shear_kv_db_mhz2_cm_zx;
imagesc(ax, truth_x_mm, truth_z_mm, kelvin_voigt_coefficient);
formatSpatial(ax); colorbar(ax); colormap(ax, parula);
setInformativeColorLimits(ax, kelvin_voigt_coefficient);
title(ax, {'Kelvin-Voigt shear coefficient'; '[dB (MHz^2 cm)^{-1}]'});

ax = nexttile(layout);
axial_nm = abs(result.fields.displacement.axial_total_zx)*1e9;
imagesc(ax, x_mm, z_mm, axial_nm);
formatSpatial(ax); colorbar(ax); colormap(ax, parula);
title(ax, {'Total axial displacement amplitude'; '|U_z| (nm)'});

ax = nexttile(layout);
imagesc(ax, x_mm, z_mm, angle(result.fields.displacement.axial_total_zx));
formatSpatial(ax); colorbar(ax); colormap(ax, hsv); clim(ax, [-pi, pi]);
title(ax, 'Total axial displacement phase, \angle U_z (rad)');

ax = nexttile(layout);
imagesc(ax, x_mm, z_mm, pair.estimate.loss_db_zx);
formatSpatial(ax); colorbar(ax); colormap(ax, turbo);
title(ax, {'Matched vector-shear amplitude loss'; ...
    'attenuated versus lossless (dB)'});

ax = nexttile(layout);
fit = pair.estimate.vector_shear;
plot(ax, fit.distance_cm, fit.measured_loss_db, '.', ...
    'DisplayName', 'Matched loss'); hold(ax, 'on');
plot(ax, fit.distance_cm, fit.predicted_loss_db, '-', ...
    'LineWidth', style.data_line_width_pt, 'DisplayName', 'Linear fit');
hold(ax, 'off'); grid(ax, 'on'); legend(ax, 'Location', 'best');
xlabel(ax, 'Propagation distance (cm)'); ylabel(ax, 'Amplitude loss (dB)');
title(ax, sprintf('Spatial fit: \\alpha_S = %.4f dB cm^{-1}; R^2 = %.4f', ...
    fit.attenuation_db_cm, fit.r_squared));

heading = title(layout, { ...
    sprintf('Matched attenuation validation at f_0 = %.1f Hz', ...
        pair.frequency_hz); ...
    sprintf(['Target = %.4f dB cm^{-1}; estimated = %.4f dB cm^{-1}; ', ...
        'valid = %d'], pair.target_attenuation_db_cm, ...
        pair.recovered_attenuation_db_cm, pair.valid)});
kwsim.viz.applyFigureStyle(fig, style);
heading.FontName = char(style.font_name);
heading.FontSize = style.figure_title_font_size_pt;

output_file = string(output_file);
if strlength(output_file) > 0
    exportgraphics(fig, output_file, 'Resolution', style.export_resolution_dpi, ...
        'BackgroundColor', style.background_color);
end

end

function formatSpatial(ax)
axis(ax, 'image'); set(ax, 'YDir', 'reverse');
xlabel(ax, 'Lateral position, x (mm)');
ylabel(ax, 'Axial position, z (mm)');
end

function setInformativeColorLimits(ax, data)
% Prevent arbitrary default limits when a material map is spatially uniform.
finite_values = double(data(isfinite(data)));
if isempty(finite_values)
    return;
end
lower_limit = min(finite_values, [], 'all');
upper_limit = max(finite_values, [], 'all');
if upper_limit == lower_limit
    padding = max(0.02*max(abs(lower_limit), 1), eps(lower_limit));
else
    padding = 0.02*(upper_limit - lower_limit);
end
clim(ax, [lower_limit - padding, upper_limit + padding]);
end
