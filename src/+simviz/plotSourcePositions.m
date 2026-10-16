function fig = plotSourcePositions(sample, options)
%PLOTSOURCEPOSITIONS Physical source centers, force vectors and observation FOV.
% Point-source coordinates are physical XYZ positions in meters, not plane
% wave propagation directions. Optional aperture nodes are shown faintly.
arguments
    sample (1,1) struct
    options.Visible (1,1) string = "off"
end
if ~isfield(sample,"sources") || ~isstruct(sample.sources) || ...
        ~isfield(sample.sources,"sources")
    error("simviz:SourcesUnavailable","Physical sources are missing.");
end
sources=sample.sources.sources;
xyz=double(sources.position_xyz_m);
force=double(sources.force_direction_xyz);
if size(xyz,2)~=3 || isempty(xyz) || ~isequal(size(force),size(xyz))
    error("simviz:InvalidSourceGeometry","Source positions and forces must be N-by-3.");
end
x=double(sample.coordinates.x_m(:))*1e3;
z=double(sample.coordinates.z_m(:))*1e3;
xyz=xyz*1e3;
range=max([rangeLocal(x),rangeLocal(z),1]);
arrowLen=0.13*range;
theme=simviz.paperTheme();
fig=figure("Visible",char(options.Visible),"Color","w", ...
    "Position",[100 100 1180 540]);
tl=tiledlayout(fig,1,2,"TileSpacing","compact");

ax=nexttile(tl);
hold(ax,"on");
rectangle(ax,"Position",[min(x),min(z),max(x)-min(x),max(z)-min(z)], ...
    "EdgeColor",theme.rgb.blue.main,"LineWidth",theme.style.line_width,"LineStyle","--");
scatter(ax,xyz(:,1),xyz(:,3),60,"filled","MarkerFaceColor",theme.rgb.orange.main);
quiver(ax,xyz(:,1),xyz(:,3),arrowLen*force(:,1),arrowLen*force(:,3),0, ...
    "Color",theme.rgb.gray.dark,"LineWidth",theme.style.line_width);
axis(ax,"equal");grid(ax,"on");xlabel(ax,"x [mm]");ylabel(ax,"z [mm]");
title(ax,"Source positions and force projection (x-z)");
hold(ax,"off");

ax=nexttile(tl);
hold(ax,"on");
scatter3(ax,xyz(:,1),xyz(:,2),xyz(:,3),55,"filled", ...
    "MarkerFaceColor",theme.rgb.orange.main);
quiver3(ax,xyz(:,1),xyz(:,2),xyz(:,3), ...
    arrowLen*force(:,1),arrowLen*force(:,2),arrowLen*force(:,3),0, ...
    "Color",theme.rgb.gray.dark,"LineWidth",theme.style.line_width);
% Outline observed x-z field at its y coordinate.
yObs=0;
if isfield(sample.coordinates,"observation_y_m")
    yObs=double(sample.coordinates.observation_y_m)*1e3;
elseif isfield(sample.coordinates,"y_m") && ~isempty(sample.coordinates.y_m) ...
        && double(sample.spatial_dimension)==3
    yy=double(sample.coordinates.y_m(:))*1e3;
    yObs=yy(round((numel(yy)+1)/2));
end
xx=[min(x),max(x),max(x),min(x),min(x)];
zz=[min(z),min(z),max(z),max(z),min(z)];
plot3(ax,xx,yObs+zeros(size(xx)),zz,"--","LineWidth",theme.style.line_width, ...
    "Color",theme.rgb.blue.main);
if isfield(sample.sources,"aperture") && ...
        isfield(sample.sources.aperture,"node_xyz_m")
    nodes=double(sample.sources.aperture.node_xyz_m)*1e3;
    if size(nodes,2)==3 && size(nodes,1)>size(xyz,1)
        scatter3(ax,nodes(:,1),nodes(:,2),nodes(:,3),15, ...
            "MarkerEdgeColor",theme.rgb.teal.main);
    end
end
axis(ax,"equal");grid(ax,"on");view(ax,35,25);
xlabel(ax,"x [mm]");ylabel(ax,"y [mm]");zlabel(ax,"z [mm]");
title(ax,"Physical 3D source geometry");
hold(ax,"off");
title(tl,"Sources | applied forces | observed x-z FOV");
simviz.applyFigureStyle(fig,theme);
end

function r=rangeLocal(v)
r=max(v)-min(v);
end
