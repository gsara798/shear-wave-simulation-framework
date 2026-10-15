function sources = prepareLegacy(cfg, directions)
%PREPARELEGACY Place parent sources and coherent aperture elements.
% The RNG stream must already be positioned by the calling pipeline.
% Intentionally consumes one rand(1,N,'single') draw even when explicit
% positions override sampled positions, matching legacy planar synthesis.
% Does not generate directions, excitation, phase, polarization or fields.
arguments
    cfg (1,1) struct
    directions (1,1) struct
end
[cfg,~] = swsynth.validateConfig(cfg);
N=cfg.directions.count;
required=["ux","uy","uz"];
for field=required
    if ~isfield(directions,field) || numel(directions.(field))~=N
        error("swsynth:InvalidDirectionsForSources", ...
            "directions.%s must have N entries.",field);
    end
end
ux=single(directions.ux(:).');
uy=single(directions.uy(:).');
uz=single(directions.uz(:).');
radiusRange=single(cfg.sources.radius_range_m);
rho=rand(1,N,"single");
if cfg.directions.space=="two_dimensional"
    radius=sqrt((radiusRange(2)^2-radiusRange(1)^2).*rho+radiusRange(1)^2);
else
    radius=((radiusRange(2)^3-radiusRange(1)^3).*rho+radiusRange(1)^3).^(1/3);
end
x=radius.*ux+single(cfg.domain.Lx_m/2);
y=radius.*uy+single(cfg.domain.observation_y_m);
z=radius.*uz+single(cfg.domain.Lz_m/2);
if ~isempty(cfg.sources.position_xyz_m)
    positions=single(cfg.sources.position_xyz_m);
    if size(positions,1)~=N || size(positions,2)~=3
        error("swsynth:InvalidSourcePositions", ...
            "Explicit positions must contain N rows and three columns.");
    end
    x=positions(:,1).'; y=positions(:,2).'; z=positions(:,3).';
end
parentXYZ=double([x(:),y(:),z(:)]);
aperture=swsynth.sources.buildCoherentAperture( ...
    parentXYZ(1,:),cfg.sources.aperture);
if cfg.sources.aperture.model=="line_segment"
    offsets=aperture.node_offsets_m(:).*aperture.axis_xyz;
    elementXYZ=reshape(parentXYZ,N,1,3)+reshape(offsets,1,[],3);
else
    elementXYZ=zeros(0,0,3);
end
sources=struct();
sources.parent_xyz_m=parentXYZ;
sources.sampled_radius_m=double(radius(:));
sources.aperture=aperture;
sources.element_xyz_m=elementXYZ;
sources.count=N;
end
