function solver = resolveSolver(model, phaseModel, geometry)
%RESOLVESOLVER Select the existing phase implementation from user intent.
% No physical method is silently substituted. Legacy naming is supported
% only where its historical numerical meaning is unambiguous.
model = string(model); phaseModel = string(phaseModel);
geometry = string(geometry);
if model ~= "plane_wave"
    error("swsynth:PhaseRoutingUnsupported", ...
        "Automatic phase routing currently supports plane_wave only.");
end
switch geometry
    case "volumetric3d"
        switch phaseModel
            case "homogeneous_analytic"
                solver = "homogeneous_plane_3d";
            case {"eikonal","volumetric_eikonal"}
                solver = "volumetric_eikonal_3d";
            otherwise
                error("swsynth:PhaseRoutingUnsupported", ...
                    "Unsupported phase_model '%s' for volumetric3d.",phaseModel);
        end
    case "projected3d"
        switch phaseModel
            case {"homogeneous_analytic","local_k_distance"}
                solver = "homogeneous_projected_3d";
            case "eikonal"
                solver = "projected3d_directional_eikonal";
            otherwise
                error("swsynth:PhaseRoutingUnsupported", ...
                    "Unsupported phase_model '%s' for projected3d.",phaseModel);
        end
    case "2d"
        switch phaseModel
            case {"homogeneous_analytic","local_k_distance"}
                solver = "homogeneous_plane_2d";
            otherwise
                error("swsynth:PhaseRoutingUnsupported", ...
                    "Unsupported phase_model '%s' for 2d.",phaseModel);
        end
    otherwise
        error("swsynth:InvalidObservationGeometry", ...
            "Unsupported observation geometry '%s'.",geometry);
end
end
