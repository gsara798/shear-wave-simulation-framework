function directions = generate(cfg)
%GENERATE Canonical direction-generation entry for the modular pipeline.
% Preserves the existing swsynth.generateDirections sampling and RNG logic.
arguments
    cfg (1,1) struct
end
directions = swsynth.generateDirections(cfg);
end
