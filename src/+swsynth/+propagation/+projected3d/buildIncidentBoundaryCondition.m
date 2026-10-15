function [initialTimeZX, fixedMaskZX, diagnostics] = buildIncidentBoundaryCondition(xM, zM, directionXYZ, referenceCsMps)
%BUILDINCIDENTBOUNDARYCONDITION Deprecated compatibility forwarding function.
[initialTimeZX, fixedMaskZX, diagnostics] = swsynth.phase.eikonal.projected3d.buildIncidentBoundaryCondition(xM, zM, directionXYZ, referenceCsMps);
end
