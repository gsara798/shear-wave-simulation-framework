function [travelTimeS,distanceM] = computeTravelTime(sourceXYZ,targetXYZ,referenceCsMps)
%COMPUTETRAVELTIME Homogeneous spherical travel times from one physical node.
% Input coordinates are [x,y,z] in metres; output is N-by-1 seconds.
arguments
    sourceXYZ (1,3) double {mustBeReal,mustBeFinite}
    targetXYZ (:,3) double {mustBeReal,mustBeFinite}
    referenceCsMps (1,1) double {mustBeReal,mustBeFinite,mustBePositive}
end
if isempty(targetXYZ)
    error("swsynth:InvalidSphericalPhaseTargets", ...
        "Provide one or more observation positions.");
end
distanceM=vecnorm(targetXYZ-sourceXYZ,2,2);
if any(distanceM<=eps)
    error("swsynth:ObservationAtPointForce", ...
        "Observation positions must differ from the emitting point.");
end
travelTimeS=distanceM./referenceCsMps;
end
