function [travelTimeZYX, diagnostics] = computeDirectionalTravelTime( ...
    csMapZYX, xM, yM, zM, directionXYZ, referenceCsMps, solverOptions)
%COMPUTEDIRECTIONALTRAVELTIME Solve a directional volumetric Eikonal field.
%
% Solves |grad(T)| = 1/c(x,y,z) using an incident plane-wave boundary
% condition. Travel time is referenced to the common spatial origin
% (0,0,0). Arrays follow [Nz, Ny, Nx].

if nargin < 7 || isempty(solverOptions)
    solverOptions = struct();
end

validateattributes(csMapZYX, {'numeric'}, ...
    {'3d','nonempty','real','finite','positive'});

xM = double(xM(:).');
yM = double(yM(:).');
zM = double(zM(:).');
csMapZYX = double(csMapZYX);
expectedSize = [numel(zM), numel(yM), numel(xM)];
if ~isequal(size(csMapZYX), expectedSize)
    error("swsynth:VolumetricMapSizeMismatch", ...
        "csMapZYX must have size [Nz Ny Nx].");
end

[initialTime, fixedMask, boundaryDiagnostics] = ...
    swsynth.propagation.volumetric3d.buildIncidentBoundaryCondition( ...
        xM, yM, zM, directionXYZ, referenceCsMps);

uniformCs = mean(csMapZYX(:));
uniformTolerance = 1e-12 * max(1, abs(uniformCs));
referenceTolerance = 1e-12 * max([1, abs(uniformCs), abs(referenceCsMps)]);
isUniform = max(abs(csMapZYX(:) - uniformCs)) <= uniformTolerance;
referenceMatches = abs(uniformCs - referenceCsMps) <= referenceTolerance;

d = double(directionXYZ(:)).';
d = d / norm(d);

if isUniform && referenceMatches
    [Z, Y, X] = ndgrid(zM, yM, xM);
    travelTimeZYX = (d(1).*X + d(2).*Y + d(3).*Z) ./ referenceCsMps;
    solverDiagnostics = struct( ...
        "method", "homogeneous_exact_3d", ...
        "converged", true, ...
        "iterations", 0, ...
        "last_change_s", 0, ...
        "finite_fraction", 1, ...
        "grid_size_zyx", expectedSize);
else
    dxM = uniformSpacing(xM, "x");
    dyM = uniformSpacing(yM, "y");
    dzM = uniformSpacing(zM, "z");
    slowness = 1 ./ csMapZYX;
    [travelTimeZYX, solverDiagnostics] = ...
        swsynth.numerics.eikonal.solveFastSweeping3D( ...
            slowness, dxM, dyM, dzM, initialTime, fixedMask, solverOptions);
    if ~solverDiagnostics.converged
        error("swsynth:Volumetric3DEikonalDidNotConverge", ...
            ["Volumetric 3D Eikonal did not converge after %d iterations. " + ...
             "Last change = %.6e s."], ...
            solverDiagnostics.iterations, solverDiagnostics.last_change_s);
    end
end

diagnostics = struct();
diagnostics.model = "volumetric_directional_eikonal";
diagnostics.direction_xyz = d;
diagnostics.reference_cs_m_s = referenceCsMps;
diagnostics.boundary = boundaryDiagnostics;
diagnostics.solver = solverDiagnostics;

end

function spacing = uniformSpacing(axisValues, axisName)
if numel(axisValues) < 2
    error("swsynth:VolumetricGridTooSmall", ...
        "Axis %s requires at least two samples.", axisName);
end
increments = diff(axisValues);
spacing = mean(increments);
tolerance = 1e-10 * max(1, abs(spacing));
if any(increments <= 0) || max(abs(increments-spacing)) > tolerance
    error("swsynth:VolumetricNonuniformGrid", ...
        "Axis %s must be uniformly increasing.", axisName);
end
end
