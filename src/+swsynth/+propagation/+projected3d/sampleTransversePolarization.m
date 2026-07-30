function [polarizationXYZ, diagnostics] = ...
        sampleTransversePolarization(directionsXYZ)
%SAMPLETRANSVERSEPOLARIZATION Random shear polarization vectors.
%
% For every propagation direction u, generate a random unit polarization p
% satisfying
%
%   dot(p, u) = 0
%   norm(p)   = 1
%
% A projected isotropic Gaussian vector produces a uniform polarization
% angle in the two-dimensional plane perpendicular to u.
%
% directionsXYZ must have size N-by-3.

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

directionNorms = sqrt(sum(directionsXYZ.^2, 2));

if any(directionNorms <= eps)
    error( ...
        "swsynth:InvalidProjected3DDirection", ...
        "Every direction must have nonzero magnitude.");
end

unitDirectionsXYZ = ...
    directionsXYZ ./ directionNorms;

directionCount = size(unitDirectionsXYZ, 1);

randomVectorsXYZ = randn(directionCount, 3);

parallelCoefficient = sum( ...
    randomVectorsXYZ .* unitDirectionsXYZ, ...
    2);

transverseVectorsXYZ = ...
    randomVectorsXYZ - ...
    parallelCoefficient .* unitDirectionsXYZ;

transverseNorms = sqrt(sum( ...
    transverseVectorsXYZ.^2, ...
    2));

degenerateMask = transverseNorms <= 1e-12;

degenerateIndices = find(degenerateMask);

for index = degenerateIndices(:).'
    direction = unitDirectionsXYZ(index, :);

    [~, fallbackAxis] = min(abs(direction));

    fallback = zeros(1, 3);
    fallback(fallbackAxis) = 1;

    transverseVectorsXYZ(index, :) = ...
        fallback - dot(fallback, direction) .* direction;

    transverseNorms(index) = norm( ...
        transverseVectorsXYZ(index, :));
end

polarizationXYZ = ...
    transverseVectorsXYZ ./ transverseNorms;

orthogonalityError = abs(sum( ...
    polarizationXYZ .* unitDirectionsXYZ, ...
    2));

polarizationNormError = abs( ...
    sqrt(sum(polarizationXYZ.^2, 2)) - 1);

diagnostics = struct();
diagnostics.direction_count = directionCount;
diagnostics.unit_directions_xyz = unitDirectionsXYZ;
diagnostics.axial_component = polarizationXYZ(:, 3);
diagnostics.axial_power = polarizationXYZ(:, 3).^2;

% Expected axial power for a uniformly random polarization angle:
%
%   E[p_z^2 | u] = (1 - u_z^2)/2.
diagnostics.expected_axial_power = ...
    (1 - unitDirectionsXYZ(:, 3).^2) ./ 2;

diagnostics.maximum_orthogonality_error = ...
    max(orthogonalityError);

diagnostics.maximum_norm_error = ...
    max(polarizationNormError);

diagnostics.degenerate_fallback_count = ...
    nnz(degenerateMask);

end
