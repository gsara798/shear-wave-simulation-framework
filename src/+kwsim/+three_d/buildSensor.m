function [sensor, metadata] = buildSensor(cfg)
%BUILDSENSOR Build the cuboidal 3D analysis sensor.
%
% The binary mask follows k-Wave's internal [Nx,Ny,Nz] orientation.
% Split compressional and shear velocity components are recorded.

arguments
    cfg struct
end

mask_xyz = false( ...
    cfg.grid.Nx, ...
    cfg.grid.Ny, ...
    cfg.grid.Nz);

mask_xyz( ...
    cfg.sensor.x_indices, ...
    cfg.sensor.y_indices, ...
    cfg.sensor.z_indices) = true;

sensor = struct();
sensor.mask = mask_xyz;
sensor.record = {'u_split_field'};
sensor.record_start_index = cfg.time.record_start_index;

metadata = struct();
metadata.mask_xyz_internal = mask_xyz;
metadata.mask_zyx = permute(mask_xyz, [3, 2, 1]);

metadata.x_indices = cfg.sensor.x_indices;
metadata.y_indices = cfg.sensor.y_indices;
metadata.z_indices = cfg.sensor.z_indices;

metadata.x_m = cfg.derived.x_full_m(metadata.x_indices);
metadata.y_m = cfg.derived.y_full_m(metadata.y_indices);
metadata.z_m = cfg.derived.z_full_m(metadata.z_indices);

metadata.size_xyz = [
    numel(metadata.x_indices), ...
    numel(metadata.y_indices), ...
    numel(metadata.z_indices)
];

metadata.point_count = nnz(mask_xyz);
metadata.record_start_index = cfg.time.record_start_index;
metadata.internal_orientation = "[Nx,Ny,Nz]";
metadata.public_orientation = "[Nz,Ny,Nx]";

end
