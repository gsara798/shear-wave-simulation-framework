function [initialTimeZYX, fixedMaskZYX, diagnostics] = ...
    buildIncidentBoundaryCondition(xM, yM, zM, directionXYZ, referenceCsMps)
%BUILDINCIDENTBOUNDARYCONDITION Build plane-wave Dirichlet data for 3D Eikonal.
%
% The incident field is a plane wave with direction d and reference speed
% c_ref. To avoid artificial injection through lateral faces in heterogeneous
% media, Dirichlet values are imposed on one principal incident face: the
% upstream face normal to the largest-magnitude direction component.
%
% The phase ramp across that face preserves the full incident slowness
% vector. Travel time uses the common spatial phase origin (0,0,0), matching
% the analytical plane-wave convention. Arrays follow [Nz, Ny, Nx].

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
[~, principalAxis] = max(abs(d));

switch principalAxis
    case 1 % x-normal face
        if d(1) >= 0
            fixedMaskZYX(:,:,1) = true;
            incidentFace = "x_min";
        else
            fixedMaskZYX(:,:,end) = true;
            incidentFace = "x_max";
        end

    case 2 % y-normal face
        if d(2) >= 0
            fixedMaskZYX(:,1,:) = true;
            incidentFace = "y_min";
        else
            fixedMaskZYX(:,end,:) = true;
            incidentFace = "y_max";
        end

    case 3 % z-normal face
        if d(3) >= 0
            fixedMaskZYX(1,:,:) = true;
            incidentFace = "z_min";
        else
            fixedMaskZYX(end,:,:) = true;
            incidentFace = "z_max";
        end

    otherwise
        error("swsynth:VolumetricBoundaryConstructionFailure", ...
            "Could not identify a principal incident face.");
end

initialTimeZYX = Inf(Nz, Ny, Nx);
initialTimeZYX(fixedMaskZYX) = planeTime(fixedMaskZYX);

diagnostics = struct();
diagnostics.direction_xyz = d;
diagnostics.reference_cs_m_s = referenceCsMps;
diagnostics.incident_face = incidentFace;
diagnostics.principal_axis = principalAxis;
diagnostics.fixed_node_count = nnz(fixedMaskZYX);
diagnostics.fixed_fraction = nnz(fixedMaskZYX) / numel(fixedMaskZYX);
diagnostics.phase_reference_offset_s = 0;
diagnostics.phase_reference = "global_origin_x0_y0_z0";

end
