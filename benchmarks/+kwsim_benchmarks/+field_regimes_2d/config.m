function cfg = config(regime)
%CONFIG Reference configuration for one 2D shear-field regime.
%
% cfg = kwsim_benchmarks.field_regimes_2d.config("directional")
% cfg = kwsim_benchmarks.field_regimes_2d.config("partially_diffuse")
% cfg = kwsim_benchmarks.field_regimes_2d.config("diffuse")
%
% Acceptance benchmarks use a homogeneous medium so source-generated
% directionality is not confounded by material scattering.

arguments
    regime (1,1) string {mustBeMember(regime, ...
        ["directional", "partially_diffuse", "diffuse"])} = ...
        "directional"
end

cfg = kwsim.two_d.defaultConfig();

cfg.scenario = "field_regimes_" + regime;

% This benchmark seed passed the same stationarity gates applied to user
% seeds and provides reproducible perimeter layouts.
cfg.seed = 1002;

switch regime
    case "directional"
        vibrator_count = 12;

    case "partially_diffuse"
        vibrator_count = 24;

    case "diffuse"
        vibrator_count = 24;

        % The random perimeter field needs one additional settling cycle.
        cfg.time.settling_cycles = 3;
end

cfg = kwsim.sources.configureVibratorBank( ...
    cfg, regime, vibrator_count);

cfg = kwsim.sources.configurePointContact( ...
    cfg, ContactRadiusM=1e-3);

% Retain the validated three-cycle cosine ramp.
cfg.source.ramp_cycles = 3;
cfg.sensor.boundary_margin_m = 4e-3;

end
