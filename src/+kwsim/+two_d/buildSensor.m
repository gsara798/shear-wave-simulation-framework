function [sensor, metadata] = buildSensor(cfg)
%BUILDSENSOR Build the rectangular 2D analysis sensor.
%
% The binary mask is required by k-Wave's split-field recording. It excludes
% a source buffer and a small boundary margin. The PML is outside the user
% grid, so the returned ROI contains physical-domain points only.

arguments
    cfg struct
end

mask = false(cfg.grid.Nx, cfg.grid.Nz);
mask(cfg.sensor.x_indices, cfg.sensor.z_indices) = true;

sensor = struct();
sensor.mask = mask;
sensor.record = {'u_split_field'};
sensor.record_start_index = cfg.time.record_start_index;

metadata = struct();
metadata.mask_xz = mask;
metadata.mask_zx = mask.';
metadata.x_indices = cfg.sensor.x_indices;
metadata.z_indices = cfg.sensor.z_indices;
metadata.x_m = cfg.derived.x_full_m(metadata.x_indices);
metadata.z_m = cfg.derived.z_full_m(metadata.z_indices);
metadata.record_start_index = cfg.time.record_start_index;

end
