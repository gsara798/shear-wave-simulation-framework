function [tau,diagnostics,solver] = compute(request)
%COMPUTE Geometry-selected directional Eikonal travel time.
if string(request.model) ~= "plane_wave"
    error("swsynth:PhaseRoutingUnsupported", ...
        "Point-source Eikonal is not implemented by this contract.");
end
geometry=string(request.geometry);
solver=swsynth.phase.validateCompatibility("plane_wave","eikonal",geometry,false);
need(request,["direction_xyz","reference_cs_m_s","x_m","z_m"]);
options=struct();
if isfield(request,"solver_options")
    options=request.solver_options;
end
switch geometry
    case "projected3d"
        need(request,["cs_map_zx"]);
        [tau,diagnostics] = ...
            swsynth.propagation.projected3d.computeDirectionalPhaseDelay( ...
                request.cs_map_zx,request.x_m,request.z_m, ...
                request.direction_xyz,request.reference_cs_m_s,options);
    case "volumetric3d"
        need(request,["cs_map_zyx","y_m"]);
        [tau,diagnostics] = ...
            swsynth.propagation.volumetric3d.computeDirectionalTravelTime( ...
                request.cs_map_zyx,request.x_m,request.y_m,request.z_m, ...
                request.direction_xyz,request.reference_cs_m_s,options);
    otherwise
        error("swsynth:PhaseRoutingUnsupported", ...
            "Eikonal not implemented for geometry %s.",geometry);
end
end

function need(request,keys)
for key=keys
    if ~isfield(request,key)
        error("swsynth:PhaseRequestMissingField","Missing %s.",key);
    end
end
end
