function [travelTimeS, diagnostics] = integrateStraightRayTravelTime( ...
    cfg, sourceXYZ, targetXYZ)
%INTEGRATESTRAIGHTRAYTRAVELTIME Straight-ray travel time in a 2.5D medium.
%
% The medium is interpreted as extruded along y:
%   cs(x,y,z) = cs(x,z)
%
% sourceXYZ must be a finite 1-by-3 vector.
% targetXYZ must be a finite N-by-3 array.
%
% For sharp circle and bilayer objects, interface crossings are inserted
% as numerical integration breakpoints. Other supported analytic media
% use adaptive composite-midpoint integration.

arguments
    cfg (1,1) struct
    sourceXYZ {mustBeNumeric}
    targetXYZ {mustBeNumeric}
end

[cfg, ~] = swsynth.validateConfig(cfg);

sourceXYZ = double(sourceXYZ);
targetXYZ = double(targetXYZ);

if ~(isvector(sourceXYZ) && numel(sourceXYZ) == 3 && ...
        all(isfinite(sourceXYZ)))
    error("swsynth:InvalidSourceCoordinate", ...
        "sourceXYZ must be a finite three-vector.");
end

sourceXYZ = reshape(sourceXYZ, 1, 3);

if isvector(targetXYZ) && numel(targetXYZ) == 3
    targetXYZ = reshape(targetXYZ, 1, 3);
end

if isempty(targetXYZ) || size(targetXYZ, 2) ~= 3 || ...
        any(~isfinite(targetXYZ(:)))
    error("swsynth:InvalidTargetCoordinates", ...
        "targetXYZ must be a nonempty finite N-by-3 array.");
end

deltaXYZ = targetXYZ - sourceXYZ;
distanceM = sqrt(sum(deltaXYZ.^2, 2));

if isempty(cfg.medium.objects)
    travelTimeS = distanceM ./ cfg.medium.background_cs_m_s;

    diagnostics = struct();
    diagnostics.method = "homogeneous_exact";
    diagnostics.converged = true(size(distanceM));
    diagnostics.segment_count = double(distanceM > 0);
    diagnostics.max_phase_error_rad = 0;
    return;
end

supportsEventSplit = all(cellfun( ...
    @(object) object.edge_sigma_m == 0 && ...
        ismember(object.type, ["circle", "bilayer"]), ...
    cfg.medium.objects));

if supportsEventSplit
    [travelTimeS, segmentCount] = integrateWithEventBreakpoints( ...
        cfg, sourceXYZ, targetXYZ, distanceM);

    diagnostics = struct();
    diagnostics.method = "event_split_midpoint";
    diagnostics.converged = true(size(distanceM));
    diagnostics.segment_count = segmentCount;
    diagnostics.max_phase_error_rad = 0;
    return;
end

[travelTimeS, converged, phaseErrorRad, refinementDepth] = ...
    integrateAdaptiveMidpoint( ...
        cfg, sourceXYZ, targetXYZ, distanceM);

if any(~converged)
    error("swsynth:StraightRayIntegrationDidNotConverge", ...
        ["Straight-ray integration did not converge for %d of %d rays " ...
         "within maximum_refinement_depth = %d."], ...
        sum(~converged), numel(converged), ...
        cfg.propagation.maximum_refinement_depth);
end

diagnostics = struct();
diagnostics.method = "adaptive_midpoint";
diagnostics.converged = converged;
diagnostics.segment_count = 2.^refinementDepth;
diagnostics.max_phase_error_rad = max(phaseErrorRad);

end

function [travelTimeS, segmentCount] = integrateWithEventBreakpoints( ...
    cfg, sourceXYZ, targetXYZ, distanceM)

targetCount = size(targetXYZ, 1);

eventSlotCount = 0;
for i = 1:numel(cfg.medium.objects)
    switch cfg.medium.objects{i}.type
        case "bilayer"
            eventSlotCount = eventSlotCount + 1;
        case "circle"
            eventSlotCount = eventSlotCount + 2;
    end
end

breakpoints = ones(targetCount, eventSlotCount + 2);
breakpoints(:, 1) = 0;

sourceX = sourceXYZ(1);
sourceZ = sourceXYZ(3);

deltaX = targetXYZ(:, 1) - sourceX;
deltaZ = targetXYZ(:, 3) - sourceZ;

nextColumn = 2;

for i = 1:numel(cfg.medium.objects)
    object = cfg.medium.objects{i};

    switch object.type
        case "bilayer"
            normalX = cos(object.normal_angle_rad);
            normalZ = sin(object.normal_angle_rad);

            sourceSignedDistance = ...
                sourceX * normalX + ...
                sourceZ * normalZ - ...
                object.offset_m;

            denominator = ...
                deltaX .* normalX + ...
                deltaZ .* normalZ;

            tCross = -sourceSignedDistance ./ denominator;

            valid = ...
                abs(denominator) > 1e-14 & ...
                tCross > 0 & ...
                tCross < 1;

            tCross(~valid) = 1;
            breakpoints(:, nextColumn) = tCross;
            nextColumn = nextColumn + 1;

        case "circle"
            center = object.center_xz_m;

            relativeSourceX = sourceX - center(1);
            relativeSourceZ = sourceZ - center(2);

            quadraticA = deltaX.^2 + deltaZ.^2;
            quadraticB = 2 .* ( ...
                relativeSourceX .* deltaX + ...
                relativeSourceZ .* deltaZ);
            quadraticC = ...
                relativeSourceX.^2 + ...
                relativeSourceZ.^2 - ...
                object.radius_m.^2;

            discriminant = ...
                quadraticB.^2 - ...
                4 .* quadraticA .* quadraticC;

            safeDenominator = 2 .* max(quadraticA, realmin);
            squareRoot = sqrt(max(discriminant, 0));

            tEntry = (-quadraticB - squareRoot) ./ safeDenominator;
            tExit = (-quadraticB + squareRoot) ./ safeDenominator;

            validRay = ...
                quadraticA > 1e-20 & ...
                discriminant >= 0;

            validEntry = ...
                validRay & ...
                tEntry > 0 & ...
                tEntry < 1;

            validExit = ...
                validRay & ...
                tExit > 0 & ...
                tExit < 1;

            tEntry(~validEntry) = 1;
            tExit(~validExit) = 1;

            breakpoints(:, nextColumn) = tEntry;
            breakpoints(:, nextColumn + 1) = tExit;
            nextColumn = nextColumn + 2;
    end
end

breakpoints = sort(breakpoints, 2);

segmentWidth = diff(breakpoints, 1, 2);
segmentMidpoint = ...
    0.5 .* ( ...
        breakpoints(:, 1:end-1) + ...
        breakpoints(:, 2:end));

sampleX = sourceX + deltaX .* segmentMidpoint;
sampleZ = sourceZ + deltaZ .* segmentMidpoint;

segmentCs = swsynth.evaluateMediumAtXZ( ...
    cfg, sampleX, sampleZ);

slownessIntegral = sum( ...
    segmentWidth ./ segmentCs, ...
    2);

travelTimeS = distanceM .* slownessIntegral;
segmentCount = sum(segmentWidth > 1e-14, 2);

end

function [travelTimeS, converged, phaseErrorRad, finalDepth] = ...
        integrateAdaptiveMidpoint( ...
            cfg, sourceXYZ, targetXYZ, distanceM)

omega = 2*pi*cfg.wavefield.frequency_hz;
toleranceRad = cfg.propagation.phase_tolerance_rad;
maximumDepth = cfg.propagation.maximum_refinement_depth;

previousIntegral = compositeMidpointIntegral( ...
    cfg, sourceXYZ, targetXYZ, 1);

converged = distanceM == 0;
phaseErrorRad = inf(size(distanceM));
finalDepth = zeros(size(distanceM));

currentIntegral = previousIntegral;

for depth = 1:maximumDepth
    intervalCount = 2^depth;

    currentIntegral = compositeMidpointIntegral( ...
        cfg, sourceXYZ, targetXYZ, intervalCount);

    phaseErrorRad = ...
        omega .* distanceM .* ...
        abs(currentIntegral - previousIntegral);

    newlyConverged = ...
        ~converged & ...
        phaseErrorRad <= toleranceRad;

    finalDepth(newlyConverged) = depth;
    converged = converged | newlyConverged;

    if all(converged)
        break;
    end

    previousIntegral = currentIntegral;
end

finalDepth(finalDepth == 0) = maximumDepth;
travelTimeS = distanceM .* currentIntegral;

end

function slownessIntegral = compositeMidpointIntegral( ...
    cfg, sourceXYZ, targetXYZ, intervalCount)

targetCount = size(targetXYZ, 1);
slownessIntegral = zeros(targetCount, 1);

midpointT = ...
    ((0:intervalCount-1) + 0.5) ./ intervalCount;

maximumPointCount = 2e6;
chunkSize = max(1, floor(maximumPointCount / intervalCount));

sourceX = sourceXYZ(1);
sourceZ = sourceXYZ(3);

for firstIndex = 1:chunkSize:targetCount
    lastIndex = min( ...
        targetCount, ...
        firstIndex + chunkSize - 1);

    indices = firstIndex:lastIndex;

    deltaX = targetXYZ(indices, 1) - sourceX;
    deltaZ = targetXYZ(indices, 3) - sourceZ;

    sampleX = sourceX + deltaX .* midpointT;
    sampleZ = sourceZ + deltaZ .* midpointT;

    cs = swsynth.evaluateMediumAtXZ( ...
        cfg, sampleX, sampleZ);

    slownessIntegral(indices) = ...
        mean(1 ./ cs, 2);
end

end
