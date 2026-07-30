function [referenceCsMps, diagnostics] = ...
        resolveReferenceSpeeds(csMapZX, directionsXYZ)
%RESOLVEREFERENCESPEEDS Assign one incident speed per direction.
%
% The projected-3D Eikonal model uses a deterministic upstream-corner
% boundary reference. For each propagation direction:
%
%   ux >= 0 -> x = xmin
%   ux <  0 -> x = xmax
%   uz >= 0 -> z = zmin
%   uz <  0 -> z = zmax
%
% The reference shear-wave speed is sampled from csMapZX at that upstream
% corner.
%
% csMapZX follows the public orientation U(z,x).
% directionsXYZ must have size N-by-3.

validateattributes( ...
    csMapZX, ...
    {'numeric'}, ...
    {'2d', 'nonempty', 'real', 'finite', 'positive'});

validateattributes( ...
    directionsXYZ, ...
    {'numeric'}, ...
    {'2d', 'nonempty', 'real', 'finite'});

if size(directionsXYZ, 2) ~= 3
    error( ...
        "swsynth:Projected3DDirectionShape", ...
        "directionsXYZ must have size N-by-3.");
end

directionsXYZ = double(directionsXYZ);
csMapZX = double(csMapZX);

directionNorms = vecnorm(directionsXYZ, 2, 2);

if any(directionNorms <= eps)
    error( ...
        "swsynth:InvalidProjected3DDirection", ...
        "Every direction must have nonzero magnitude.");
end

unitDirectionsXYZ = ...
    directionsXYZ ./ directionNorms;

directionCount = size(unitDirectionsXYZ, 1);

upstreamXIndex = ones(directionCount, 1);
upstreamZIndex = ones(directionCount, 1);

upstreamXIndex(unitDirectionsXYZ(:,1) < 0) = ...
    size(csMapZX, 2);

upstreamZIndex(unitDirectionsXYZ(:,3) < 0) = ...
    size(csMapZX, 1);

linearIndex = sub2ind( ...
    size(csMapZX), ...
    upstreamZIndex, ...
    upstreamXIndex);

referenceCsMps = csMapZX(linearIndex);
referenceCsMps = referenceCsMps(:);

diagnostics = struct();
diagnostics.model = "upstream_corner_reference_speed";
diagnostics.reference_cs_m_s = referenceCsMps;
diagnostics.upstream_x_index = upstreamXIndex;
diagnostics.upstream_z_index = upstreamZIndex;
diagnostics.unit_directions_xyz = unitDirectionsXYZ;
diagnostics.unique_reference_cs_m_s = ...
    unique(referenceCsMps, "stable");

end
