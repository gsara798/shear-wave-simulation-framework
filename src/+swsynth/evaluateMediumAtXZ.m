function [cs, materialId, objectAlpha] = evaluateMediumAtXZ(cfg, X, Z)
%EVALUATEMEDIUMATXZ Evaluate the synthetic medium at arbitrary x-z points.
%
% X and Z must have identical sizes. The output arrays preserve that size.
%
% This pointwise evaluator currently supports sharp analytic objects:
% circle, bilayer, and s_curve. Custom masks and nonzero edge_sigma_m
% remain supported by buildMediumMaps, but are not used by the numerical
% straight-ray integrator.

arguments
    cfg (1,1) struct
    X {mustBeNumeric}
    Z {mustBeNumeric}
end

[cfg, ~] = swsynth.validateConfig(cfg);

if ~isequal(size(X), size(Z))
    error("swsynth:CoordinateSizeMismatch", ...
        "X and Z must have identical sizes.");
end

if any(~isfinite(X(:))) || any(~isfinite(Z(:)))
    error("swsynth:NonfiniteCoordinates", ...
        "X and Z must contain only finite values.");
end

X = double(X);
Z = double(Z);

backgroundCs = cfg.medium.background_cs_m_s;
cs = backgroundCs * ones(size(X));
materialId = zeros(size(X), "uint16");

objectCount = numel(cfg.medium.objects);
objectAlpha = cell(1, objectCount);

for i = 1:objectCount
    object = cfg.medium.objects{i};

    if object.edge_sigma_m ~= 0
        error("swsynth:PointEvaluationRequiresSharpEdges", ...
            "Pointwise medium evaluation currently requires " + ...
            "edge_sigma_m = 0.");
    end

    if object.type == "custom"
        error("swsynth:PointEvaluationCustomUnsupported", ...
            "Pointwise evaluation of custom masks is not yet " + ...
            "supported.");
    end

    objectAlpha{i} = alphaFromAnalyticObject(X, Z, object);
end

switch cfg.medium.combine_mode
    case "overlay"
        for i = 1:objectCount
            alpha = objectAlpha{i};

            cs = (1 - alpha) .* cs + ...
                alpha .* cfg.medium.objects{i}.cs_m_s;

            materialId(alpha >= 0.5) = uint16(i);
        end

    case "blend"
        numerator = zeros(size(X));
        denominator = zeros(size(X));

        for i = 1:objectCount
            alpha = objectAlpha{i};

            numerator = numerator + ...
                alpha .* cfg.medium.objects{i}.cs_m_s;

            denominator = denominator + alpha;
        end

        totalAlpha = min(denominator, 1);
        blendedCs = numerator ./ max(denominator, eps);

        cs = (1 - totalAlpha) .* backgroundCs + ...
            totalAlpha .* blendedCs;

        for i = 1:objectCount
            materialId(objectAlpha{i} >= 0.5) = uint16(i);
        end

    case {"max", "min"}
        for i = 1:objectCount
            alpha = objectAlpha{i};

            localCs = (1 - alpha) .* backgroundCs + ...
                alpha .* cfg.medium.objects{i}.cs_m_s;

            if cfg.medium.combine_mode == "max"
                updateMask = localCs > cs;
                cs = max(cs, localCs);
            else
                updateMask = localCs < cs;
                cs = min(cs, localCs);
            end

            materialId(updateMask) = uint16(i);
        end
end

end

function alpha = alphaFromAnalyticObject(X, Z, object)

switch object.type
    case "circle"
        center = object.center_xz_m;

        radiusFromCenter = sqrt( ...
            (X - center(1)).^2 + ...
            (Z - center(2)).^2);

        binaryMask = radiusFromCenter <= object.radius_m;

    case "bilayer"
        normal = [ ...
            cos(object.normal_angle_rad); ...
            sin(object.normal_angle_rad)];

        signedDistance = ...
            X .* normal(1) + ...
            Z .* normal(2) - ...
            object.offset_m;

        binaryMask = signedDistance > 0;

    case "s_curve"
        center = object.center_xz_m;
        localX = X - center(1);
        localZ = Z - center(2);

        curveZ = object.amplitude_m .* ...
            sin(2*pi*localX / object.wavelength_m);

        binaryMask = ...
            abs(localZ - curveZ) <= object.thickness_m/2;

    otherwise
        error("swsynth:UnknownMediumObjectType", ...
            "Unsupported analytic medium object type: %s.", ...
            object.type);
end

alpha = double(binaryMask);

end
