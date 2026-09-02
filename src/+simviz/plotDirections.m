function fig = plotDirections(sample, options)
%PLOTDIRECTIONS Plot effective propagation-direction geometry.
arguments
    sample (1,1) struct
    options.Title (1,1) string = "Propagation directions"
    options.Visible (1,1) string = "off"
end
if ~isfield(sample,"directions") || ~isfield(sample.directions,"xyz")
    error("simviz:DirectionsUnavailable","sample.directions.xyz is required.");
end
D = double(sample.directions.xyz);
if size(D,2) ~= 3 || isempty(D)
    error("simviz:InvalidDirections","directions.xyz must be N-by-3.");
end
inPlane = abs(D(:,2)) <= 1e-10;
theme = simviz.paperTheme();
fig = figure("Visible",char(options.Visible),"Color","w","Position",[100 100 850 700]);
if all(inPlane)
    ax=axes(fig); hold(ax,"on");
    t=linspace(0,2*pi,361);
    plot(ax,cos(t),sin(t),"Color",theme.rgb.gray.light,"LineWidth",1);
    quiver(ax,zeros(size(D,1),1),zeros(size(D,1),1),D(:,1),D(:,3),0, ...
        "Color",theme.rgb.blue.main,"LineWidth",1.2,"MaxHeadSize",0.35);
    scatter(ax,D(:,1),D(:,3),28,theme.rgb.blue.main,"filled");
    axis(ax,"equal"); xlim(ax,[-1.1 1.1]); ylim(ax,[-1.1 1.1]);
    xlabel(ax,"u_x"); ylabel(ax,"u_z"); title(ax,options.Title + " | x-z plane");
    grid(ax,"on"); hold(ax,"off");
else
    ax=axes(fig); hold(ax,"on");
    [xs,ys,zs]=sphere(32);
    surf(ax,xs,ys,zs,"FaceColor",theme.fills.gray.light,"FaceAlpha",0.18, ...
        "EdgeColor",theme.rgb.gray.light,"EdgeAlpha",0.18);
    if any(inPlane)
        scatter3(ax,D(inPlane,1),D(inPlane,2),D(inPlane,3),36,theme.rgb.blue.main,"filled");
    end
    if any(~inPlane)
        scatter3(ax,D(~inPlane,1),D(~inPlane,2),D(~inPlane,3),30,theme.rgb.red.main,"filled");
    end
    quiver3(ax,zeros(size(D,1),1),zeros(size(D,1),1),zeros(size(D,1),1), ...
        D(:,1),D(:,2),D(:,3),0,"Color",theme.rgb.gray.dark,"LineWidth",0.8,"MaxHeadSize",0.25);
    axis(ax,"equal"); xlim(ax,[-1.1 1.1]); ylim(ax,[-1.1 1.1]); zlim(ax,[-1.1 1.1]);
    xlabel(ax,"u_x"); ylabel(ax,"u_y"); zlabel(ax,"u_z");
    title(ax,sprintf("%s | N=%d, in-plane=%d",options.Title,size(D,1),nnz(inPlane)));
    grid(ax,"on"); view(ax,35,25); hold(ax,"off");
end
simviz.applyFigureStyle(fig,theme);
end
