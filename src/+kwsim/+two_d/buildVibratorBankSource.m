function [source, metadata] = buildVibratorBankSource(cfg, kgrid)
%BUILDVIBRATORBANKSOURCE Build labelled vector sources for a Stage 3 run.
%
% [source, metadata] = kwsim.two_d.buildVibratorBankSource(cfg, kgrid)
%
% Each nonzero integer in source.u_mask identifies one solver channel. A
% point vibrator has one channel; a finite contact has one independently
% weighted channel per non-adjacent contact node. Rows of source.ux and
% source.uy contain lateral and axial velocity. Public vectors use [x,z],
% while k-Wave stores its 2D arrays internally as [Nx,Nz]. Units are m/s.
%
% All contacts use the same single frequency and half-cosine startup ramp.
% Independent phase and transverse polarization define the requested field
% regime. The imposed-velocity drive is normalized before this function is
% called; it is a reproducible drive proxy, not mechanical power in watts.

arguments
    cfg struct
    kgrid
end

bank = cfg.source.resolved_bank;
t_s = double(kgrid.t_array(:).');
ramp_duration_s = cfg.source.ramp_cycles / cfg.source.f0_hz;
envelope = ones(size(t_s));
ramp_index = t_s < ramp_duration_s;
envelope(ramp_index) = 0.5 * ...
    (1 - cos(pi * t_s(ramp_index) / ramp_duration_s));

count = bank.vibrator_count;
channel_count = bank.solver_channel_count;
scalar_waveforms_m_s = zeros(count, numel(t_s), 'single');
for index = 1:count
    vibrator = bank.vibrators(index);
    waveform = vibrator.peak_velocity_m_s * envelope .* sin( ...
        2*pi*cfg.source.f0_hz*t_s + vibrator.phase_rad);
    scalar_waveforms_m_s(index, :) = single(waveform);
end

ux_m_s = zeros(channel_count, numel(t_s), 'single');
uz_m_s = zeros(channel_count, numel(t_s), 'single');
for channel_index = 1:channel_count
    channel = bank.solver_channels(channel_index);
    vibrator = bank.vibrators(channel.vibrator_id);
    waveform = channel.peak_velocity_m_s * envelope .* sin( ...
        2*pi*cfg.source.f0_hz*t_s + vibrator.phase_rad);
    ux_m_s(channel_index, :) = single( ...
        vibrator.polarization_xz(1) * waveform);
    uz_m_s(channel_index, :) = single( ...
        vibrator.polarization_xz(2) * waveform);
end

source = struct();
source.u_mask = bank.solver_label_mask_xz;
source.ux = ux_m_s;
source.uy = uz_m_s; % k-Wave's second coordinate is public axial z.
source.u_mode = char(cfg.source.mode);

if bank.coherent_count > 0
    representative = 1;
    nominal_center_m = mean(vertcat( ...
        bank.vibrators(1:bank.coherent_count).center_m_xz), 1);
else
    representative = 1;
    nominal_center_m = [mean(cfg.derived.x_full_m), mean(cfg.derived.z_full_m)];
end

metadata = struct();
metadata.kind = "external_labelled_velocity_bank";
metadata.regime = bank.regime;
metadata.mode = string(cfg.source.mode);
metadata.vibrator_count = bank.vibrator_count;
metadata.coherent_count = bank.coherent_count;
metadata.diffuse_count = bank.diffuse_count;
metadata.vibrators = bank.vibrators;
metadata.solver_channels = bank.solver_channels;
metadata.solver_channel_count = bank.solver_channel_count;
metadata.label_mask_xz = bank.solver_label_mask_xz;
metadata.label_mask_zx = bank.solver_label_mask_zx;
metadata.vibrator_id_mask_xz = bank.vibrator_id_mask_xz;
metadata.vibrator_id_mask_zx = bank.vibrator_id_mask_zx;
metadata.mask_xz = bank.solver_label_mask_xz > 0;
metadata.mask_zx = bank.solver_label_mask_zx > 0;
metadata.center_m_xz = nominal_center_m;
metadata.center_index_xz = [NaN, NaN];
metadata.contact_radius_m = cfg.source.contact_radius_m;
metadata.contact_radius_points = cfg.source.contact_radius_points;
metadata.contact_model = string(cfg.source.contact_model);
metadata.contact_profile = string(cfg.source.contact_profile);
metadata.contact_node_spacing_points = ...
    cfg.source.contact_node_spacing_points;
metadata.contact_sampling = string(cfg.source.contact_sampling);
metadata.contact_node_count = nnz(metadata.mask_xz);
metadata.polarization_xz = bank.vibrators(representative).polarization_xz;
metadata.nominal_propagation_xz = ...
    bank.vibrators(representative).propagation_xz;
metadata.target_angle_deg = bank.target_angle_deg;
metadata.target_direction_xz = bank.target_direction_xz;
metadata.f0_hz = cfg.source.f0_hz;
metadata.phase_rad = bank.vibrators(representative).phase_rad;
metadata.velocity_amplitude_m_s = ...
    bank.vibrators(representative).peak_velocity_m_s;
metadata.requested_drive_rms_squared_m2_s2 = ...
    bank.requested_drive_rms_squared_m2_s2;
metadata.realized_drive_rms_squared_m2_s2 = ...
    bank.total_drive_rms_squared_m2_s2;
metadata.drive_power_relative_error = bank.drive_power_relative_error;
metadata.drive_definition = ...
    "sum over active nodes of peak velocity^2 / 2, in m^2/s^2";
metadata.t_s = t_s;
metadata.envelope = envelope;
metadata.scalar_waveforms_m_s = scalar_waveforms_m_s;
metadata.lateral_solver_channel_waveforms_m_s = ux_m_s;
metadata.axial_solver_channel_waveforms_m_s = uz_m_s;
% Retain a representative scalar waveform for existing diagnostic figures.
metadata.waveform_m_s = double(scalar_waveforms_m_s(representative, :));

end
