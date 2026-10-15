function request = validateRequest(request)
%VALIDATEREQUEST Validate and normalize position placement instructions.
% This API places physical emitters; direction of force/wave is unrelated.
arguments
    request (1,1) struct
end
for key=["geometry","count"]
    if ~isfield(request,key)
        error("swsynth:SourcePositionMissingField","Missing %s.",key);
    end
end
request.geometry=string(request.geometry);
if ~isscalar(request.geometry) || ...
        ~ismember(request.geometry,["planar2d","projected3d","volumetric3d"])
    error("swsynth:InvalidSourceGeometry","Unsupported source geometry.");
end
n=double(request.count);
if ~isscalar(n) || ~isfinite(n) || n<1 || n~=floor(n)
    error("swsynth:InvalidSourceCount","count must be a positive integer.");
end
request.count=n;
if ~isfield(request,"method") || isempty(request.method)
    if isfield(request,"position_xyz_m") && ~isempty(request.position_xyz_m)
        request.method="explicit";
    else
        error("swsynth:SourcePositionMissingField", ...
            "Specify method: fibonacci, random, or explicit.");
    end
end
request.method=string(request.method);
if ~isscalar(request.method) || ...
        ~ismember(request.method,["fibonacci","random","explicit"])
    error("swsynth:InvalidSourcePositionMethod","Invalid position method.");
end
if ~isfield(request,"observation_y_m")
    request.observation_y_m=0;
end
y=double(request.observation_y_m);
if ~isscalar(y) || ~isfinite(y)
    error("swsynth:InvalidObservationY","observation_y_m must be finite.");
end
request.observation_y_m=y;
if isfield(request,"stream") && ~isempty(request.stream) && ...
        ~isa(request.stream,"RandStream")
    error("swsynth:InvalidPositionStream","stream must be a RandStream.");
end

if request.method=="explicit"
    if ~isfield(request,"position_xyz_m") || isempty(request.position_xyz_m)
        error("swsynth:SourcePositionMissingField", ...
            "Explicit method requires position_xyz_m.");
    end
    request.position_xyz_m=swsynth.sources.positions.validate( ...
        double(request.position_xyz_m),request.geometry,n,y);
    return;
end
if isfield(request,"position_xyz_m") && ~isempty(request.position_xyz_m)
    error("swsynth:AmbiguousSourcePositions", ...
        "position_xyz_m is only allowed when method is explicit.");
end
for key=["center_xyz_m","radius_range_m"]
    if ~isfield(request,key)
        error("swsynth:SourcePositionMissingField","Missing %s.",key);
    end
end
c=double(request.center_xyz_m(:).');
r=double(request.radius_range_m(:).');
if numel(c)~=3 || any(~isfinite(c))
    error("swsynth:InvalidSourceCenter","center_xyz_m must be finite XYZ.");
end
if numel(r)~=2 || any(~isfinite(r)) || r(1)<=0 || r(2)<r(1)
    error("swsynth:InvalidSourceRadius", ...
        "radius_range_m must be positive ordered [r_min,r_max].");
end
if request.geometry=="planar2d" && abs(c(2)-y)>1e-10
    error("swsynth:PlanarSourceOutsidePlane", ...
        "center_xyz_m must lie in the planar observation plane.");
end
request.center_xyz_m=c;
request.radius_range_m=r;

if ~isfield(request,"support") || isempty(request.support)
    if request.geometry=="planar2d"
        request.support=struct("type","full_circle");
    else
        request.support=struct("type","full_sphere");
    end
end
support=request.support;
if ~isstruct(support) || ~isscalar(support) || ~isfield(support,"type")
    error("swsynth:InvalidPositionSupport","support.type is required.");
end
support.type=string(support.type);
if request.geometry=="planar2d"
    allowed=["full_circle","cone"];
else
    allowed=["full_sphere","cone"];
end
if ~isscalar(support.type) || ~ismember(support.type,allowed)
    error("swsynth:InvalidPositionSupport", ...
        "Invalid angular support for the selected geometry.");
end
if support.type=="cone"
    if ~isfield(support,"axis_xyz") || ~isfield(support,"half_angle_deg")
        error("swsynth:InvalidPositionSupport", ...
            "Cone support requires axis_xyz and half_angle_deg.");
    end
    axis=double(support.axis_xyz(:).');
    halfAngle=double(support.half_angle_deg);
    if numel(axis)~=3 || any(~isfinite(axis)) || norm(axis)==0 || ...
            ~isscalar(halfAngle) || ~isfinite(halfAngle) || ...
            halfAngle<0 || halfAngle>180
        error("swsynth:InvalidPositionSupport","Invalid cone axis/half-angle.");
    end
    if request.geometry=="planar2d"
        axis(2)=0;
        if norm(axis)==0
            error("swsynth:InvalidPositionSupport", ...
                "Planar cone requires a nonzero x-z axis projection.");
        end
    end
    support.axis_xyz=axis/norm(axis);
    support.half_angle_deg=halfAngle;
end
request.support=support;
end
