function wavefield = synthesizeProjected3D(cfg,maps,directions)
%SYNTHESIZEPROJECTED3D Dispatch projected 3D plane-wave phase algorithms.
% Projected 3D uses 3D incident directions observed on an x-z slice.
arguments
    cfg (1,1) struct
    maps (1,1) struct
    directions (1,1) struct
end
[cfg,~] = swsynth.validateConfig(cfg);
if cfg.directions.space ~= "three_dimensional"
    error("swsynth:Projected3DRequiresThreeDimensions", ...
        "Projected 3D requires directions.space=three_dimensional.");
end
if cfg.propagation.model == "projected3d_eikonal"
    % Historical configuration represents plane-wave projected eikonal.
    solver = "projected3d_directional_eikonal";
elseif cfg.propagation.model == "plane_wave"
    solver = swsynth.phase.validateCompatibility( ...
        "plane_wave",cfg.propagation.phase_model,"projected3d", ...
        ~isempty(cfg.medium.objects));
else
    error("swsynth:PhaseRoutingUnsupported", ...
        "Projected 3D requires plane_wave propagation.");
end
switch solver
    case "homogeneous_projected_3d"
        wavefield = swsynth.propagation.plane_wave.synthesize2D( ...
            cfg,maps,directions);
    case "projected3d_directional_eikonal"
        wavefield = swsynth.propagation.plane_wave.synthesizeProjected3DEikonal( ...
            cfg,maps,directions);
    otherwise
        error("swsynth:PhaseRoutingUnsupported", ...
            "Unsupported projected 3D phase solver: %s",solver);
end
end
