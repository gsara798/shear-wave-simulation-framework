function [directionalSlownessZX, diagnostics] = buildDirectionalSlowness(csMapZX, directionXYZ, referenceCsMps)
%BUILDDIRECTIONALSLOWNESS Deprecated compatibility forwarding function.
[directionalSlownessZX, diagnostics] = swsynth.phase.eikonal.projected3d.buildDirectionalSlowness(csMapZX, directionXYZ, referenceCsMps);
end
