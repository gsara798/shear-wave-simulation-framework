function [phaseDelayZX, diagnostics] = computeDirectionalPhaseDelay(csMapZX, xM, zM, directionXYZ, referenceCsMps, solverOptions)
%COMPUTEDIRECTIONALPHASEDELAY Deprecated compatibility forwarding function.
[phaseDelayZX, diagnostics] = swsynth.phase.eikonal.projected3d.computeTravelTime(csMapZX, xM, zM, directionXYZ, referenceCsMps, solverOptions);
end
