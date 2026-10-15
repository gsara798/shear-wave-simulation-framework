function [travelTimeZYX, diagnostics] = computeDirectionalTravelTime(csMapZYX, xM, yM, zM, directionXYZ, referenceCsMps, solverOptions)
%COMPUTEDIRECTIONALTRAVELTIME Deprecated compatibility forwarding function.
if nargin < 7 || isempty(solverOptions)
    solverOptions = struct();
end

[travelTimeZYX, diagnostics] = swsynth.phase.eikonal.volumetric3d.computeTravelTime(csMapZYX, xM, yM, zM, directionXYZ, referenceCsMps, solverOptions);
end
