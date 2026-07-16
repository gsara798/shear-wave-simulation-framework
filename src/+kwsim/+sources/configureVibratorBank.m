function cfg = configureVibratorBank( ...
    cfg, regime, vibrator_count, options)
%CONFIGUREVIBRATORBANK Configure a reusable perimeter vibrator bank.
%
% cfg = kwsim.sources.configureVibratorBank( ...
%     cfg, regime, vibrator_count)
%
% The field regime and contact geometry are independent. Call
% configurePointContact or configureFiniteContact after this function to
% select how each physical vibrator is spatially represented.

arguments
    cfg struct

    regime (1,1) string {mustBeMember(regime, ...
        ["directional", "partially_diffuse", "diffuse"])}

    vibrator_count (1,1) double {mustBeInteger, mustBePositive}

    options.TargetAngleDeg (1,1) double {mustBeFinite} = 0

    options.CoherentPowerFraction (1,1) double = NaN

    options.TotalDriveRmsSquaredM2S2 (1,1) double = NaN
end

switch regime
    case "directional"
        default_fraction = 1;

    case "partially_diffuse"
        default_fraction = 0.5;

    case "diffuse"
        default_fraction = 0;
end

fraction = options.CoherentPowerFraction;

if isnan(fraction)
    fraction = default_fraction;
end

if ~isfinite(fraction) || fraction < 0 || fraction > 1
    error( ...
        'kwsim:InvalidSourceConfiguration', ...
        'CoherentPowerFraction must lie in [0, 1].');
end

if regime == "directional" && fraction ~= 1
    error( ...
        'kwsim:InvalidSourceConfiguration', ...
        'A directional bank must have CoherentPowerFraction equal to 1.');
end

if regime == "diffuse" && fraction ~= 0
    error( ...
        'kwsim:InvalidSourceConfiguration', ...
        'A diffuse bank must have CoherentPowerFraction equal to 0.');
end

cfg.source.layout = "vibrator_bank";
cfg.source.regime = regime;
cfg.source.vibrator_count = vibrator_count;
cfg.source.target_angle_deg = options.TargetAngleDeg;
cfg.source.coherent_power_fraction = fraction;

requested_drive = options.TotalDriveRmsSquaredM2S2;

if ~isnan(requested_drive)
    if ~isfinite(requested_drive) || requested_drive <= 0
        error( ...
            'kwsim:InvalidSourceConfiguration', ...
            'TotalDriveRmsSquaredM2S2 must be positive.');
    end

    cfg.source.total_drive_rms_squared_m2_s2 = ...
        requested_drive;
end

end
