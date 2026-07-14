function MAT = make_material_map_2d(CFG)
%MAKE_MATERIAL_MAP_2D Build true material maps for controlled k-Wave tests.
%
% Coordinate convention:
%   k-Wave arrays are Nx-by-Nz, with the first dimension along x and the
%   second along z/depth. adaptive_req REQ maps use Uxz(z,x), so run output
%   transposes fields after harmonic extraction.

geometry = lower(string(CFG.Geometry));
[X, Z] = ndgrid(CFG.x_m, CFG.z_m);

cs = CFG.cs_soft * ones(CFG.Nx, CFG.Nz);
rho = CFG.rho_soft * ones(CFG.Nx, CFG.Nz);
material_id = ones(CFG.Nx, CFG.Nz);
hard_mask = false(CFG.Nx, CFG.Nz);

switch geometry
    case "homogeneous_cs2"
        cs(:) = 2.0;
        material_id(:) = 1;

    case "homogeneous_cs3"
        cs(:) = 3.0;
        material_id(:) = 2;

    case {"inclusion_2_3", "circular_inclusion_2_3"}
        r = hypot(X - CFG.inclusion_center_m(1), Z - CFG.inclusion_center_m(2));
        hard_mask = r <= CFG.inclusion_radius_m;
        cs(hard_mask) = CFG.cs_hard;
        rho(hard_mask) = CFG.rho_hard;
        material_id(hard_mask) = 2;

    case "bilayer_2_3"
        hard_mask = X >= median(CFG.x_m);
        cs(hard_mask) = CFG.cs_hard;
        rho(hard_mask) = CFG.rho_hard;
        material_id(hard_mask) = 2;

    otherwise
        error('Unknown controlled k-Wave geometry: %s', geometry);
end

switch lower(string(CFG.CompressionMode))
    case "matched_shear"
        cp = cs;
    case "constant"
        cp = CFG.compression_speed * ones(size(cs));
    otherwise
        error('Unknown CompressionMode: %s', CFG.CompressionMode);
end

MAT = struct();
MAT.cs_xz = cs;
MAT.cp_xz = cp;
MAT.rho_xz = rho;
MAT.material_id_xz = material_id;
MAT.hard_mask_xz = hard_mask;
MAT.cs_map_zx = cs.';
MAT.material_id_zx = material_id.';
MAT.x_m = CFG.x_m;
MAT.z_m = CFG.z_m;
MAT.geometry = geometry;

end
