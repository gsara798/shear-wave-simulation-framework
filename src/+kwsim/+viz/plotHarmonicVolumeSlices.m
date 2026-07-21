function handles = plotHarmonicVolumeSlices( ...
    volume_zyx, x_m, y_m, z_m, options)
%PLOTHARMONICVOLUMESLICES Plot central amplitude and phase slices of a 3D field.
%
% Inputs
% ------
% volume_zyx:
%   Complex or real numeric volume with public orientation [Nz,Ny,Nx].
%
% x_m, y_m, z_m:
%   Physical coordinate vectors in meters.
%
% Name-value options
% ------------------
% Title:
%   Figure title.
%
% XIndex, YIndex, ZIndex:
%   Slice indices. Empty values select the central voxel.
%
% AmplitudeScale:
%   "linear", "normalized", or "db".
%
% MinimumDb:
%   Lower display limit when AmplitudeScale="db".
%
% FigureVisible:
%   "on" or "off".
%
% Outputs
% -------
% handles:
%   Structure containing the figure, tiled layout, axes, image handles,
%   selected indices, and selected coordinates.
%
% Layout
% ------
% Row 1: amplitude
%   x-z at fixed y
%   x-y at fixed z
%   y-z at fixed x
%
% Row 2: phase
%   x-z at fixed y
%   x-y at fixed z
%   y-z at fixed x

arguments
    volume_zyx {mustBeNumeric}
    x_m {mustBeNumeric, mustBeVector}
    y_m {mustBeNumeric, mustBeVector}
    z_m {mustBeNumeric, mustBeVector}
    options.Title (1,1) string = "Harmonic volume"
    options.XIndex = []
    options.YIndex = []
    options.ZIndex = []
    options.AmplitudeScale (1,1) string = "linear"
    options.MinimumDb (1,1) double {mustBeFinite} = -40
    options.FigureVisible (1,1) string = "on"
end

if ndims(volume_zyx) ~= 3
    error("kwsim:InvalidHarmonicVolume", ...
        "volume_zyx must have shape [Nz,Ny,Nx].");
end

x_m = double(x_m(:).');
y_m = double(y_m(:).');
z_m = double(z_m(:).');

expected_size = [
    numel(z_m), ...
    numel(y_m), ...
    numel(x_m)
];

if ~isequal(size(volume_zyx), expected_size)
    error("kwsim:InvalidHarmonicVolume", ...
        "volume_zyx has size [%s], but axes imply [%s].", ...
        num2str(size(volume_zyx)), ...
        num2str(expected_size));
end

if any(~isfinite(x_m)) || any(~isfinite(y_m)) || ...
        any(~isfinite(z_m))
    error("kwsim:InvalidHarmonicAxes", ...
        "Coordinate vectors must contain finite values.");
end

if any(diff(x_m) <= 0) || any(diff(y_m) <= 0) || ...
        any(diff(z_m) <= 0)
    error("kwsim:InvalidHarmonicAxes", ...
        "Coordinate vectors must be strictly increasing.");
end

if any(~isfinite(volume_zyx), "all")
    error("kwsim:InvalidHarmonicVolume", ...
        "volume_zyx contains NaN or Inf.");
end

amplitude_scale = lower(options.AmplitudeScale);

valid_scales = [
    "linear"
    "normalized"
    "db"
];

if ~any(amplitude_scale == valid_scales)
    error("kwsim:InvalidAmplitudeScale", ...
        "AmplitudeScale must be linear, normalized, or db.");
end

figure_visible = lower(options.FigureVisible);

if ~any(figure_visible == ["on", "off"])
    error("kwsim:InvalidFigureVisibility", ...
        "FigureVisible must be on or off.");
end

nx = numel(x_m);
ny = numel(y_m);
nz = numel(z_m);

x_index = resolveIndex(options.XIndex, nx, "XIndex");
y_index = resolveIndex(options.YIndex, ny, "YIndex");
z_index = resolveIndex(options.ZIndex, nz, "ZIndex");

amplitude = abs(volume_zyx);
phase = angle(volume_zyx);

[display_amplitude, amplitude_label, amplitude_limits] = ...
    scaleAmplitude(amplitude, amplitude_scale, options.MinimumDb);

% Slices are transposed where necessary so the first displayed coordinate
% is horizontal and the second coordinate is vertical.
amplitude_xz = squeeze(display_amplitude(:, y_index, :));
amplitude_xy = squeeze(display_amplitude(z_index, :, :));
amplitude_yz = squeeze(display_amplitude(:, :, x_index));

phase_xz = squeeze(phase(:, y_index, :));
phase_xy = squeeze(phase(z_index, :, :));
phase_yz = squeeze(phase(:, :, x_index));

figure_handle = figure( ...
    'Visible', char(figure_visible), ...
    'Name', char(options.Title), ...
    'Color', 'w');

layout = tiledlayout(figure_handle, 2, 3, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

title(layout, options.Title, 'Interpreter', 'none');

axes_handles = gobjects(2, 3);
image_handles = gobjects(2, 3);

axes_handles(1,1) = nexttile(layout, 1);
image_handles(1,1) = imagesc( ...
    axes_handles(1,1), ...
    x_m * 1e3, ...
    z_m * 1e3, ...
    amplitude_xz);
formatAmplitudeAxes( ...
    axes_handles(1,1), ...
    "x (mm)", "z (mm)", ...
    sprintf("Amplitude: x-z at y = %.2f mm", y_m(y_index)*1e3), ...
    amplitude_limits);

axes_handles(1,2) = nexttile(layout, 2);
image_handles(1,2) = imagesc( ...
    axes_handles(1,2), ...
    x_m * 1e3, ...
    y_m * 1e3, ...
    amplitude_xy);
formatAmplitudeAxes( ...
    axes_handles(1,2), ...
    "x (mm)", "y (mm)", ...
    sprintf("Amplitude: x-y at z = %.2f mm", z_m(z_index)*1e3), ...
    amplitude_limits);

axes_handles(1,3) = nexttile(layout, 3);
image_handles(1,3) = imagesc( ...
    axes_handles(1,3), ...
    y_m * 1e3, ...
    z_m * 1e3, ...
    amplitude_yz);
formatAmplitudeAxes( ...
    axes_handles(1,3), ...
    "y (mm)", "z (mm)", ...
    sprintf("Amplitude: y-z at x = %.2f mm", x_m(x_index)*1e3), ...
    amplitude_limits);

axes_handles(2,1) = nexttile(layout, 4);
image_handles(2,1) = imagesc( ...
    axes_handles(2,1), ...
    x_m * 1e3, ...
    z_m * 1e3, ...
    phase_xz);
formatPhaseAxes( ...
    axes_handles(2,1), ...
    "x (mm)", "z (mm)", ...
    sprintf("Phase: x-z at y = %.2f mm", y_m(y_index)*1e3));

axes_handles(2,2) = nexttile(layout, 5);
image_handles(2,2) = imagesc( ...
    axes_handles(2,2), ...
    x_m * 1e3, ...
    y_m * 1e3, ...
    phase_xy);
formatPhaseAxes( ...
    axes_handles(2,2), ...
    "x (mm)", "y (mm)", ...
    sprintf("Phase: x-y at z = %.2f mm", z_m(z_index)*1e3));

axes_handles(2,3) = nexttile(layout, 6);
image_handles(2,3) = imagesc( ...
    axes_handles(2,3), ...
    y_m * 1e3, ...
    z_m * 1e3, ...
    phase_yz);
formatPhaseAxes( ...
    axes_handles(2,3), ...
    "y (mm)", "z (mm)", ...
    sprintf("Phase: y-z at x = %.2f mm", x_m(x_index)*1e3));

amplitude_colorbar = colorbar(axes_handles(1,3));
amplitude_colorbar.Label.String = amplitude_label;

phase_colorbar = colorbar(axes_handles(2,3));
phase_colorbar.Label.String = "Phase (rad)";

handles = struct();
handles.figure = figure_handle;
handles.layout = layout;
handles.axes = axes_handles;
handles.images = image_handles;
handles.colorbars = struct( ...
    'amplitude', amplitude_colorbar, ...
    'phase', phase_colorbar);

handles.indices = struct( ...
    'x', x_index, ...
    'y', y_index, ...
    'z', z_index);

handles.coordinates_m = struct( ...
    'x', x_m(x_index), ...
    'y', y_m(y_index), ...
    'z', z_m(z_index));

handles.amplitude_scale = amplitude_scale;

end


function index = resolveIndex(requested_index, dimension_size, option_name)

if isempty(requested_index)
    index = round((dimension_size + 1) / 2);
    return
end

if ~(isnumeric(requested_index) && ...
        isscalar(requested_index) && ...
        isfinite(requested_index) && ...
        requested_index == fix(requested_index) && ...
        requested_index >= 1 && ...
        requested_index <= dimension_size)
    error("kwsim:InvalidSliceIndex", ...
        "%s must be an integer between 1 and %d.", ...
        option_name, dimension_size);
end

index = double(requested_index);

end


function [display_amplitude, label, limits] = ...
    scaleAmplitude(amplitude, scale_name, minimum_db)

maximum_amplitude = max(amplitude, [], "all");

switch scale_name
    case "linear"
        display_amplitude = amplitude;
        label = "Amplitude";
        limits = [];

    case "normalized"
        if maximum_amplitude > 0
            display_amplitude = amplitude / maximum_amplitude;
        else
            display_amplitude = zeros(size(amplitude), "like", amplitude);
        end

        label = "Normalized amplitude";
        limits = [0, 1];

    case "db"
        if minimum_db >= 0
            error("kwsim:InvalidAmplitudeScale", ...
                "MinimumDb must be negative.");
        end

        if maximum_amplitude > 0
            normalized = amplitude / maximum_amplitude;
            floor_linear = 10^(minimum_db / 20);
            display_amplitude = ...
                20*log10(max(normalized, floor_linear));
        else
            display_amplitude = ...
                minimum_db * ones(size(amplitude), "like", amplitude);
        end

        label = "Amplitude (dB)";
        limits = [minimum_db, 0];
end

end


function formatAmplitudeAxes( ...
    axes_handle, x_label, y_label, plot_title, limits)

axis(axes_handle, "image");
axis(axes_handle, "xy");

xlabel(axes_handle, x_label);
ylabel(axes_handle, y_label);
title(axes_handle, plot_title, 'Interpreter', 'none');

if ~isempty(limits)
    clim(axes_handle, limits);
end

end


function formatPhaseAxes( ...
    axes_handle, x_label, y_label, plot_title)

axis(axes_handle, "image");
axis(axes_handle, "xy");

xlabel(axes_handle, x_label);
ylabel(axes_handle, y_label);
title(axes_handle, plot_title, 'Interpreter', 'none');

clim(axes_handle, [-pi, pi]);

end
