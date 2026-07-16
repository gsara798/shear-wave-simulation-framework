function [source, metadata] = buildSingleContactSource(cfg, kgrid)
%BUILDSINGLECONTACTSOURCE Build a prescribed 2D single-contact source.
%
% The contact is represented by regularly sampled points along a vertical
% line near the left boundary. Its imposed velocity is purely axial (+z),
% transverse to the intended lateral (+x) propagation. A half-cosine ramp
% avoids the broadband onset produced by a suddenly enabled sine or square
% wave.
%
% Important k-Wave 1.4.1 limitation: enforcing identical Dirichlet velocity
% on adjacent elastic grid points causes exponential numerical growth for
% long continuous-wave simulations. Sampling the contact every second grid
% point avoids conflicting adjacent constraints while retaining a resolved
% 2 mm contact. This behavior is covered by the finite-field diagnostic and
% documented as a single-contact solver limitation.
%
% source follows the pstdElastic2D convention [Nx,Nz]. metadata contains
% both that orientation and the public [Nz,Nx] representation.

arguments
    cfg struct
    kgrid
end

center = cfg.source.center_index_xz;
contact_z = cfg.source.contact_z_indices;
mask = false(cfg.grid.Nx, cfg.grid.Nz);
mask(center(1), contact_z) = true;

t_s = double(kgrid.t_array(:).');
ramp_duration_s = cfg.source.ramp_cycles / cfg.source.f0_hz;
envelope = ones(size(t_s));
ramp_index = t_s < ramp_duration_s;
envelope(ramp_index) = 0.5 * (1 - cos(pi * t_s(ramp_index) / ramp_duration_s));

waveform_m_s = cfg.source.velocity_amplitude_m_s * envelope .* ...
    sin(2*pi*cfg.source.f0_hz*t_s + cfg.source.phase_rad);

source = struct();
source.u_mask = mask;
source.uy = single(waveform_m_s);
source.u_mode = char(cfg.source.mode);

metadata = struct();
metadata.kind = "external_sampled_contact_velocity";
metadata.side = string(cfg.source.side);
metadata.mode = string(cfg.source.mode);
metadata.center_index_xz = center;
metadata.center_m_xz = cfg.source.center_m_xz;
metadata.contact_radius_m = cfg.source.contact_radius_m;
metadata.contact_radius_points = cfg.source.contact_radius_points;
if numel(contact_z) > 1
    metadata.contact_minimum_node_spacing_points = min(diff(contact_z));
else
    metadata.contact_minimum_node_spacing_points = NaN;
end
metadata.contact_node_count = nnz(mask);
metadata.contact_z_m = (contact_z - 1) * cfg.grid.dz_m;
metadata.realized_contact_span_m = ...
    max(metadata.contact_z_m) - min(metadata.contact_z_m);
metadata.mask_xz = mask;
metadata.mask_zx = mask.';
metadata.polarization_xz = [0, 1];
metadata.nominal_propagation_xz = [1, 0];
metadata.f0_hz = cfg.source.f0_hz;
metadata.phase_rad = cfg.source.phase_rad;
metadata.velocity_amplitude_m_s = cfg.source.velocity_amplitude_m_s;
metadata.t_s = t_s;
metadata.envelope = envelope;
metadata.waveform_m_s = waveform_m_s;

end
