function wavefield = synthesizeProjected3DEikonal(cfg, maps, directions)
%SYNTHESIZEPROJECTED3DEIKONAL Legacy compatibility entrypoint.
% Projected 3D directional propagation is implemented under plane_wave.
arguments
    cfg (1,1) struct
    maps (1,1) struct
    directions (1,1) struct
end
wavefield = swsynth.propagation.plane_wave.synthesizeProjected3D( ...
    cfg, maps, directions);
end
