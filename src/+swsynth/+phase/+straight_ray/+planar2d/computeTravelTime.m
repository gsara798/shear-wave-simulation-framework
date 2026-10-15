function [travelTimeS,diagnostics] = computeTravelTime(cfg,sourceXYZ,targetXYZ)
%COMPUTETRAVELTIME Planar 2D straight-ray integration.
% The numerical integral is shared with the extruded 2.5D geometry.
% No separate solver is duplicated for a purely in-plane ray.
if any(abs(double(targetXYZ(:,2))-double(sourceXYZ(2)))>1e-12)
    error("swsynth:StraightRay2DRequiresInPlaneCoordinates", ...
        "Planar 2D straight rays require the source and targets to share y.");
end
[travelTimeS,diagnostics] = ...
    swsynth.phase.straight_ray.projected3d.computeTravelTime( ...
        cfg,sourceXYZ,targetXYZ);
end
