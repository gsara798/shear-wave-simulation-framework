function field = synthesizeProjected3D(cfg, maps, directions)
%SYNTHESIZEPROJECTED3D 3D point forces sampled on an x-z observation plane.
% Use the established numerical path, retaining its RNG and precision.
[cfg, ~] = swsynth.validateConfig(cfg);
field = swsynth.synthesizeWavefield2D(cfg,maps,directions);
end
