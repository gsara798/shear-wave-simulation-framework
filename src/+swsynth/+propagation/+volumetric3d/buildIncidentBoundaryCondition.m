function [initialTimeZYX, fixedMaskZYX, diagnostics] = buildIncidentBoundaryCondition(xM, yM, zM, directionXYZ, referenceCsMps)
%BUILDINCIDENTBOUNDARYCONDITION Deprecated compatibility forwarding function.
[initialTimeZYX, fixedMaskZYX, diagnostics] = swsynth.phase.eikonal.volumetric3d.buildIncidentBoundaryCondition(xM, yM, zM, directionXYZ, referenceCsMps);
end
