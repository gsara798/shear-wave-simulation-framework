function [projection, polarizationXYZ, radialDirectionXYZ, distanceM] = ...
    computePointForceShearProjection( ...
        sourceXYZ, observationXYZ, forceDirectionXYZ, observedDirectionXYZ)
%COMPUTEPOINTFORCESHEARPROJECTION Project 3D far-field shear polarization.
%
% For a point force F and source-to-observation unit vector n, the
% far-field shear polarization is
%
%   p = (I - n*n') F = F - n (n dot F).
%
% This function evaluates that vector in three dimensions and returns its
% signed projection onto the requested observed component. Coordinates use
% the physical [x,y,z] convention. observationXYZ may be N-by-3.

arguments
    sourceXYZ (1,3) double {mustBeReal, mustBeFinite}
    observationXYZ (:,3) double {mustBeReal, mustBeFinite}
    forceDirectionXYZ (1,3) double {mustBeReal, mustBeFinite}
    observedDirectionXYZ (1,3) double {mustBeReal, mustBeFinite}
end

forceNorm = norm(forceDirectionXYZ);
observedNorm = norm(observedDirectionXYZ);

if forceNorm <= eps
    error("swsynth:InvalidPointForceDirection", ...
        "forceDirectionXYZ must have nonzero magnitude.");
end
if observedNorm <= eps
    error("swsynth:InvalidObservedDirection", ...
        "observedDirectionXYZ must have nonzero magnitude.");
end

forceDirectionXYZ = forceDirectionXYZ ./ forceNorm;
observedDirectionXYZ = observedDirectionXYZ ./ observedNorm;

displacementXYZ = observationXYZ - sourceXYZ;
distanceM = vecnorm(displacementXYZ, 2, 2);
if any(distanceM <= eps)
    error("swsynth:ObservationAtPointForce", ...
        "An observation point must not coincide with the point force.");
end

radialDirectionXYZ = displacementXYZ ./ distanceM;
radialForceProjection = radialDirectionXYZ * forceDirectionXYZ.';
polarizationXYZ = forceDirectionXYZ - ...
    radialDirectionXYZ .* radialForceProjection;
projection = polarizationXYZ * observedDirectionXYZ.';

end
