function [tau,diagnostics,solver] = compute(request)
%COMPUTE Analytical travel times for homogeneous incident plane waves.
if string(request.model) ~= "plane_wave"
    error("swsynth:PhaseRoutingUnsupported", ...
        "Analytical phase contract currently supports plane_wave only.");
end
geometry = string(request.geometry);
solver = swsynth.phase.validateCompatibility( ...
    "plane_wave","analytical",geometry,false);
need(request,["direction_xyz","reference_cs_m_s","x_m","z_m"]);
d = double(request.direction_xyz(:).');
cs = double(request.reference_cs_m_s);
if numel(d)~=3 || any(~isfinite(d)) || norm(d)<=0 || ...
        ~isscalar(cs) || ~isfinite(cs) || cs<=0
    error("swsynth:InvalidPhaseRequest","Invalid direction or reference speed.");
end
d=d/norm(d);
switch geometry
    case "volumetric3d"
        need(request,["y_m"]);
        tau=swsynth.phase.analytical.volumetric3d.computeTravelTime( ...
            request.x_m,request.y_m,request.z_m,d,cs);
    case "projected3d"
        tau=swsynth.phase.analytical.projected3d.computeTravelTime( ...
            request.x_m,request.z_m,d,cs);
    case "2d"
        tau=swsynth.phase.analytical.planar2d.computeTravelTime( ...
            request.x_m,request.z_m,d,cs);
end
mediumField = "cs_map_zx";
if geometry=="volumetric3d"
    mediumField = "cs_map_zyx";
end
if isfield(request,mediumField)
    values=double(request.(mediumField));
    if any(~isfinite(values(:))) || any(values(:)<=0) || ...
            max(abs(values(:)-cs))>1e-10*max(1,cs)
        error("swsynth:AnalyticalRequiresHomogeneousMedium", ...
            "Analytical phase requires a medium uniform at reference_cs_m_s.");
    end
end
diagnostics=struct("method","homogeneous_exact","reference_cs_m_s",cs);
end

function need(request,keys)
for key=keys
    if ~isfield(request,key)
        error("swsynth:PhaseRequestMissingField","Missing %s.",key);
    end
end
end
