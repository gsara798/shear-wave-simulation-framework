function [medium, truth] = buildMedium(cfg)
%BUILDMEDIUM Build the homogeneous medium for pstdElastic3D.
%
% The initial 3D foundation supports a homogeneous, lossless medium.
% k-Wave receives scalar properties to reduce memory use. Full internal
% truth maps are returned in [Nx,Ny,Nz] orientation for diagnostics and
% later conversion to the public [Nz,Ny,Nx] contract.

arguments
    cfg struct
end

grid_size = [
    cfg.grid.Nx, ...
    cfg.grid.Ny, ...
    cfg.grid.Nz
];

medium = struct();
medium.sound_speed_compression = cfg.medium.cp_m_s;
medium.sound_speed_shear = cfg.medium.cs_m_s;
medium.density = cfg.medium.rho_kg_m3;

if cfg.attenuation.enabled
    error("kwsim:ThreeDAttenuationNotImplemented", ...
        "3D attenuation is not implemented in the homogeneous foundation.");
end

truth = struct();
truth.cp_m_s_xyz = ...
    cfg.medium.cp_m_s * ones(grid_size, 'single');

truth.cs_m_s_xyz = ...
    cfg.medium.cs_m_s * ones(grid_size, 'single');

truth.rho_kg_m3_xyz = ...
    cfg.medium.rho_kg_m3 * ones(grid_size, 'single');

truth.material_id_xyz = ...
    ones(grid_size, 'uint16');

truth.orientation = "[Nx,Ny,Nz]";
truth.homogeneous = true;
truth.attenuation = struct( ...
    'enabled', false, ...
    'model', string(cfg.attenuation.model));

end
