function grid = buildGrid(request)
%BUILDGRID Construct a spatial computational grid, independent of the medium.
%
% request.geometry: 2d/planar2d, projected3d, or volumetric3d.
% Choose exactly ONE spatial specification:
%   (1) explicit x_m, z_m, and for volumetric3d y_m
%   (2) Lx_m, Lz_m, dx_m, dz_m (+ Ly_m, dy_m for volume)
% For length/step mode, match legacy round(L/d)+1 / linspace endpoints.
% observation_y_m sets the x-z slice plane for 2d/projected3d.
% Optional origin_xyz_m shifts length/step grid starting coordinates.
% The returned dx_m etc describe *realized*, not requested, spacing.
arguments
    request (1,1) struct
end
if ~isfield(request,"geometry")
    error("swsynth:DomainMissingGeometry","domain.geometry is required.");
end
geometry=string(request.geometry);
if ~isscalar(geometry)
    error("swsynth:InvalidDomainGeometry","geometry must be a scalar string.");
end
if geometry=="planar2d";geometry="2d";end
if ~ismember(geometry,["2d","projected3d","volumetric3d"])
    error("swsynth:InvalidDomainGeometry","Unsupported geometry %s.",geometry);
end

isVolume=geometry=="volumetric3d";
axisNames=["x","z"];
if isVolume;axisNames=["x","y","z"];end
hasExplicit=isfield(request,"x_m") || isfield(request,"z_m") || ...
    isfield(request,"y_m");
hasLength=isfield(request,"Lx_m") || isfield(request,"Lz_m") || ...
    isfield(request,"Ly_m") || isfield(request,"dx_m") || ...
    isfield(request,"dz_m") || isfield(request,"dy_m");
if hasExplicit==hasLength
    error("swsynth:AmbiguousDomainSpecification", ...
        "Specify either coordinate axes or domain lengths/spacings, not both or neither.");
end
if ~isVolume && (isfield(request,"y_m") || ...
        isfield(request,"Ly_m") || isfield(request,"dy_m"))
    error("swsynth:InvalidDomainGeometry", ...
        "Slice geometries must not define a volumetric y grid.");
end
origin=[0 0 0];
if isfield(request,"origin_xyz_m")
    origin=double(request.origin_xyz_m);
    if ~isequal(size(origin),[1 3]) || ~isreal(origin) || ...
            any(~isfinite(origin))
        error("swsynth:InvalidDomainOrigin", ...
            "origin_xyz_m must be a finite real [x y z] row vector.");
    end
    if hasExplicit
        error("swsynth:AmbiguousDomainSpecification", ...
            "Explicit axes already define the origin; do not also provide origin_xyz_m.");
    end
end

if hasExplicit
    for axisName=axisNames
        field=axisName+"_m";
        if ~isfield(request,field)
            error("swsynth:DomainMissingAxis","Missing domain axis %s.",field);
        end
        grid.(field)=validateAxis(request.(field),field);
    end
else
    for axisName=axisNames
        lengthKey="L"+axisName+"_m";
        stepKey="d"+axisName+"_m";
        if ~isfield(request,lengthKey) || ~isfield(request,stepKey)
            error("swsynth:DomainMissingAxis", ...
                "Missing %s or %s.",lengthKey,stepKey);
        end
        L=double(request.(lengthKey));
        step=double(request.(stepKey));
        if ~isscalar(L) || ~isreal(L) || ~isfinite(L) || L<=0 || ...
                ~isscalar(step) || ~isreal(step) || ...
                ~isfinite(step) || step<=0 || step>L
            error("swsynth:InvalidDomainExtent", ...
                "%s must be positive, with 0 < %s <= %s.", ...
                lengthKey,stepKey,lengthKey);
        end
        axisIndex=find(["x","y","z"]==axisName);
        count=round(L/step)+1;
        grid.(axisName+"_m")=linspace(origin(axisIndex), ...
            origin(axisIndex)+L,count);
        grid.("requested_d"+axisName+"_m")=step;
    end
end

for axisName=axisNames
    axis=grid.(axisName+"_m");
    grid.("n"+axisName)=numel(axis);
    grid.("d"+axisName+"_m")=(axis(end)-axis(1))/(numel(axis)-1);
    grid.("L"+axisName+"_m")=axis(end)-axis(1);
end
grid.geometry=geometry;
grid.x_m=grid.x_m(:).';
grid.z_m=grid.z_m(:).';
if isVolume
    grid.y_m=grid.y_m(:).';
    grid.spatial_size=[grid.nz,grid.ny,grid.nx];
    grid.output_convention="grid(z,y,x)";
else
    y=0;
    if isfield(request,"observation_y_m")
        y=double(request.observation_y_m);
    end
    if ~isscalar(y) || ~isreal(y) || ~isfinite(y)
        error("swsynth:InvalidDomainObservationPlane", ...
            "observation_y_m must be a finite real scalar.");
    end
    grid.observation_y_m=y;
    grid.spatial_size=[grid.nz,grid.nx];
    grid.output_convention="grid(z,x)";
end
end

function axis = validateAxis(value,name)
if ~isnumeric(value) || ~isvector(value) || numel(value)<2 || ...
        ~isreal(value) || any(~isfinite(value(:)))
    error("swsynth:InvalidDomainAxis", ...
        "%s must be a real finite vector with at least two elements.",name);
end
axis=double(value(:).');
delta=diff(axis);
if any(delta<=0)
    error("swsynth:InvalidDomainAxis","%s must increase strictly.",name);
end
realized=(axis(end)-axis(1))/(numel(axis)-1);
if any(abs(delta-realized)>1e-10*max(1,abs(realized)))
    error("swsynth:NonuniformDomainGrid", ...
        "%s must be uniformly spaced for current numerical solvers.",name);
end
end
