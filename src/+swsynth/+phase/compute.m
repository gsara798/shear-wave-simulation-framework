function result = compute(request)
%COMPUTE Compute one component's propagation travel time (seconds).
% Contract fields:
%   model: "plane_wave" or "spherical_wave"
%   method: "analytical" or "eikonal"
%   geometry: "2d", "projected3d", "volumetric3d"
%   direction_xyz: 1x3 for plane waves
%   source_xyz_m / target_xyz_m: homogeneous spherical ray positions
%   reference_cs_m_s: homogeneous spherical or plane-wave reference speed
%   x_m, z_m, cs_map_zx for planar observations
%   y_m, cs_map_zyx for volumetric observations
%   reference_cs_m_s: incident/reference speed for plane waves
%   Spherical analytical T=|target-source|/cs is additive; existing
%   plane-wave analytical/eikonal routes remain unchanged.
%
% Output travel_time_s is a spatial array (zx or zyx), or Nx1 for rays.
% This API does not compute excitation, polarization, amplitude or noise.
arguments
    request (1,1) struct
end
required = ["model","method","geometry"];
for key = required
    if ~isfield(request,key)
        error("swsynth:PhaseRequestMissingField","Missing phase request field %s.",key);
    end
end
model = string(request.model);
method = string(request.method);
geometry = string(request.geometry);
switch method
    case {"analytical","homogeneous_analytic"}
        [tau,details,solver] = swsynth.phase.analytical.compute(request);
    case "eikonal"
        [tau,details,solver] = swsynth.phase.eikonal.compute(request);
    otherwise
        error("swsynth:PhaseRoutingUnsupported", ...
            "Unknown phase method %s.",method);
end
result = struct("travel_time_s",tau,"solver",solver, ...
    "method",method,"geometry",geometry,"model",model, ...
    "diagnostics",details);
end
