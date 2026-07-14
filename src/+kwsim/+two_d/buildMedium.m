function [medium, truth] = buildMedium(cfg)
%BUILDMEDIUM Build a homogeneous or geometry-defined lossless 2D medium.
%
% Outputs use k-Wave's internal [Nx,Nz] orientation. Public result maps are
% transposed to [Nz,Nx] by the run adapter. No attenuation fields are added:
% pstdElastic2D is therefore lossless in Stage 1.

arguments
    cfg struct
end

[geometry_maps, geometry_metadata] = kwsim.two_d.buildGeometry(cfg);
grid_size = [cfg.grid.Nx, cfg.grid.Nz];
medium = struct();
medium.sound_speed_compression = cfg.medium.cp_m_s * ones(grid_size);
medium.sound_speed_shear = geometry_maps.cs_m_s_xz;
medium.density = geometry_maps.rho_kg_m3_xz;

truth = struct();
truth.cp_m_s_xz = medium.sound_speed_compression;
truth.cs_m_s_xz = medium.sound_speed_shear;
truth.rho_kg_m3_xz = medium.density;
truth.material_id_xz = geometry_maps.material_id_xz;
truth.attenuation_db_cm_xz = zeros(grid_size);
truth.geometry = geometry_metadata;

end
