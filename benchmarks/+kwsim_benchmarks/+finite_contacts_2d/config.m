function cfg = config(regime)
%CONFIG Reference configuration with finite external vibrator contacts.
%
% Each physical vibrator is a tangential perimeter segment. Its active
% nodes share phase and polarization but receive independently weighted
% solver channels.

arguments
    regime (1,1) string {mustBeMember(regime, ...
        ["directional", "partially_diffuse", "diffuse"])} = ...
        "directional"
end

cfg = kwsim.two_d.defaultConfig();

cfg.scenario = "finite_contacts_" + regime;
cfg.seed = 1002;

switch regime
    case "directional"
        vibrator_count = 8;

    case "partially_diffuse"
        vibrator_count = 16;

    case "diffuse"
        vibrator_count = 16;

        % Finite diffuse contacts require additional settling.
        cfg.time.settling_cycles = 6;
end

cfg = kwsim.sources.configureVibratorBank( ...
    cfg, regime, vibrator_count);

cfg = kwsim.sources.configureFiniteContact( ...
    cfg, ...
    ContactRadiusM=2e-3, ...
    NodeSpacingPoints=4, ...
    Profile="raised_cosine");

cfg.source.ramp_cycles = 3;
cfg.sensor.boundary_margin_m = 4e-3;

end
