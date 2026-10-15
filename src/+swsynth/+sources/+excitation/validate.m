function out = validate(request)
%VALIDATE Source-level force orientation, amplitude and initial phase.
% For planar2d, force is in the x-z plane; projected3d/volumetric3d use XYZ.
% Accept either force_direction_xz or force_direction_xyz for planar2d.
arguments
    request (1,1) struct
end
required=["count","relative_amplitude","phase_rad"];
for name=required
    if ~isfield(request,name)
        error("swsynth:ExcitationMissingField", ...
            "Missing excitation field %s.",name);
    end
end
n=double(request.count);
if ~isscalar(n)||~isfinite(n)||n<1||n~=floor(n)
    error("swsynth:InvalidExcitationCount","count must be a positive integer.");
end
geometry="";
if isfield(request,"geometry")
    geometry=string(request.geometry);
    if ~isscalar(geometry)
        error("swsynth:InvalidExcitationGeometry", ...
            "geometry must be a scalar string.");
    end
    if geometry=="2d"; geometry="planar2d"; end
    if ~ismember(geometry,["planar2d","projected3d","volumetric3d"])
        error("swsynth:InvalidExcitationGeometry", ...
            "Unsupported excitation geometry %s.",geometry);
    end
end
hasXZ=isfield(request,"force_direction_xz") && ...
    ~isempty(request.force_direction_xz);
hasXYZ=isfield(request,"force_direction_xyz") && ...
    ~isempty(request.force_direction_xyz);
if hasXZ && hasXYZ
    error("swsynth:AmbiguousForceDirection", ...
        "Specify only force_direction_xz or force_direction_xyz.");
end
if hasXZ
    if geometry~="planar2d"
        error("swsynth:ForceXZRequires2D", ...
            "force_direction_xz requires geometry=2d or planar2d.");
    end
    xz=double(request.force_direction_xz);
    if ~isequal(size(xz),[n 2]) || any(~isfinite(xz(:)))
        error("swsynth:InvalidExcitationDirections", ...
            "force_direction_xz must contain N finite 2-vectors.");
    end
    f=[xz(:,1),zeros(n,1),xz(:,2)];
elseif hasXYZ
    f=double(request.force_direction_xyz);
else
    error("swsynth:ExcitationMissingField", ...
        "Provide force_direction_xyz or, for 2D, force_direction_xz.");
end
if ~isequal(size(f),[n 3]) || any(~isfinite(f(:))) || ...
        any(vecnorm(f,2,2)<=0)
    error("swsynth:InvalidExcitationDirections", ...
        "Force directions must be finite nonzero vectors for all N sources.");
end
if geometry=="planar2d" && any(abs(f(:,2))>1e-12)
    error("swsynth:PlanarForceOutsidePlane", ...
        "Planar 2D excitation only permits forces in the x-z plane. " + ...
        "Use projected3d for 3D force orientation.");
end
a=double(request.relative_amplitude(:));
p=double(request.phase_rad(:));
if numel(a)~=n || any(~isfinite(a)) || any(a<0)
    error("swsynth:InvalidExcitationAmplitude", ...
        "relative_amplitude must contain N nonnegative finite values.");
end
if numel(p)~=n || any(~isfinite(p))
    error("swsynth:InvalidExcitationPhase", ...
        "phase_rad must contain N finite values.");
end
out=struct("count",n,"force_direction_xyz",f./vecnorm(f,2,2), ...
    "relative_amplitude",a,"phase_rad",p);
end
