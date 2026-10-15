function out = synthesizeVolumetric3D(cfg, maps)
%SYNTHESIZEVOLUMETRIC3D Select volumetric plane-wave phase implementation.
arguments
    cfg (1,1) struct
    maps (1,1) struct
end
[cfg, ~] = swsynth.validateConfig3D(cfg);
if cfg.propagation.model ~= "plane_wave"
    error("swsynth:UnsupportedVolumetricPropagationModel", ...
        "synthesizeVolumetric3D requires plane_wave.");
end
solver = swsynth.phase.validateCompatibility( ...
    "plane_wave",cfg.propagation.phase_model,"volumetric3d", ...
    ~isempty(cfg.medium.objects));
switch solver
    case "homogeneous_plane_3d"
        out = swsynth.propagation.plane_wave.synthesizeVolumetricAnalytical3D(cfg);
    case "volumetric_eikonal_3d"
        out = swsynth.propagation.plane_wave.synthesizeVolumetricEikonal3D(cfg,maps);
    otherwise
        error("swsynth:PhaseRoutingUnsupported", ...
            "Unsupported volumetric phase solver: %s",solver);
end
end
