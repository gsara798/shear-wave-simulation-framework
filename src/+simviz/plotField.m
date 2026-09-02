function fig = plotField(sample, options)
%PLOTFIELD Plot normalized real wavefield mapped to [0,1].
%
% Signed Re(U) is first normalized to [-1,1] using its maximum absolute
% value, then linearly mapped to [0,1]:
%
%     -1 -> 0
%      0 -> 0.5
%     +1 -> 1

arguments
    sample (1,1) struct
    options.Visible (1,1) string = "off"
end

if double(sample.spatial_dimension) == 3
    fig = simviz.plotVolumetricFieldSlices( ...
        sample, ...
        Visible=options.Visible);
    return
end

if double(sample.spatial_dimension) == 3
    fig = simviz.plotVolumetricFieldSlices( ...
        sample, ...
        Visible=options.Visible);
    return
end

[x_mm, z_mm, U, ~, ~] = ...
    simviz.displayPlane(sample);

raw = real(U);

scale = max( ...
    abs(raw), ...
    [], ...
    "all", ...
    "omitnan");

if isfinite(scale) && scale > 0
    normalized_signed = raw ./ scale;
else
    normalized_signed = zeros(size(raw));
end

values = 0.5 * (normalized_signed + 1);

fig = figure( ...
    "Visible", char(options.Visible), ...
    "Color", "w", ...
    "Position", [100, 100, 760, 620]);

ax = axes(fig);

imagesc(ax, x_mm, z_mm, values);
axis(ax, "image");
set(ax, "YDir", "normal");

xlabel(ax, "x [mm]");
ylabel(ax, "z [mm]");

clim(ax, [0, 1]);

cb = colorbar(ax);
cb.Ticks = [0, 0.25, 0.5, 0.75, 1];
ylabel(cb, "Normalized Re(U)");

colormap(ax, simviz.colormapFieldReal(256));

simviz.applyFigureStyle(fig);

end
