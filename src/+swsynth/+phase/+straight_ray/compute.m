function [tau,diagnostics,solver] = compute(request)
%COMPUTE Existing straight-ray point-source travel-time integration.
if string(request.model) ~= "spherical_wave" || ...
        ~ismember(string(request.geometry),["2d","projected3d"])
    error("swsynth:PhaseRoutingUnsupported", ...
        "Straight ray is currently implemented only for planar point sources.");
end
keys=["cfg","source_xyz_m","target_xyz_m"];
for key=keys
    if ~isfield(request,key)
        error("swsynth:PhaseRequestMissingField","Missing %s.",key);
    end
end
switch string(request.geometry)
    case "2d"
        [tau,diagnostics] = ...
            swsynth.phase.straight_ray.planar2d.computeTravelTime( ...
                request.cfg,request.source_xyz_m,request.target_xyz_m);
    case "projected3d"
        [tau,diagnostics] = ...
            swsynth.phase.straight_ray.projected3d.computeTravelTime( ...
                request.cfg,request.source_xyz_m,request.target_xyz_m);
end
solver="straight_ray_integral_2p5d";
end
