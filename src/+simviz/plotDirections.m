function fig = plotDirections(sample, options)
%PLOTDIRECTIONS Plot effective incident propagation-direction geometry.
%
% Each direction vector D is shown as an inward arrow entering the unit
% circle/sphere from the boundary point -D. This preserves the physical
% propagation sense: the arrow itself points along +D toward the domain.
arguments
    sample (1,1) struct
    options.Visible (1,1) string = "off"
    options.ArrowLength (1,1) double {mustBePositive} = 0.24
end

if ~isfield(sample,"directions") || ~isfield(sample.directions,"xyz")
    error("simviz:DirectionsUnavailable","sample.directions.xyz is required.");
end

D = double(sample.directions.xyz);
if size(D,2) ~= 3 || isempty(D)
    error("simviz:InvalidDirections","directions.xyz must be N-by-3.");
end

norms = vecnorm(D,2,2);
if any(~isfinite(norms)) || any(norms <= eps)
    error("simviz:InvalidDirections","directions.xyz must contain finite nonzero vectors.");
end
D = D ./ norms;

inPlane = abs(D(:,2)) <= 1e-10;
theme = simviz.paperTheme();
fig = figure("Visible",char(options.Visible),"Color","w","Position",[100 100 850 700]);

if all(inPlane)
    ax = axes(fig);
    hold(ax,"on");

    t = linspace(0,2*pi,361);
    plot(ax,cos(t),sin(t),"Color",theme.rgb.gray.main,"LineWidth",1.0);

    % A wave propagating along +D enters from the opposite boundary point -D.
    tailX = -D(:,1);
    tailZ = -D(:,3);
    arrowX = options.ArrowLength * D(:,1);
    arrowZ = options.ArrowLength * D(:,3);

    quiver(ax,tailX,tailZ,arrowX,arrowZ,0, ...
        "Color",theme.rgb.blue.main, ...
        "LineWidth",1.4, ...
        "MaxHeadSize",0.9);

    scatter(ax,tailX,tailZ,30,theme.rgb.blue.main,"filled");

    axis(ax,"equal");
    xlim(ax,[-1.1 1.1]);
    ylim(ax,[-1.1 1.1]);
    xlabel(ax,"u_x");
    ylabel(ax,"u_z");
    grid(ax,"on");
    hold(ax,"off");
else
    ax = axes(fig);
    hold(ax,"on");

    [xs,ys,zs] = sphere(32);
    surf(ax,xs,ys,zs, ...
        "FaceColor","white", ...
        "FaceAlpha",0.05, ...
        "EdgeColor",theme.rgb.gray.main, ...
        "EdgeAlpha",0.16);

    tails = -D;
    arrows = options.ArrowLength * D;

    if any(inPlane)
        scatter3(ax, ...
            tails(inPlane,1),tails(inPlane,2),tails(inPlane,3), ...
            38,theme.rgb.blue.main,"filled");
    end
    if any(~inPlane)
        scatter3(ax, ...
            tails(~inPlane,1),tails(~inPlane,2),tails(~inPlane,3), ...
            32,theme.rgb.red.main,"filled");
    end

    quiver3(ax, ...
        tails(:,1),tails(:,2),tails(:,3), ...
        arrows(:,1),arrows(:,2),arrows(:,3),0, ...
        "Color",theme.rgb.gray.dark, ...
        "LineWidth",1.0, ...
        "MaxHeadSize",0.8);

    axis(ax,"equal");
    xlim(ax,[-1.1 1.1]);
    ylim(ax,[-1.1 1.1]);
    zlim(ax,[-1.1 1.1]);
    xlabel(ax,"u_x");
    ylabel(ax,"u_y");
    zlabel(ax,"u_z");
    grid(ax,"on");
    view(ax,35,25);
    hold(ax,"off");
end

simviz.applyFigureStyle(fig,theme);
end
