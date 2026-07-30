function maps = buildMediumMaps(cfg)
%BUILDMEDIUMMAPS Build shear-speed, wavenumber, and material maps.
%
% Public map orientation is (z,x).
%
% Usage:
%   cfg = swsynth.defaultConfig();
%   maps = swsynth.buildMediumMaps(cfg);
%
% Output fields:
%   x_m
%   z_m
%   cs_map_zx
%   k_map_zx
%   material_id_zx
%   object_alpha_zx

arguments
    cfg (1,1) struct
end

[cfg, ~] = swsynth.validateConfig(cfg);

Nx = round(cfg.domain.Lx_m / cfg.domain.dx_m) + 1;
Nz = round(cfg.domain.Lz_m / cfg.domain.dz_m) + 1;

x = linspace(0, cfg.domain.Lx_m, Nx);
z = linspace(0, cfg.domain.Lz_m, Nz);

[X, Z] = ndgrid(x, z);

supportsPointEvaluation = all(cellfun( ...
    @(object) object.edge_sigma_m == 0 && object.type ~= "custom", ...
    cfg.medium.objects));

if supportsPointEvaluation
    [csMapXZ, materialIdXZ, alphaStackXZ] = ...
        swsynth.evaluateMediumAtXZ(cfg, X, Z);
else
    backgroundCs = cfg.medium.background_cs_m_s;
    csMapXZ = backgroundCs * ones(Nx, Nz);
    materialIdXZ = zeros(Nx, Nz, "uint16");

    objectCount = numel(cfg.medium.objects);
    alphaStackXZ = cell(1, objectCount);

    switch cfg.medium.combine_mode
        case "overlay"
            for i = 1:objectCount
                alpha = alphaFromObject(X, Z, cfg.medium.objects{i});
                alphaStackXZ{i} = alpha;
                csMapXZ = (1 - alpha) .* csMapXZ + ...
                    alpha .* cfg.medium.objects{i}.cs_m_s;
                materialIdXZ(alpha >= 0.5) = uint16(i);

            end

        case "blend"
            numerator = zeros(Nx, Nz);
            denominator = zeros(Nx, Nz);

            for i = 1:objectCount
                alpha = alphaFromObject(X, Z, cfg.medium.objects{i});
                alphaStackXZ{i} = alpha;
                numerator = numerator + ...
                    alpha .* cfg.medium.objects{i}.cs_m_s;
                denominator = denominator + alpha;
            end

            totalAlpha = min(denominator, 1);
            blendedCs = numerator ./ max(denominator, eps);
            csMapXZ = (1 - totalAlpha) .* backgroundCs + ...
                totalAlpha .* blendedCs;

            for i = 1:objectCount
                mask = alphaStackXZ{i} >= 0.5;
                materialIdXZ(mask) = uint16(i);
            end

        case {"max", "min"}
            for i = 1:objectCount
                alpha = alphaFromObject(X, Z, cfg.medium.objects{i});
                alphaStackXZ{i} = alpha;

                localCs = (1 - alpha) .* backgroundCs + ...
                    alpha .* cfg.medium.objects{i}.cs_m_s;

                if cfg.medium.combine_mode == "max"
                    updateMask = localCs > csMapXZ;
                    csMapXZ = max(csMapXZ, localCs);
                else
                    updateMask = localCs < csMapXZ;
                    csMapXZ = min(csMapXZ, localCs);
                end

                materialIdXZ(updateMask) = uint16(i);
            end
    end
end

omega = 2*pi*cfg.wavefield.frequency_hz;
kMapXZ = omega ./ csMapXZ;

alphaStackZX = cell(size(alphaStackXZ));
for i = 1:numel(alphaStackXZ)
    alphaStackZX{i} = alphaStackXZ{i}.';
end

maps = struct();
maps.x_m = x;
maps.z_m = z;
maps.dx_m = cfg.domain.dx_m;
maps.dz_m = cfg.domain.dz_m;
maps.cs_map_zx = csMapXZ.';
maps.k_map_zx = kMapXZ.';
maps.material_id_zx = materialIdXZ.';
maps.object_alpha_zx = alphaStackZX;
maps.output_convention = "maps(z,x)";

end

function alpha = alphaFromObject(X, Z, object)

switch object.type
    case "circle"
        center = object.center_xz_m;
        radius = sqrt((X - center(1)).^2 + (Z - center(2)).^2);
        binaryMask = radius <= object.radius_m;

    case "s_curve"
        center = object.center_xz_m;
        localX = X - center(1);
        localZ = Z - center(2);
        curveZ = object.amplitude_m .* ...
            sin(2*pi*localX / object.wavelength_m);
        binaryMask = abs(localZ - curveZ) <= object.thickness_m/2;

    case "bilayer"
        normal = [ ...
            cos(object.normal_angle_rad); ...
            sin(object.normal_angle_rad)];
        signedDistance = X*normal(1) + Z*normal(2) - object.offset_m;
        binaryMask = signedDistance > 0;

    case "custom"
        expectedSize = fliplr(size(X));
        if ~isequal(size(object.mask_zx), expectedSize)
            error("swsynth:CustomMaskSizeMismatch", ...
                "custom mask_zx must have size [Nz, Nx] = [%d, %d].", ...
                expectedSize(1), expectedSize(2));
        end
        binaryMask = logical(object.mask_zx.');

    otherwise
        error("swsynth:UnknownMediumObjectType", ...
            "Unsupported medium object type: %s.", object.type);
end

alpha = softenMask(binaryMask, object.edge_sigma_m, X, Z);

end

function alpha = softenMask(binaryMask, edgeSigmaM, X, Z)

if edgeSigmaM <= 0
    alpha = double(binaryMask);
    return;
end

if exist("imgaussfilt", "file") ~= 2
    error("swsynth:MissingImageProcessingToolbox", ...
        "Nonzero edge_sigma_m requires imgaussfilt.");
end

dx = mean(diff(unique(X(:,1))));
dz = mean(diff(unique(Z(1,:))));
sigmaPixels = max(0.5, edgeSigmaM / max(dx, dz));
filterSize = 2*ceil(3*sigmaPixels) + 1;

alpha = imgaussfilt( ...
    double(binaryMask), ...
    sigmaPixels, ...
    FilterSize=filterSize, ...
    Padding="replicate");

maximum = max(alpha(:));
if maximum > 0
    alpha = alpha / maximum;
end

end
