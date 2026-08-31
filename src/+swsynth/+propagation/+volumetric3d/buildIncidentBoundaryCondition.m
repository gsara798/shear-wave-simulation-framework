function [initialTimeZYX, fixedMaskZYX, diagnostics] = ...
    buildIncidentBoundaryCondition(xM, yM, zM, directionXYZ, referenceCsMps)
%BUILDINCIDENTBOUNDARYCONDITION Build upstream Dirichlet data for 3D Eikonal.
%
% The incident field is a plane wave with direction d and reference speed
% c_ref. Dirichlet values are applied on every upstream domain face touched
% by d. Travel time uses the common spatial phase origin (0,0,0), matching
% the analytical plane-wave backend. Arrays follow [Nz, Ny, Nx].

xM = double(xM(:).');
yM = double(yM(:).');
zM = double(zM(:).');
d = double(directionXYZ(:)).';

if numel(d) ~= 3 || any(~isfinite(d)) || norm(d) <= eps
    error("swsynth:InvalidVolumetricDirection", ...
        "directionXYZ must be a finite nonzero 3-vector.");
end
if ~isscalar(referenceCsMps) || ~isfinite(referenceCsMps) || referenceCsMps <= 0
    error("swsynth:InvalidVolumetricReferenceSpeed", ...
        "referenceCsMps must be a positive finite scalar.");
end

d = d / norm(d);
[Nz, Ny, Nx] = deal(numel(zM), numel(yM), numel(xM));
[Z, Y, X] = ndgrid(zM, yM, xM);
planeTime = (d(1).*X + d(2).*Y + d(3).*Z) ./ referenceCsMps;

fixedMaskZYX = false(Nz, Ny, Nx);
tol = 1e-12;

if d(1) > tol
    fixedMaskZYX(:,:,1) = true;
elseif d(1) < -tol
    fixedMaskZYX(:,:,end) = true;
end

if d(2) > tol
    fixedMaskZYX(:,1,:) = true;
elseif d(2) < -tol
    fixedMaskZYX(:,end,:) = true;
end

if d(3) > tol
    fixedMaskZYX(1,:,:) = true;
elseif d(3) < -tol
    fixedMaskZYX(end,:,:) = true;
end

if ~any(fixedMaskZYX(:))
    error("swsynth:VolumetricBoundaryConstructionFailure", ...
        "Could not identify an upstream boundary face.");
end

initialTimeZYX = Inf(Nz, Ny, Nx);
initialTimeZYX(fixedMaskZYX) = planeTime(fixedMaskZYX);

diagnostics = struct();
diagnostics.direction_xyz = d;
diagnostics.reference_cs_m_s = referenceCsMps;
diagnostics.fixed_node_count = nnz(fixedMaskZYX);
diagnostics.fixed_fraction = nnz(fixedMaskZYX) / numel(fixedMaskZYX);
diagnostics.phase_reference_offset_s = 0;
diagnostics.phase_reference = "global_origin_x0_y0_z0";

end
