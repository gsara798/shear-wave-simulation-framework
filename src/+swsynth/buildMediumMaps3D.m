function maps = buildMediumMaps3D(cfg)
%BUILDMEDIUMMAPS3D Build volumetric shear-speed and material maps.
%
% Public orientation is (z,y,x). Medium construction is intentionally
% independent of propagation-backend compatibility; a heterogeneous map is
% valid even when the caller is only inspecting geometry. Complete runs
% still enforce propagation compatibility through validateConfig3D.

arguments
    cfg (1,1) struct
end

[cfg, ~] = swsynth.validateConfig3D( ...
    cfg, EnforcePropagationCompatibility=false);

Nx = round(cfg.domain.Lx_m / cfg.domain.dx_m) + 1;
Ny = round(cfg.domain.Ly_m / cfg.domain.dy_m) + 1;
Nz = round(cfg.domain.Lz_m / cfg.domain.dz_m) + 1;

x_m = linspace(0, cfg.domain.Lx_m, Nx);
y_m = linspace(0, cfg.domain.Ly_m, Ny);
z_m = linspace(0, cfg.domain.Lz_m, Nz);

[Z, Y, X] = ndgrid(z_m, y_m, x_m);

csMap = cfg.medium.background_cs_m_s * ones(Nz, Ny, Nx);
materialId = zeros(Nz, Ny, Nx, "uint16");
alpha = cell(1, numel(cfg.medium.objects));

for i = 1:numel(cfg.medium.objects)
    object = cfg.medium.objects{i};
    mask = maskForObject(object, X, Y, Z, [Nz Ny Nx]);
    alpha{i} = double(mask);
    csMap(mask) = object.cs_m_s;
    materialId(mask) = uint16(i);
end

kMap = 2*pi*cfg.wavefield.frequency_hz ./ csMap;

maps = struct();
maps.x_m = x_m;
maps.y_m = y_m;
maps.z_m = z_m;
maps.dx_m = cfg.domain.dx_m;
maps.dy_m = cfg.domain.dy_m;
maps.dz_m = cfg.domain.dz_m;
maps.cs_map_zyx = csMap;
maps.k_map_zyx = kMap;
maps.material_id_zyx = materialId;
maps.object_alpha_zyx = alpha;
maps.output_convention = "maps(z,y,x)";

end

function mask = maskForObject(object, X, Y, Z, expectedSize)

switch string(object.type)
    case "sphere"
        c = double(object.center_xyz_m);
        mask = (X-c(1)).^2 + (Y-c(2)).^2 + (Z-c(3)).^2 ...
            <= double(object.radius_m)^2;

    case "box"
        c = double(object.center_xyz_m);
        halfSize = double(object.size_xyz_m) / 2;
        mask = abs(X-c(1)) <= halfSize(1) & ...
            abs(Y-c(2)) <= halfSize(2) & ...
            abs(Z-c(3)) <= halfSize(3);

    case "slab"
        n = double(object.normal_xyz(:));
        signedCoordinate = X*n(1) + Y*n(2) + Z*n(3);
        mask = signedCoordinate >= double(object.offset_m);

    case "custom"
        mask = logical(object.mask_zyx);
        if ~isequal(size(mask), expectedSize)
            error("swsynth:Custom3DMaskSizeMismatch", ...
                "custom mask_zyx must have size [Nz Ny Nx] = [%d %d %d].", ...
                expectedSize(1), expectedSize(2), expectedSize(3));
        end

    otherwise
        error("swsynth:Unknown3DMediumObjectType", ...
            "Unsupported 3D medium object type: %s.", object.type);
end

end
