function drive = fromLegacy(cfg)
%FROMLEGACY Adapt legacy cfg.wavefield.frequency_hz to the V2 drive.
% Does not mutate or validate the complete legacy simulation config.
arguments
    cfg (1,1) struct
end
if ~isfield(cfg,"wavefield") || ~isstruct(cfg.wavefield) || ...
        ~isscalar(cfg.wavefield) || ...
        ~isfield(cfg.wavefield,"frequency_hz")
    error("swsynth:LegacyHarmonicFrequencyMissing", ...
        "Legacy cfg.wavefield.frequency_hz is required.");
end
request=struct("frequency_hz",cfg.wavefield.frequency_hz);
if isfield(cfg.wavefield,"quantity")
    request.quantity=cfg.wavefield.quantity;
end
drive=swsynth.excitation.resolve(request);
end
