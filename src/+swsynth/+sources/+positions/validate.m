function positions = validate(positions, geometry, count, observationY)
%VALIDATE Validate physical source coordinates for a spatial geometry.
arguments
    positions (:,3) double
    geometry (1,1) string
    count (1,1) double {mustBeInteger,mustBeNonnegative}
    observationY (1,1) double = 0
end
if ~isequal(size(positions),[count,3]) || any(~isfinite(positions(:)))
    error("swsynth:InvalidSourcePositions", ...
        "Source positions must be a finite count-by-3 array.");
end
if geometry=="planar2d" && any(abs(positions(:,2)-observationY)>1e-10)
    error("swsynth:PlanarSourceOutsidePlane", ...
        "Planar 2D source positions must lie on observation_y_m.");
end
if ~ismember(geometry,["planar2d","projected3d","volumetric3d"])
    error("swsynth:InvalidSourceGeometry","Unsupported source geometry %s.",geometry);
end
end
