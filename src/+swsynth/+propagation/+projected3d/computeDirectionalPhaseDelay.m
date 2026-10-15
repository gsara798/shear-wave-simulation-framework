function [phaseDelayZX, diagnostics] = computeDirectionalPhaseDelay(csMapZX, xM, zM, directionXYZ, referenceCsMps, solverOptions)
%COMPUTEDIRECTIONALPHASEDELAY Deprecated compatibility forwarding function.
if nargin < 6 || isempty(solverOptions)
    solverOptions = struct();
end

[phaseDelayZX, diagnostics] = swsynth.phase.eikonal.projected3d.computeTravelTime(csMapZX, xM, zM, directionXYZ, referenceCsMps, solverOptions);
end
