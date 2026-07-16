function [fig, output_file] = plotRegimeSuite(validation, output_file)
%PLOTREGIMESUITE Compare source banks, measured fields, and spectra.
%
% Rows show source geometry, measured axial-displacement amplitude, and the
% vector-shear angular spectrum. Columns show directional, partially diffuse,
% and diffuse regimes. Spatial axes are in mm; displacement is in nm.

arguments
    validation struct
    output_file {mustBeTextScalar} = ""
end

style = kwsim.viz.figureTemplate();
names = ["directional", "partially_diffuse", "diffuse"];
display_names = ["Directional", "Partially diffuse", "Diffuse"];
fig = figure('Visible', 'off', 'Color', style.background_color, ...
    'Position', [50, 50, 1500, 1250]);
layout = tiledlayout(fig, 3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

maximum_amplitude_nm = 0;
for name = names
    field_nm = abs(validation.results.(name).fields.displacement.axial_total_zx)*1e9;
    maximum_amplitude_nm = max(maximum_amplitude_nm, max(field_nm, [], 'all'));
end

for index = 1:3
    name = names(index);
    result = validation.results.(name);
    angular = validation.reports.(name).metrics.angular;

    nexttile(layout, index);
    imagesc(result.config_resolved.derived.x_full_m*1e3, ...
        result.config_resolved.derived.z_full_m*1e3, result.source.mask_zx);
    axis image; set(gca, 'YDir', 'reverse'); hold on;
    vibrators = result.source.vibrators;
    centers_mm = 1e3*vertcat(vibrators.center_m_xz);
    polarizations = vertcat(vibrators.polarization_xz);
    if lower(string(result.source.contact_model)) == "finite_segment"
        for vibrator = vibrators.'
            [node_x, node_z] = ind2sub( ...
                [result.config_resolved.grid.Nx, result.config_resolved.grid.Nz], ...
                vibrator.contact_node_indices);
            plot((node_x - 1)*result.axes.dx_m*1e3, ...
                (node_z - 1)*result.axes.dz_m*1e3, 'r-', 'LineWidth', 1.2);
        end
    end
    arrow_length_mm = 1.5;
    quiver(centers_mm(:,1), centers_mm(:,2), ...
        arrow_length_mm*polarizations(:,1), ...
        arrow_length_mm*polarizations(:,2), 0, 'r', 'LineWidth', 1.0);
    hold off;
    xlim(1e3*[result.config_resolved.derived.x_full_m(1), ...
        result.config_resolved.derived.x_full_m(end)]);
    ylim(1e3*[result.config_resolved.derived.z_full_m(1), ...
        result.config_resolved.derived.z_full_m(end)]);
    xlabel('Lateral position, x (mm)'); ylabel('Axial position, z (mm)');
    title(sprintf('%s source bank (N = %d)', ...
        display_names(index), result.source.vibrator_count));

    nexttile(layout, 3 + index);
    amplitude_nm = abs(result.fields.displacement.axial_total_zx)*1e9;
    imagesc(result.axes.x_m*1e3, result.axes.z_m*1e3, amplitude_nm);
    axis image; set(gca, 'YDir', 'reverse');
    clim([0, maximum_amplitude_nm]); colorbar;
    xlabel('Lateral position, x (mm)'); ylabel('Axial position, z (mm)');
    title('$|U_{z,\mathrm{total}}|$ (nm)', 'Interpreter', 'latex');

    nexttile(layout, 6 + index);
    plot(angular.bin_centres_deg, angular.bin_energy_normalized, ...
        'LineWidth', 1.4);
    xlim([-180, 180]); ylim([0, max(angular.bin_energy_normalized)*1.10]);
    xticks(-180:45:180); grid on;
    xlabel('Propagation angle, \theta (deg)');
    ylabel('Normalized shear energy');
    title(sprintf('C_{\\pm15^\\circ} = %.3f, H_{\\theta} = %.3f', ...
        angular.target_concentration, angular.entropy_normalized));
end

contact_model = replace(string( ...
    validation.results.directional.source.contact_model), "_", " ");
title(layout, sprintf( ...
    '2D shear-field regimes at f_0 = %.1f Hz | contact: %s | valid = %d', ...
    validation.results.directional.axes.f0_hz, contact_model, validation.valid));
kwsim.viz.applyFigureStyle(fig, style);

output_file = string(output_file);
if strlength(output_file) > 0
    exportgraphics(fig, output_file, 'Resolution', style.export_resolution_dpi, ...
        'BackgroundColor', style.background_color);
end

end
