function [travelTimeZYX, diagnostics] = computeDirectionalTravelTime(csMapZYX, xM, yM, zM, directionXYZ, referenceCsMps, solverOptions)
%COMPUTEDIRECTIONALTRAVELTIME Deprecated compatibility forwarding function.
[travelTimeZYX, diagnostics] = swsynth.phase.eikonal.volumetric3d.computeTravelTime(csMapZYX, xM, yM, zM, directionXYZ, referenceCsMps, solverOptions);
end
