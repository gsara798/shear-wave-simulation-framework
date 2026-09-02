function fig = plotVolumetricCrossplanes(sample, quantity, options)
%PLOTVOLUMETRICCROSSPLANES Plot central XY, XZ, YZ cross-planes for 3D data.

arguments
    sample (1,1) struct
    quantity (1,1) string {mustBeMember(quantity,["sws","amplitude","phase","field_real"])} = "amplitude"
    options.Visible (1,1) string = "off"
end

if double(sample.spatial_dimension) ~= 3
    error( ...
        "simviz:NotVolumetric", ...
        "plotVolumetricCrossplanes requires spatial_dimension == 3.");
end

U = double(sample.wavefield.data_zyx);
cs = double(sample.truth.cs_map_zyx);

x_mm = 1e3 * double(sample.coordinates.x_m(:));
y_mm = 1e3 * double(sample.coordinates.y_m(:));
z_mm = 1e3 * double(sample.coordinates.z_m(:));

iz = round((size(U,1) + 1) / 2);
iy = round((size(U,2) + 1) / 2);
ix = round((size(U,3) + 1) / 2);

switch quantity
    case "sws"
        values = cs;
        cmap = simviz.colormapSws(256);
        cbarLabel = "SWS [m/s]";
        climits = [min(values(:)), max(values(:))];
        if climits(1) == climits(2)
            pad = max(abs(climits(1))*0.25, 1);
            climits = climits + [-pad, pad];
        end

    case "amplitude"
        scale = max(abs(U), [], "all");
        if ~(isfinite(scale) && scale > 0)
            scale = 1;
        end
        values = abs(U) ./ scale;
        cmap = simviz.colormapAmplitude(256);
        cbarLabel = "Normalized |U|";
        climits = [0, 1];

    case "phase"
        values = angle(U);
        cmap = simviz.colormapPhase(256);
        cbarLabel = "Phase [rad]";
        climits = [-pi, pi];

    case "field_real"
        raw = real(U);
        scale = max(abs(raw), [], "all");
        if ~(isfinite(scale) && scale > 0)
            scale = 1;
        end
        values = 0.5 * (max(min(raw ./ scale, 1), -1) + 1);
        cmap = simviz.colormapFieldReal(256);
        cbarLabel = "Normalized Re(U)";
        climits = [0, 1];
end

fig = figure( ...
    "Visible", char(options.Visible), ...
    "Color", "w", ...
    "Position", [100, 100, 1050, 850]);

ax = axes(fig);
hold(ax, "on");

% XY plane (z = z0)
[Xxy, Yxy] = meshgrid(x_mm, y_mm);
Zxy = z_mm(iz) * ones(size(Xxy));
Cxy = squeeze(values(iz,:,:));

surface(ax, ...
    Xxy, Yxy, Zxy, Cxy, ...
    "FaceColor", "texturemap", ...
    "EdgeColor", "none");

% XZ plane (y = y0)
[Xxz, Zxz] = meshgrid(x_mm, z_mm);
Yxz = y_mm(iy) * ones(size(Xxz));
Cxz = squeeze(values(:,iy,:));

surface(ax, ...
    Xxz, Yxz, Zxz, Cxz, ...
    "FaceColor", "texturemap", ...
    "EdgeColor", "none");

% YZ plane (x = x0)
[Yyz, Zyz] = meshgrid(y_mm, z_mm);
Xyz = x_mm(ix) * ones(size(Yyz));
Cyz = squeeze(values(:,:,ix));

surface(ax, ...
    Xyz, Yyz, Zyz, Cyz, ...
    "FaceColor", "texturemap", ...
    "EdgeColor", "none");

axis(ax, "equal");
axis(ax, "tight");
grid(ax, "on");

xlabel(ax, "x [mm]");
ylabel(ax, "y [mm]");
zlabel(ax, "z [mm]");

xlim(ax, [min(x_mm), max(x_mm)]);
ylim(ax, [min(y_mm), max(y_mm)]);
zlim(ax, [min(z_mm), max(z_mm)]);

view(ax, 35, 25);
clim(ax, climits);
colormap(ax, cmap);

cb = colorbar(ax);
ylabel(cb, cbarLabel);

if quantity == "phase"
    cb.Ticks = [-pi, -pi/2, 0, pi/2, pi];
    cb.TickLabels = {'-\pi','-\pi/2','0','\pi/2','\pi'};
    cb.TickLabelInterpreter = "tex";
elseif quantity == "amplitude" || quantity == "field_real"
    cb.Ticks = 0:0.2:1;
end

hold(ax, "off");
simviz.applyFigureStyle(fig);

end
