function positions = generate(request)
%GENERATE Resolve finite-source positions independently of excitation.
% Request: geometry, count, and either position_xyz_m (explicit)
% or center_xyz_m, radius_range_m, direction_xyz and optional stream.
% Random radial sampling is area-uniform in planar2d and volume-uniform
% in projected3d/volumetric3d. No implicit reseeding.
arguments
    request (1,1) struct
end
keys=["geometry","count"];
for key=keys
    if ~isfield(request,key)
        error("swsynth:SourcePositionMissingField","Missing %s.",key);
    end
end
geometry=string(request.geometry); N=double(request.count);
if ~isscalar(N) || ~isfinite(N) || N<1 || N~=floor(N)
    error("swsynth:InvalidSourceCount","count must be a positive integer.");
end
observationY=0;
if isfield(request,"observation_y_m")
    observationY=double(request.observation_y_m);
end
if isfield(request,"position_xyz_m") && ~isempty(request.position_xyz_m)
    positions=double(request.position_xyz_m);
else
    for key=["direction_xyz","radius_range_m","center_xyz_m"]
        if ~isfield(request,key)
            error("swsynth:SourcePositionMissingField","Missing %s.",key);
        end
    end
    directions=double(request.direction_xyz);
    if ~isequal(size(directions),[N,3]) || ...
            any(~isfinite(directions(:))) || any(vecnorm(directions,2,2)<=0)
        error("swsynth:InvalidSourceDirections", ...
            "direction_xyz must contain N finite nonzero 3-vectors.");
    end
    directions=directions./vecnorm(directions,2,2);
    center=double(request.center_xyz_m(:).');
    radiusRange=double(request.radius_range_m(:).');
    if numel(center)~=3 || any(~isfinite(center)) || ...
            numel(radiusRange)~=2 || ...
            any(~isfinite(radiusRange)) || radiusRange(1)<=0 || ...
            radiusRange(2)<radiusRange(1)
        error("swsynth:InvalidSourceRadius", ...
            "Provide finite center_xyz_m and ordered positive radius_range_m.");
    end
    if isfield(request,"stream") && ~isempty(request.stream)
        rho=rand(request.stream,N,1);
    else
        rho=rand(N,1);
    end
    switch geometry
        case "planar2d"
            radius=sqrt((radiusRange(2)^2-radiusRange(1)^2).*rho+radiusRange(1)^2);
        case {"projected3d","volumetric3d"}
            radius=((radiusRange(2)^3-radiusRange(1)^3).*rho+radiusRange(1)^3).^(1/3);
        otherwise
            error("swsynth:InvalidSourceGeometry","Unsupported geometry %s.",geometry);
    end
    positions=center+radius.*directions;
end
positions=swsynth.sources.positions.validate(positions,geometry,N,observationY);
end
