function cfg = configureSingleContact(cfg, options)
%CONFIGURESINGLECONTACT Configure one external prescribed-velocity contact.
%
% Contact geometry is selected separately with configurePointContact or
% configureFiniteContact.

arguments
    cfg struct

    options.Side (1,1) string {mustBeMember(options.Side, ...
        ["left"])} = "left"

    options.VelocityAmplitudeMPerS (1,1) double ...
        {mustBePositive} = 1e-6

    options.PhaseRad (1,1) double {mustBeFinite} = 0
end

cfg.source.layout = "single_contact";
cfg.source.side = options.Side;
cfg.source.regime = "single";
cfg.source.vibrator_count = 1;
cfg.source.target_angle_deg = 0;
cfg.source.coherent_power_fraction = 1;
cfg.source.velocity_amplitude_m_s = ...
    options.VelocityAmplitudeMPerS;
cfg.source.phase_rad = options.PhaseRad;

end
