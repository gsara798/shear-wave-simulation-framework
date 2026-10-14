function fieldXZ = synthesizeHomogeneousFieldXZ( ...
        kMapZX, x, z, ux, uy, uz, observationY, weights, useParallel)
%SYNTHESIZEHOMOGENEOUSFIELDXZ Accumulate analytic directional plane waves.
% Internal numerical kernel. Array order here is XZ, then caller converts
% to public ZX. Inputs, single-precision accumulation and loop order are
% preserved from the legacy swsynth.synthesizeWavefield2D implementation.

N = numel(weights);
Nx = numel(x);
Nz = numel(z);
fieldXZ = complex(zeros(Nx, Nz, "single"));

referenceK = double(kMapZX(1,1));
relativeVariation = ...
    max(abs(kMapZX(:) - referenceK)) / ...
    max(abs(referenceK), eps);

if relativeVariation > 1e-9
    error("swsynth:PlaneWaveRequiresHomogeneousMedium", ...
        "plane_wave requires a spatially uniform wavenumber map.");
end

parfor (zIndex = 1:Nz, parallelFlag(useParallel))
    column = complex(zeros(Nx, 1, "single"));
    xColumn = single(x(:));
    zValue = single(z(zIndex));

    for directionIndex = 1:N
        spatialPhase = referenceK * ( ...
            ux(directionIndex) * xColumn + ...
            uy(directionIndex) * observationY + ...
            uz(directionIndex) * zValue);

        column = column + ...
            weights(directionIndex) .* exp(1i * spatialPhase);
    end

    fieldXZ(:, zIndex) = column;
end
end

function flag = parallelFlag(useParallel)
if useParallel
    flag = Inf;
else
    flag = 0;
end
end
