function field = synthesize2D(cfg, maps, directions)
%SYNTHESIZE2D Planar observation of a 3D point-force shear field.
% All source and observation y coordinates must match.
[cfg, ~] = swsynth.validateConfig(cfg);
if cfg.directions.space ~= "two_dimensional"
    error("swsynth:PointSource2DRequiresPlanarDirections", ...
        "2D point-source synthesis requires two_dimensional directions.");
end
if ~isempty(cfg.sources.position_xyz_m) && ...
        any(abs(cfg.sources.position_xyz_m(:,2)-cfg.domain.observation_y_m)>1e-12)
    error("swsynth:PointSource2DRequiresPlanarPositions", ...
        "Point-source positions must lie in the observation plane.");
end
field = swsynth.synthesizeWavefield2D(cfg,maps,directions);
end
