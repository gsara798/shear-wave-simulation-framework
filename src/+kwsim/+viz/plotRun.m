function files = plotRun(result, report, output_directory)
%PLOTRUN Save deterministic single-run diagnostic figures as PNG files.
%
% Figures are created invisibly and closed before returning. Axes always use
% millimetres for display, while the underlying MAT result remains in SI.

arguments
    result struct
    report struct
    output_directory {mustBeTextScalar}
end

output_directory = string(output_directory);
style = kwsim.viz.figureTemplate();
if ~isfolder(output_directory)
    mkdir(output_directory);
end

files = struct();
uses_vibrator_bank = ...
    isfield(result.config_resolved.source, 'layout') && ...
    lower(string(result.config_resolved.source.layout)) == "vibrator_bank";

% -------------------------------------------------------------------------
% Source geometry, waveform, and spectrum
% -------------------------------------------------------------------------
fig = figure('Visible', 'off', 'Color', style.background_color, ...
    'Position', [100, 100, 1200, 800]);
layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile(layout);
imagesc(result.config_resolved.derived.x_full_m * 1e3, ...
    result.config_resolved.derived.z_full_m * 1e3, result.source.mask_zx);
axis image; set(gca, 'YDir', 'reverse');
hold on;
if uses_vibrator_bank
    centers_mm = 1e3*vertcat(result.source.vibrators.center_m_xz);
    polarization = vertcat(result.source.vibrators.polarization_xz);
    plot(centers_mm(:,1), centers_mm(:,2), 'wo', 'MarkerFaceColor', 'k', ...
        'MarkerSize', 4);
    quiver(centers_mm(:,1), centers_mm(:,2), polarization(:,1), ...
        polarization(:,2), 1.2, 'w', 'LineWidth', 1.2, 'MaxHeadSize', 1);
else
    center_mm = result.source.center_m_xz * 1e3;
    plot(center_mm(1), center_mm(2), 'wo', 'MarkerFaceColor', 'k', ...
        'MarkerSize', 6);
    arrow_length_mm = max(result.source.contact_radius_m * 1e3, 1);
    quiver(center_mm(1), center_mm(2), ...
        arrow_length_mm * result.source.polarization_xz(1), ...
        arrow_length_mm * result.source.polarization_xz(2), 0, ...
        'w', 'LineWidth', 1.8, 'MaxHeadSize', 1);
end
hold off;
xlabel('Lateral position, x (mm)'); ylabel('Axial position, z (mm)');
if uses_vibrator_bank
    contact_model = lower(string(result.source.contact_model));

    switch contact_model
        case "point"
            contact_description = "point contacts";

        case "finite_segment"
            contact_description = "finite-segment contacts";

        otherwise
            contact_description = replace(contact_model, "_", " ");
    end

    title(sprintf('%s source bank (%d %s)', ...
        sentenceCase(result.source.regime), ...
        result.source.vibrator_count, ...
        contact_description));
else
    title(sprintf('Prescribed axial-velocity contact (%d nodes)', ...
        result.source.contact_node_count));
end
colorbar;

nexttile(layout);
plot(result.source.t_s * 1e3, result.source.waveform_m_s * 1e6, 'LineWidth', 1.2);
xlabel('Time, t (ms)'); ylabel('Axial particle velocity, v_z (\mum s^{-1})');
grid on;
if uses_vibrator_bank
    ylabel('Scalar contact velocity (\mum s^{-1})');
    title('Representative cosine-ramped sinusoidal drive');
else
    title('Cosine-ramped sinusoidal source');
end

nexttile(layout);
semilogy(result.source.diagnostics.frequency_hz, ...
    max(result.source.diagnostics.normalized_spectrum, eps), 'LineWidth', 1.2);
xlim([0, 5*result.source.f0_hz]); ylim([1e-8, 1.1]); grid on;
xlabel('Frequency, f (Hz)'); ylabel('Normalized magnitude (a.u.)');
title('Stationary source spectrum');

nexttile(layout);
axis off;
text(0, 0.95, "Source diagnostics", 'FontWeight', 'bold', 'FontSize', 12);
text(0, 0.78, sprintf('Frequency, f_0: %.3f Hz', result.source.f0_hz));
text(0, 0.64, sprintf('Peak velocity amplitude: %.3f \\mum s^{-1}', ...
    1e6*result.source.velocity_amplitude_m_s));
if uses_vibrator_bank
    text(0, 0.50, sprintf('Coherent/diffuse contacts: %d/%d', ...
        result.source.coherent_count, result.source.diffuse_count));
    text(0, 0.42, sprintf('Prescribed-drive relative error: %.3g', ...
        result.source.drive_power_relative_error));
else
    text(0, 0.50, sprintf('Polarization unit vector [x,z]: [%g,%g]', ...
        result.source.polarization_xz));
end
text(0, 0.36, sprintf('Stationary fundamental fraction: %.8f', ...
    result.source.diagnostics.fundamental_fraction));
if report.valid
    status_text = 'PASS';
else
    status_text = 'FAIL';
end

text(0, 0.22, sprintf('Diagnostic status: %s', status_text));

kwsim.viz.applyFigureStyle(fig, style);

files.source = fullfile(output_directory, "source_diagnostics.png");
exportgraphics(fig, files.source, 'Resolution', style.export_resolution_dpi, ...
    'BackgroundColor', style.background_color);
close(fig);

files.field = fullfile(output_directory, "field_diagnostics.png");
[~, files.field] = kwsim.viz.plotAxialField(result, report, ...
    files.field, 'Quantity', "displacement", 'Visible', false, ...
    'CloseAfterExport', true);

files.components = fullfile(output_directory, "motion_components.png");
[~, files.components] = kwsim.viz.plotMotionComponents(result, report, ...
    files.components, 'Quantity', "displacement", 'Visible', false, ...
    'CloseAfterExport', true);

end

function value = sentenceCase(value)
value = replace(string(value), "_", " ");
characters = char(value);
if ~isempty(characters)
    characters(1) = upper(characters(1));
end
value = string(characters);
end
