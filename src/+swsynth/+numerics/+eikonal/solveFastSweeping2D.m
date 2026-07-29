function [travelTimeZX, diagnostics] = solveFastSweeping2D( ...
    slownessZX, dxM, dzM, initialTimeZX, fixedMaskZX, options)
%SOLVEFASTSWEEPING2D Solve |grad(T)| = slowness on an x-z grid.
%
% Arrays use public orientation [Nz, Nx].
%
% fixedMaskZX marks Dirichlet nodes whose values in initialTimeZX are
% preserved. Non-fixed initial values may be finite upper bounds or Inf.
%
% This is an internal numerical kernel. It does not define source geometry
% or a public 2D propagation model.

if nargin < 6 || isempty(options)
    options = struct();
end

validateInputs( ...
    slownessZX, dxM, dzM, initialTimeZX, fixedMaskZX);

maximumIterations = getOption( ...
    options, "MaximumIterations", 200);

toleranceS = getOption( ...
    options, "ToleranceS", 1e-10);

verbose = logical(getOption( ...
    options, "Verbose", false));

validateattributes( ...
    maximumIterations, ...
    {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'});

validateattributes( ...
    toleranceS, ...
    {'numeric'}, ...
    {'scalar', 'nonnegative', 'finite'});

slownessZX = double(slownessZX);
travelTimeZX = double(initialTimeZX);
fixedMaskZX = logical(fixedMaskZX);

[Nz, Nx] = size(slownessZX);

rowOrders = {
    1:Nz
    Nz:-1:1
    1:Nz
    Nz:-1:1
};

columnOrders = {
    1:Nx
    1:Nx
    Nx:-1:1
    Nx:-1:1
};

inverseDxSquared = 1 / dxM^2;
inverseDzSquared = 1 / dzM^2;
quadraticCoefficient = ...
    inverseDxSquared + inverseDzSquared;

lastChangeS = Inf;
converged = false;

for iteration = 1:maximumIterations
    previousTimeZX = travelTimeZX;
    previousFullyFinite = all(isfinite(previousTimeZX(:)));

    for sweepIndex = 1:4
        rows = rowOrders{sweepIndex};
        columns = columnOrders{sweepIndex};

        for zIndex = rows
            for xIndex = columns
                if fixedMaskZX(zIndex, xIndex)
                    continue;
                end

                minimumXNeighbor = Inf;
                minimumZNeighbor = Inf;

                if xIndex > 1
                    minimumXNeighbor = min( ...
                        minimumXNeighbor, ...
                        travelTimeZX(zIndex, xIndex - 1));
                end

                if xIndex < Nx
                    minimumXNeighbor = min( ...
                        minimumXNeighbor, ...
                        travelTimeZX(zIndex, xIndex + 1));
                end

                if zIndex > 1
                    minimumZNeighbor = min( ...
                        minimumZNeighbor, ...
                        travelTimeZX(zIndex - 1, xIndex));
                end

                if zIndex < Nz
                    minimumZNeighbor = min( ...
                        minimumZNeighbor, ...
                        travelTimeZX(zIndex + 1, xIndex));
                end

                candidateTime = localUpwindUpdate( ...
                    minimumXNeighbor, ...
                    minimumZNeighbor, ...
                    slownessZX(zIndex, xIndex), ...
                    dxM, ...
                    dzM, ...
                    inverseDxSquared, ...
                    inverseDzSquared, ...
                    quadraticCoefficient);

                if candidateTime < travelTimeZX(zIndex, xIndex)
                    travelTimeZX(zIndex, xIndex) = candidateTime;
                end
            end
        end
    end

    currentFullyFinite = all(isfinite(travelTimeZX(:)));

    % Newly finite nodes were Inf in the previous iteration and cannot be
    % included in a finite difference. Require another complete sweep cycle
    % before convergence may be declared.
    if previousFullyFinite && currentFullyFinite
        lastChangeS = max(abs( ...
            travelTimeZX(:) - previousTimeZX(:)));
    else
        lastChangeS = Inf;
    end

    if verbose
        fprintf( ...
            "Fast-sweeping iteration %d: max change = %.6e s\n", ...
            iteration, ...
            lastChangeS);
    end

    if currentFullyFinite && lastChangeS <= toleranceS
        converged = true;
        break;
    end
end

diagnostics = struct();
diagnostics.iterations = iteration;
diagnostics.converged = converged;
diagnostics.last_change_s = lastChangeS;
diagnostics.maximum_iterations = maximumIterations;
diagnostics.tolerance_s = toleranceS;
diagnostics.finite_fraction = ...
    nnz(isfinite(travelTimeZX)) / numel(travelTimeZX);
diagnostics.grid_size_zx = [Nz, Nx];

end

function candidateTime = localUpwindUpdate( ...
    neighborX, neighborZ, localSlowness, ...
    dxM, dzM, inverseDxSquared, inverseDzSquared, ...
    quadraticCoefficient)

candidateTime = Inf;

if isfinite(neighborX)
    candidateTime = min( ...
        candidateTime, ...
        neighborX + localSlowness * dxM);
end

if isfinite(neighborZ)
    candidateTime = min( ...
        candidateTime, ...
        neighborZ + localSlowness * dzM);
end

if ~(isfinite(neighborX) && isfinite(neighborZ))
    return;
end

weightedNeighbor = ...
    neighborX * inverseDxSquared + ...
    neighborZ * inverseDzSquared;

constantTerm = ...
    neighborX^2 * inverseDxSquared + ...
    neighborZ^2 * inverseDzSquared - ...
    localSlowness^2;

discriminant = ...
    weightedNeighbor^2 - ...
    quadraticCoefficient * constantTerm;

if discriminant < 0
    return;
end

quadraticCandidate = ...
    (weightedNeighbor + sqrt(discriminant)) / ...
    quadraticCoefficient;

if quadraticCandidate >= max(neighborX, neighborZ)
    candidateTime = min(candidateTime, quadraticCandidate);
end

end

function validateInputs( ...
    slownessZX, dxM, dzM, initialTimeZX, fixedMaskZX)

validateattributes( ...
    slownessZX, ...
    {'numeric'}, ...
    {'2d', 'nonempty', 'real', 'finite', 'nonnegative'});

validateattributes( ...
    dxM, ...
    {'numeric'}, ...
    {'scalar', 'positive', 'finite'});

validateattributes( ...
    dzM, ...
    {'numeric'}, ...
    {'scalar', 'positive', 'finite'});

if ~isequal(size(initialTimeZX), size(slownessZX))
    error( ...
        "swsynth:EikonalInitialTimeSizeMismatch", ...
        "initialTimeZX must have the same size as slownessZX.");
end

if ~isequal(size(fixedMaskZX), size(slownessZX))
    error( ...
        "swsynth:EikonalFixedMaskSizeMismatch", ...
        "fixedMaskZX must have the same size as slownessZX.");
end

if any(isnan(initialTimeZX(:))) || ...
        any(initialTimeZX(:) == -Inf)
    error( ...
        "swsynth:InvalidEikonalInitialTime", ...
        "initialTimeZX may contain finite values or positive Inf.");
end

fixedMaskZX = logical(fixedMaskZX);

if ~any(fixedMaskZX(:))
    error( ...
        "swsynth:EikonalMissingBoundaryCondition", ...
        "At least one fixed travel-time node is required.");
end

if any(~isfinite(initialTimeZX(fixedMaskZX)))
    error( ...
        "swsynth:InvalidEikonalFixedTime", ...
        "All fixed travel-time values must be finite.");
end

end

function value = getOption(options, name, defaultValue)

if isfield(options, name) && ~isempty(options.(name))
    value = options.(name);
else
    value = defaultValue;
end

end
