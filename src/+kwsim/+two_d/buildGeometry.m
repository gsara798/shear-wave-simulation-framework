function [maps, metadata] = buildGeometry(cfg)
%BUILDGEOMETRY Rasterize ordered 2D geometry objects onto the solver grid.
%
% [maps, metadata] = kwsim.two_d.buildGeometry(cfg)
%
% Inputs use physical [x,z] coordinates in metres. Outputs use k-Wave's
% internal [Nx,Nz] orientation and are converted to public [Nz,Nx] maps only
% by the run adapter. Stage 2 supports circles; unknown object types fail
% explicitly instead of being silently ignored.

arguments
    cfg struct
end

x_m = (0:(cfg.grid.Nx - 1)) * cfg.grid.dx_m;
z_m = (0:(cfg.grid.Nz - 1)) * cfg.grid.dz_m;
[X_m, Z_m] = ndgrid(x_m, z_m);

maps = struct();
maps.cs_m_s_xz = cfg.medium.cs_m_s * ones(cfg.grid.Nx, cfg.grid.Nz);
maps.rho_kg_m3_xz = cfg.medium.rho_kg_m3 * ones(cfg.grid.Nx, cfg.grid.Nz);
maps.material_id_xz = ones(cfg.grid.Nx, cfg.grid.Nz, 'uint16');

objects = cfg.geometry.objects;
object_metadata = repmat(emptyObjectMetadata(), numel(objects), 1);
object_masks_xz = cell(numel(objects), 1);
for index = 1:numel(objects)
    object = objects(index);
    switch lower(string(object.type))
        case "circle"
            mask = (X_m - object.center_m_xz(1)).^2 + ...
                (Z_m - object.center_m_xz(2)).^2 <= object.radius_m^2;
            requested_area_m2 = pi*object.radius_m^2;
        otherwise
            error('kwsim:UnsupportedGeometry', ...
                'Unsupported 2D geometry type: %s', string(object.type));
    end

    maps.cs_m_s_xz(mask) = object.cs_m_s;
    maps.rho_kg_m3_xz(mask) = object.rho_kg_m3;
    maps.material_id_xz(mask) = object.material_id;
    object_masks_xz{index} = mask;

    discrete_area_m2 = nnz(mask) * cfg.grid.dx_m * cfg.grid.dz_m;
    info = emptyObjectMetadata();
    info.type = string(object.type);
    info.name = string(object.name);
    info.center_m_xz = object.center_m_xz;
    info.radius_m = object.radius_m;
    info.material_id = object.material_id;
    info.cs_m_s = object.cs_m_s;
    info.rho_kg_m3 = object.rho_kg_m3;
    info.requested_area_m2 = requested_area_m2;
    info.discrete_area_m2 = discrete_area_m2;
    info.area_relative_error = abs(discrete_area_m2 - requested_area_m2) / ...
        requested_area_m2;
    info.grid_point_count = nnz(mask);
    object_metadata(index) = info;
end

metadata = struct();
metadata.objects = object_metadata;
metadata.object_masks_xz = object_masks_xz;
metadata.object_count = numel(objects);
metadata.minimum_cs_m_s = min(maps.cs_m_s_xz, [], 'all');
metadata.maximum_cs_m_s = max(maps.cs_m_s_xz, [], 'all');
metadata.material_ids = unique(maps.material_id_xz(:)).';
metadata.composition_rule = "Objects are applied in array order; later objects overwrite earlier objects.";

end

function info = emptyObjectMetadata()
info = struct('type', "", 'name', "", 'center_m_xz', [NaN, NaN], ...
    'radius_m', NaN, 'material_id', uint16(0), 'cs_m_s', NaN, ...
    'rho_kg_m3', NaN, 'requested_area_m2', NaN, ...
    'discrete_area_m2', NaN, 'area_relative_error', NaN, ...
    'grid_point_count', 0);
end
