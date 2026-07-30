function [initialTimeZX, fixedMaskZX, diagnostics] = ...
        buildIncidentBoundaryCondition( ...
            xM, zM, directionXYZ, referenceCsMps)
%BUILDINCIDENTBOUNDARYCONDITION Plane-wave inflow condition in x-z.
%
% directionXYZ is the three-dimensional propagation direction defined in
% the homogeneous reference medium.
%
% The absolute phase-delay reference is chosen at the upstream corner:
%
%   tau = px * (x - xRef) + pz * (z - zRef)
%
% where px = ux / referenceCsMps and pz = uz / referenceCsMps.
%
% Only the inflow boundaries are fixed. For a pure out-of-plane direction,
% the observed x-z phase is spatially constant and all nodes are fixed to 0.

validateattributes( ...
    xM, ...
    {'numeric'}, ...
    {'vector', 'nonempty', 'real', 'finite'});

validateattributes( ...
    zM, ...
    {'numeric'}, ...
    {'vector', 'nonempty', 'real', 'finite'});

validateattributes( ...
    directionXYZ, ...
    {'numeric'}, ...
    {'vector', 'numel', 3, 'real', 'finite'});

validateattributes( ...
    referenceCsMps, ...
    {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});

xM = double(xM(:).');
zM = double(zM(:));
directionXYZ = double(directionXYZ(:).');

if any(diff(xM) <= 0) || any(diff(zM) <= 0)
    error( ...
        "swsynth:InvalidProjected3DCoordinates", ...
        "xM and zM must be strictly increasing.");
end

directionNorm = norm(directionXYZ);

if directionNorm <= eps
    error( ...
        "swsynth:InvalidProjected3DDirection", ...
        "directionXYZ must have nonzero magnitude.");
end

unitDirectionXYZ = directionXYZ / directionNorm;

ux = unitDirectionXYZ(1);
uy = unitDirectionXYZ(2);
uz = unitDirectionXYZ(3);

projectedDirectionNorm = hypot(ux, uz);

Nz = numel(zM);
Nx = numel(xM);

initialTimeZX = Inf(Nz, Nx);
fixedMaskZX = false(Nz, Nx);

directionTolerance = 1e-12;

if projectedDirectionNorm <= directionTolerance
    initialTimeZX(:) = 0;
    fixedMaskZX(:) = true;

    diagnostics = makeDiagnostics( ...
        unitDirectionXYZ, ...
        referenceCsMps, ...
        0, ...
        0, ...
        "pure_out_of_plane", ...
        fixedMaskZX);

    return;
end

pxSPerM = ux / referenceCsMps;
pzSPerM = uz / referenceCsMps;

if ux >= 0
    referenceXM = xM(1);
else
    referenceXM = xM(end);
end

if uz >= 0
    referenceZM = zM(1);
else
    referenceZM = zM(end);
end

[X, Z] = meshgrid(xM, zM);

incidentTimeZX = ...
    pxSPerM .* (X - referenceXM) + ...
    pzSPerM .* (Z - referenceZM);

smallNegativeTolerance = ...
    100 * eps(max(1, max(abs(incidentTimeZX(:)))));

incidentTimeZX( ...
    incidentTimeZX < 0 & ...
    incidentTimeZX >= -smallNegativeTolerance) = 0;

if ux > directionTolerance
    fixedMaskZX(:, 1) = true;
elseif ux < -directionTolerance
    fixedMaskZX(:, end) = true;
end

if uz > directionTolerance
    fixedMaskZX(1, :) = true;
elseif uz < -directionTolerance
    fixedMaskZX(end, :) = true;
end

if ~any(fixedMaskZX(:))
    error( ...
        "swsynth:Projected3DMissingInflowBoundary", ...
        "No projected inflow boundary could be identified.");
end

initialTimeZX(fixedMaskZX) = ...
    incidentTimeZX(fixedMaskZX);

diagnostics = makeDiagnostics( ...
    unitDirectionXYZ, ...
    referenceCsMps, ...
    pxSPerM, ...
    pzSPerM, ...
    "directional_inflow", ...
    fixedMaskZX);

diagnostics.reference_x_m = referenceXM;
diagnostics.reference_z_m = referenceZM;

end

function diagnostics = makeDiagnostics( ...
    unitDirectionXYZ, referenceCsMps, ...
    pxSPerM, pzSPerM, mode, fixedMaskZX)

diagnostics = struct();
diagnostics.mode = mode;
diagnostics.unit_direction_xyz = unitDirectionXYZ;
diagnostics.reference_cs_m_s = referenceCsMps;
diagnostics.px_s_m = pxSPerM;
diagnostics.py_s_m = ...
    unitDirectionXYZ(2) / referenceCsMps;
diagnostics.pz_s_m = pzSPerM;
diagnostics.projected_direction_norm = ...
    hypot(unitDirectionXYZ(1), unitDirectionXYZ(3));
diagnostics.fixed_node_count = nnz(fixedMaskZX);

end
