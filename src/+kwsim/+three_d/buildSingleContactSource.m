function [source, metadata] = buildSingleContactSource(cfg, kgrid)
%BUILDSINGLECONTACTSOURCE Build a sparse finite-disk 3D velocity source.
%
% The contact lies in a yz plane near the left x boundary. The default
% velocity is polarized along +z and is transverse to the intended +x
% propagation direction.
%
% The disk is sampled on a sparse lattice to avoid adjacent Dirichlet
% constraints during long continuous-wave simulations.

arguments
    cfg struct
    kgrid
end

mask_xyz = false( ...
    cfg.grid.Nx, ...
    cfg.grid.Ny, ...
    cfg.grid.Nz);

source_x = cfg.source.center_index_xyz(1);
mask_xyz(source_x, :, :) = reshape( ...
    cfg.source.contact_mask_yz, ...
    1, cfg.grid.Ny, cfg.grid.Nz);

t_s = double(kgrid.t_array(:).');

ramp_duration_s = ...
    cfg.source.ramp_cycles / cfg.source.f0_hz;

envelope = ones(size(t_s));

ramp_index = t_s < ramp_duration_s;

envelope(ramp_index) = ...
    0.5 * (1 - cos( ...
    pi * t_s(ramp_index) / ramp_duration_s));

waveform_m_s = ...
    cfg.source.velocity_amplitude_m_s .* ...
    envelope .* ...
    sin(2*pi*cfg.source.f0_hz*t_s + ...
    cfg.source.phase_rad);

polarization = cfg.source.polarization_xyz;

source = struct();
source.u_mask = mask_xyz;
source.ux = single(polarization(1) * waveform_m_s);
source.uy = single(polarization(2) * waveform_m_s);
source.uz = single(polarization(3) * waveform_m_s);
source.u_mode = char(cfg.source.mode);

metadata = struct();
metadata.kind = "external_sparse_disk_velocity";
metadata.side = string(cfg.source.side);
metadata.mode = string(cfg.source.mode);

metadata.center_index_xyz = ...
    cfg.source.center_index_xyz;
metadata.center_m_xyz = ...
    cfg.source.center_m_xyz;

metadata.contact_radius_m = ...
    cfg.source.contact_radius_m;
metadata.realized_radius_y_m = ...
    cfg.source.realized_radius_y_m;
metadata.realized_radius_z_m = ...
    cfg.source.realized_radius_z_m;

metadata.contact_node_spacing_points = ...
    cfg.source.contact_node_spacing_points;
metadata.contact_node_count = nnz(mask_xyz);

metadata.mask_xyz_internal = mask_xyz;
metadata.mask_zyx = permute(mask_xyz, [3, 2, 1]);

metadata.polarization_xyz = ...
    cfg.source.polarization_xyz;
metadata.nominal_propagation_xyz = ...
    cfg.source.target_direction_xyz;

metadata.f0_hz = cfg.source.f0_hz;
metadata.phase_rad = cfg.source.phase_rad;
metadata.velocity_amplitude_m_s = ...
    cfg.source.velocity_amplitude_m_s;

metadata.t_s = t_s;
metadata.envelope = envelope;
metadata.waveform_m_s = waveform_m_s;

metadata.internal_orientation = "[Nx,Ny,Nz]";
metadata.public_orientation = "[Nz,Ny,Nx]";

end
