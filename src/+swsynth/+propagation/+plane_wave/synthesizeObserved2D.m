function field = synthesizeObserved2D(cfg, maps, directions)
%SYNTHESIZEOBSERVED2D Backward-compatible plane-wave observation entrypoint.
field = swsynth.synthesizeWavefield2D(cfg,maps,directions);
end
