function [directionsXYZ, diagnostics] = ...
        sampleSolidAngleDirections( ...
            directionCount, solidAngleSr, axisXYZ, inPlaneCount)
%SAMPLESOLIDANGLEDIRECTIONS Deterministic directions on a spherical cap.
%
% [directionsXYZ, diagnostics] = ...
%     swsynth.sampleSolidAngleDirections( ...
%         directionCount, solidAngleSr, axisXYZ, inPlaneCount)
%
% Inputs
% ------
% directionCount
%   Total number of directions.
%
% solidAngleSr
%   Spherical-cap solid angle in steradians:
%
%       0 < solidAngleSr <= 4*pi
%
%   Examples:
%       4*pi : full sphere
%       2*pi : hemisphere
%
% axisXYZ
%   Unit-cap axis before normalization.
%
% inPlaneCount
%   Exact number of directions constrained to the x-z observation plane:
%
%       uy = 0
%
% The remaining directions are sampled deterministically using an
% equal-solid-angle Fibonacci construction.
%
% Propagation convention
% ----------------------
% directionXYZ points in the direction of propagation. A direction with
% ux > 0 enters the domain from the left and propagates toward +x.

validateattributes( ...
    directionCount, ...
    {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'});

validateattributes( ...
    solidAngleSr, ...
    {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});

validateattributes( ...
    axisXYZ, ...
    {'numeric'}, ...
    {'vector', 'numel', 3, 'real', 'finite'});

validateattributes( ...
    inPlaneCount, ...
    {'numeric'}, ...
    {'scalar', 'integer', 'nonnegative', 'finite'});

if solidAngleSr > 4*pi + 100*eps(4*pi)
    error( ...
        "swsynth:InvalidSolidAngle", ...
        "solidAngleSr must satisfy 0 < solidAngleSr <= 4*pi.");
end

solidAngleSr = min(double(solidAngleSr), 4*pi);

if inPlaneCount > directionCount
    error( ...
        "swsynth:InvalidInPlaneDirectionCount", ...
        "inPlaneCount must not exceed directionCount.");
end

axisXYZ = double(axisXYZ(:));
axisNorm = norm(axisXYZ);

if axisNorm <= eps
    error( ...
        "swsynth:InvalidSolidAngleAxis", ...
        "axisXYZ must have nonzero magnitude.");
end

axisHat = axisXYZ / axisNorm;

cosHalfAngle = 1 - solidAngleSr/(2*pi);
cosHalfAngle = max(-1, min(1, cosHalfAngle));

halfAngleRad = acos(cosHalfAngle);

outOfPlaneCount = directionCount - inPlaneCount;

inPlaneXYZ = sampleInPlaneDirections( ...
    inPlaneCount, ...
    axisHat, ...
    cosHalfAngle);

outOfPlaneXYZ = sampleFibonacciCapDirections( ...
    outOfPlaneCount, ...
    axisHat, ...
    cosHalfAngle);

directionsXYZ = [
    inPlaneXYZ
    outOfPlaneXYZ];

directionsXYZ = ...
    directionsXYZ ./ vecnorm(directionsXYZ, 2, 2);

supportProjection = directionsXYZ * axisHat;

supportTolerance = 1e-12;

if any(supportProjection < cosHalfAngle - supportTolerance)
    error( ...
        "swsynth:SolidAngleSamplingFailure", ...
        "A generated direction lies outside the requested spherical cap.");
end

inPlaneMask = abs(directionsXYZ(:, 2)) <= 1e-12;

if nnz(inPlaneMask) ~= inPlaneCount
    error( ...
        "swsynth:InPlaneDirectionCountMismatch", ...
        ["Generated %d exactly in-plane directions, but %d " + ...
         "were requested."], ...
        nnz(inPlaneMask), ...
        inPlaneCount);
end

diagnostics = struct();
diagnostics.direction_count = directionCount;
diagnostics.in_plane_count = inPlaneCount;
diagnostics.out_of_plane_count = outOfPlaneCount;
diagnostics.solid_angle_sr = solidAngleSr;
diagnostics.solid_angle_fraction = solidAngleSr/(4*pi);
diagnostics.half_angle_rad = halfAngleRad;
diagnostics.half_angle_deg = rad2deg(halfAngleRad);
diagnostics.axis_xyz = axisHat.';
diagnostics.in_plane_mask = inPlaneMask;
diagnostics.minimum_axis_projection = min(supportProjection);
diagnostics.maximum_axis_projection = max(supportProjection);
diagnostics.sampling_method = ...
    "fibonacci_equal_solid_angle_with_exact_in_plane";

end

function directionsXYZ = sampleFibonacciCapDirections( ...
    directionCount, axisHat, cosHalfAngle)

if directionCount == 0
    directionsXYZ = zeros(0, 3);
    return;
end

index = (0:directionCount-1).';

% Equal-area coordinate on the spherical cap.
mu = ...
    1 - ...
    ((index + 0.5) ./ directionCount) .* ...
    (1 - cosHalfAngle);

transverseRadius = sqrt(max(0, 1 - mu.^2));

goldenAngle = pi * (3 - sqrt(5));

% Half-step offset avoids placing the first point on a preferred meridian.
azimuth = goldenAngle .* (index + 0.5);

[e1, e2] = transverseBasis(axisHat);

directionsXYZ = ...
    mu .* axisHat.' + ...
    (transverseRadius .* cos(azimuth)) .* e1.' + ...
    (transverseRadius .* sin(azimuth)) .* e2.';

% The out-of-plane set must not accidentally add exact uy = 0 points.
planeTolerance = 1e-12;

for directionIndex = 1:directionCount
    adjustmentCount = 0;

    while abs(directionsXYZ(directionIndex, 2)) <= planeTolerance
        adjustmentCount = adjustmentCount + 1;

        if adjustmentCount > 20
            error( ...
                "swsynth:SolidAngleSamplingFailure", ...
                "Could not move a Fibonacci direction away from uy = 0.");
        end

        adjustedAzimuth = ...
            azimuth(directionIndex) + ...
            adjustmentCount * 1e-7;

        directionsXYZ(directionIndex, :) = ...
            mu(directionIndex) .* axisHat.' + ...
            transverseRadius(directionIndex) .* ...
                cos(adjustedAzimuth) .* e1.' + ...
            transverseRadius(directionIndex) .* ...
                sin(adjustedAzimuth) .* e2.';
    end
end

end

function directionsXYZ = sampleInPlaneDirections( ...
    directionCount, axisHat, cosHalfAngle)

if directionCount == 0
    directionsXYZ = zeros(0, 3);
    return;
end

axisProjectionMagnitude = hypot( ...
    axisHat(1), ...
    axisHat(3));

planeTolerance = 1e-12;

if axisProjectionMagnitude <= planeTolerance
    % For an axis normal to the observation plane, every in-plane
    % direction has dot(u,axis)=0.
    if cosHalfAngle > planeTolerance
        error( ...
            "swsynth:SolidAngleDoesNotIntersectObservationPlane", ...
            ["The requested spherical cap does not intersect the " + ...
             "x-z observation plane, so inPlaneCount must be zero."]);
    end

    centerAngle = 0;
    allowedHalfWidth = pi;

else
    centerAngle = atan2(axisHat(3), axisHat(1));

    normalizedThreshold = ...
        cosHalfAngle / axisProjectionMagnitude;

    if normalizedThreshold > 1 + planeTolerance
        error( ...
            "swsynth:SolidAngleDoesNotIntersectObservationPlane", ...
            ["The requested spherical cap does not intersect the " + ...
             "x-z observation plane, so inPlaneCount must be zero."]);
    elseif normalizedThreshold <= -1
        allowedHalfWidth = pi;
    else
        normalizedThreshold = max(-1, min(1, normalizedThreshold));
        allowedHalfWidth = acos(normalizedThreshold);
    end
end

if abs(allowedHalfWidth - pi) <= planeTolerance
    % Full circle. Midpoint placement avoids duplicating 0 and 2*pi.
    alpha = ...
        centerAngle + ...
        2*pi .* ((0:directionCount-1).' + 0.5) ./ ...
        directionCount;
else
    % Uniform midpoint placement over the allowed arc.
    alpha = ...
        centerAngle - allowedHalfWidth + ...
        2*allowedHalfWidth .* ...
        ((0:directionCount-1).' + 0.5) ./ ...
        directionCount;
end

directionsXYZ = [
    cos(alpha), ...
    zeros(directionCount, 1), ...
    sin(alpha)];

end

function [e1, e2] = transverseBasis(axisHat)

axisHat = axisHat(:);

if abs(dot(axisHat, [0; 0; 1])) < 0.99
    temporary = [0; 0; 1];
else
    temporary = [0; 1; 0];
end

e1 = cross(temporary, axisHat);
e1 = e1 / norm(e1);

e2 = cross(axisHat, e1);
e2 = e2 / norm(e2);

end
