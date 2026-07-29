function [fieldZX, diagnostics] = synthesizeDirectionalField( ...
    csMapZX, xM, zM, directionsXYZ, weights, ...
    frequencyHz, referenceCsMps, options)
%SYNTHESIZEDIRECTIONALFIELD Sum projected-3D directional components.
%
% directionsXYZ is N-by-3. Each row is a three-dimensional unit direction.
% weights is N-by-1 and may contain amplitude and initial complex phase.
%
% The returned complex harmonic field is
%
%   U(z,x) = sum_n weights(n) * exp(i*omega*tau_n(z,x)).
%
% The medium is invariant along y and represented by csMapZX.

if nargin < 8 || isempty(options)
    options = struct();
end

validateattributes( ...
    csMapZX, ...
    {'numeric'}, ...
    {'2d', 'nonempty', 'real', 'finite', 'positive'});

validateattributes( ...
    directionsXYZ, ...
    {'numeric'}, ...
    {'2d', 'nonempty', 'real', 'finite'});

validateattributes( ...
    frequencyHz, ...
    {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});

validateattributes( ...
    referenceCsMps, ...
    {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});

if size(directionsXYZ, 2) ~= 3
    error( ...
        "swsynth:Projected3DDirectionShape", ...
        "directionsXYZ must have size N-by-3.");
end

directionCount = size(directionsXYZ, 1);

if isempty(weights)
    weights = ones(directionCount, 1) / sqrt(directionCount);
end

weights = weights(:);

if numel(weights) ~= directionCount
    error( ...
        "swsynth:Projected3DWeightCountMismatch", ...
        "weights must contain one value per direction.");
end

if any(~isfinite(real(weights))) || ...
        any(~isfinite(imag(weights)))
    error( ...
        "swsynth:InvalidProjected3DWeights", ...
        "weights must be finite.");
end

useParallel = logical(getOption( ...
    options, ...
    "UseParallel", ...
    false));

solverOptions = getOption( ...
    options, ...
    "SolverOptions", ...
    struct());

if useParallel
    try
        if isempty(gcp("nocreate"))
            parpool("threads");
        end
    catch
        useParallel = false;
    end
end

omegaRadS = 2*pi*frequencyHz;

contributions = cell(directionCount, 1);
solverMethods = strings(directionCount, 1);
solverIterations = zeros(directionCount, 1);
perDirectionTimeS = zeros(directionCount, 1);

parfor (directionIndex = 1:directionCount, ...
        parallelFlag(useParallel))

    timerHandle = tic;

    [phaseDelayZX, phaseDiagnostics] = ...
        swsynth.propagation.projected3d. ...
            computeDirectionalPhaseDelay( ...
                csMapZX, ...
                xM, ...
                zM, ...
                directionsXYZ(directionIndex, :), ...
                referenceCsMps, ...
                solverOptions);

    contributions{directionIndex} = ...
        weights(directionIndex) .* ...
        exp(1i .* omegaRadS .* phaseDelayZX);

    solverMethods(directionIndex) = ...
        phaseDiagnostics.solver.method;

    solverIterations(directionIndex) = ...
        phaseDiagnostics.solver.iterations;

    perDirectionTimeS(directionIndex) = toc(timerHandle);
end

fieldZX = complex(zeros(size(csMapZX)));

for directionIndex = 1:directionCount
    fieldZX = fieldZX + contributions{directionIndex};
end

unitDirectionsXYZ = double(directionsXYZ);

directionNorms = sqrt(sum(unitDirectionsXYZ.^2, 2));
unitDirectionsXYZ = ...
    unitDirectionsXYZ ./ directionNorms;

diagnostics = struct();
diagnostics.model = ...
    "projected3d_directional_eikonal_superposition";
diagnostics.direction_count = directionCount;
diagnostics.directions_xyz = unitDirectionsXYZ;
diagnostics.projected_direction_norm = hypot( ...
    unitDirectionsXYZ(:, 1), ...
    unitDirectionsXYZ(:, 3));
diagnostics.weights = weights;
diagnostics.solver_methods = solverMethods;
diagnostics.solver_iterations = solverIterations;
diagnostics.per_direction_time_s = perDirectionTimeS;
diagnostics.total_direction_time_s = sum(perDirectionTimeS);
diagnostics.used_parallel = useParallel;

end

function value = getOption(options, name, defaultValue)

if isfield(options, name) && ~isempty(options.(name))
    value = options.(name);
else
    value = defaultValue;
end

end

function flag = parallelFlag(useParallel)

if useParallel
    flag = Inf;
else
    flag = 0;
end

end
