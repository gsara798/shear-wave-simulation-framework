function [travelTimeZYX, diagnostics] = solveFastSweeping3D( ...
    slownessZYX, dxM, dyM, dzM, initialTimeZYX, fixedMaskZYX, options)
%SOLVEFASTSWEEPING3D Solve |grad(T)| = slowness on a 3D Cartesian grid.
%
% Arrays use public orientation [Nz, Ny, Nx]. fixedMaskZYX marks Dirichlet
% nodes whose initial travel times are preserved.

if nargin < 7 || isempty(options)
    options = struct();
end

validateInputs(slownessZYX, dxM, dyM, dzM, initialTimeZYX, fixedMaskZYX);

maximumIterations = getOption(options, "MaximumIterations", 200);
toleranceS = getOption(options, "ToleranceS", 1e-10);
verbose = logical(getOption(options, "Verbose", false));

validateattributes(maximumIterations, {'numeric'}, ...
    {'scalar','integer','positive','finite'});
validateattributes(toleranceS, {'numeric'}, ...
    {'scalar','nonnegative','finite'});

slownessZYX = double(slownessZYX);
travelTimeZYX = double(initialTimeZYX);
fixedMaskZYX = logical(fixedMaskZYX);
[Nz, Ny, Nx] = size(slownessZYX);

zOrders = {1:Nz, Nz:-1:1};
yOrders = {1:Ny, Ny:-1:1};
xOrders = {1:Nx, Nx:-1:1};

lastChangeS = Inf;
converged = false;

for iteration = 1:maximumIterations
    previous = travelTimeZYX;
    previousFullyFinite = all(isfinite(previous(:)));

    for sz = 1:2
        for sy = 1:2
            for sx = 1:2
                for iz = zOrders{sz}
                    for iy = yOrders{sy}
                        for ix = xOrders{sx}
                            if fixedMaskZYX(iz,iy,ix)
                                continue
                            end

                            ax = Inf; ay = Inf; az = Inf;
                            if ix > 1, ax = min(ax, travelTimeZYX(iz,iy,ix-1)); end
                            if ix < Nx, ax = min(ax, travelTimeZYX(iz,iy,ix+1)); end
                            if iy > 1, ay = min(ay, travelTimeZYX(iz,iy-1,ix)); end
                            if iy < Ny, ay = min(ay, travelTimeZYX(iz,iy+1,ix)); end
                            if iz > 1, az = min(az, travelTimeZYX(iz-1,iy,ix)); end
                            if iz < Nz, az = min(az, travelTimeZYX(iz+1,iy,ix)); end

                            candidate = localUpwindUpdate3D( ...
                                [ax ay az], [dxM dyM dzM], ...
                                slownessZYX(iz,iy,ix));
                            if candidate < travelTimeZYX(iz,iy,ix)
                                travelTimeZYX(iz,iy,ix) = candidate;
                            end
                        end
                    end
                end
            end
        end
    end

    currentFullyFinite = all(isfinite(travelTimeZYX(:)));
    if previousFullyFinite && currentFullyFinite
        lastChangeS = max(abs(travelTimeZYX(:) - previous(:)));
    else
        lastChangeS = Inf;
    end

    if verbose
        fprintf("3D fast-sweeping iteration %d: max change = %.6e s\n", ...
            iteration, lastChangeS);
    end

    if currentFullyFinite && lastChangeS <= toleranceS
        converged = true;
        break
    end
end

diagnostics = struct();
diagnostics.method = "fast_sweeping_3d";
diagnostics.iterations = iteration;
diagnostics.converged = converged;
diagnostics.last_change_s = lastChangeS;
diagnostics.maximum_iterations = maximumIterations;
diagnostics.tolerance_s = toleranceS;
diagnostics.finite_fraction = nnz(isfinite(travelTimeZYX)) / numel(travelTimeZYX);
diagnostics.grid_size_zyx = [Nz Ny Nx];

end

function candidate = localUpwindUpdate3D(neighbors, spacings, slowness)

finiteMask = isfinite(neighbors);
candidate = Inf;
indices = find(finiteMask);

% Evaluate every nonempty subset of available coordinate directions. A
% subset solution is admissible only when the positive quadratic root is
% not smaller than any neighbor used in that subset (Godunov causality).
for subsetCode = 1:(2^numel(indices)-1)
    localMask = logical(bitget(subsetCode, 1:numel(indices)));
    subset = indices(localMask);
    a = neighbors(subset);
    h = spacings(subset);
    invH2 = 1 ./ (h.^2);
    A = sum(invH2);
    B = sum(a .* invH2);
    C = sum((a.^2) .* invH2) - slowness^2;
    discriminant = B^2 - A*C;
    if discriminant < 0
        continue
    end
    root = (B + sqrt(discriminant)) / A;
    if root + 10*eps(max(1,abs(root))) >= max(a)
        candidate = min(candidate, root);
    end
end

end

function validateInputs(slowness, dxM, dyM, dzM, initialTime, fixedMask)
validateattributes(slowness, {'numeric'}, ...
    {'3d','nonempty','real','finite','nonnegative'});
for spacing = [dxM dyM dzM]
    validateattributes(spacing, {'numeric'}, {'scalar','positive','finite'});
end
if ~isequal(size(initialTime), size(slowness))
    error("swsynth:Eikonal3DInitialTimeSizeMismatch", ...
        "initialTimeZYX must match slownessZYX size.");
end
if ~isequal(size(fixedMask), size(slowness))
    error("swsynth:Eikonal3DFixedMaskSizeMismatch", ...
        "fixedMaskZYX must match slownessZYX size.");
end
if any(isnan(initialTime(:))) || any(initialTime(:) == -Inf)
    error("swsynth:InvalidEikonal3DInitialTime", ...
        "initial times may be finite or positive Inf.");
end
fixedMask = logical(fixedMask);
if ~any(fixedMask(:))
    error("swsynth:Eikonal3DMissingBoundaryCondition", ...
        "At least one fixed travel-time node is required.");
end
if any(~isfinite(initialTime(fixedMask)))
    error("swsynth:InvalidEikonal3DFixedTime", ...
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
