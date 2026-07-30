function metrics = computeSpectralEntropy( ...
        powerSpectrum, kxRadM, kzRadM, options)
%COMPUTESPECTRALENTROPY Angular and radial spectral entropy.
%
% powerSpectrum must have size [numel(kzRadM), numel(kxRadM)].
%
% Returned normalized entropies lie in [0,1]:
%
%   0 -> energy concentrated in one bin
%   1 -> energy uniformly distributed across occupied analysis bins

if nargin < 4 || isempty(options)
    options = struct();
end

validateattributes( ...
    powerSpectrum, ...
    {'numeric'}, ...
    {'2d', 'nonempty', 'real', 'finite', 'nonnegative'});

validateattributes( ...
    kxRadM, ...
    {'numeric'}, ...
    {'vector', 'nonempty', 'real', 'finite'});

validateattributes( ...
    kzRadM, ...
    {'numeric'}, ...
    {'vector', 'nonempty', 'real', 'finite'});

kxRadM = double(kxRadM(:).');
kzRadM = double(kzRadM(:));
powerSpectrum = double(powerSpectrum);

if ~isequal( ...
        size(powerSpectrum), ...
        [numel(kzRadM), numel(kxRadM)])
    error( ...
        "swsynth:SpectralEntropySizeMismatch", ...
        ["powerSpectrum must have size " + ...
         "[numel(kzRadM), numel(kxRadM)]."]);
end

angularBinCount = getOption(options, "AngularBinCount", 36);
radialBinCount = getOption(options, "RadialBinCount", 24);
minimumRadiusRadM = getOption(options, "MinimumRadiusRadM", 0);
maximumRadiusRadM = getOption(options, "MaximumRadiusRadM", Inf);
halfPlane = lower(string(getOption(options, "HalfPlane", "all")));

validateattributes( ...
    angularBinCount, ...
    {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'});

validateattributes( ...
    radialBinCount, ...
    {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'});

validateattributes( ...
    minimumRadiusRadM, ...
    {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});

if ~(isnumeric(maximumRadiusRadM) && isscalar(maximumRadiusRadM) && ...
        (isfinite(maximumRadiusRadM) || isinf(maximumRadiusRadM)) && ...
        maximumRadiusRadM > minimumRadiusRadM)
    error( ...
        "swsynth:InvalidSpectralEntropyRadiusRange", ...
        ["MaximumRadiusRadM must exceed MinimumRadiusRadM " + ...
         "and may be Inf."]);
end

if ~ismember(halfPlane, ["all", "positive_kx", "negative_kx"])
    error( ...
        "swsynth:InvalidSpectralEntropyHalfPlane", ...
        "HalfPlane must be all, positive_kx, or negative_kx.");
end

[KX, KZ] = meshgrid(kxRadM, kzRadM);

radiusRadM = hypot(KX, KZ);
angleRad = atan2(KZ, KX);

analysisMask = ...
    radiusRadM >= minimumRadiusRadM & ...
    radiusRadM <= maximumRadiusRadM;

switch halfPlane
    case "positive_kx"
        analysisMask = analysisMask & KX >= 0;

    case "negative_kx"
        analysisMask = analysisMask & KX <= 0;
end

selectedPower = powerSpectrum(analysisMask);

totalPower = sum(selectedPower);

if totalPower <= 0
    error( ...
        "swsynth:ZeroSpectralEntropyPower", ...
        "The selected spectral region contains zero total power.");
end

selectedPower = selectedPower ./ totalPower;

selectedAngles = angleRad(analysisMask);
selectedRadii = radiusRadM(analysisMask);

angularEdges = linspace(-pi, pi, angularBinCount + 1);

finiteMaximumRadius = maximumRadiusRadM;

if isinf(finiteMaximumRadius)
    finiteMaximumRadius = max(selectedRadii);
end

radialEdges = linspace( ...
    minimumRadiusRadM, ...
    finiteMaximumRadius, ...
    radialBinCount + 1);

angularProbability = weightedHistogram( ...
    selectedAngles, ...
    selectedPower, ...
    angularEdges);

radialProbability = weightedHistogram( ...
    selectedRadii, ...
    selectedPower, ...
    radialEdges);

[angularEntropy, angularRawEntropy, angularEffectiveBins] = ...
    normalizedEntropy(angularProbability);

[radialEntropy, radialRawEntropy, radialEffectiveBins] = ...
    normalizedEntropy(radialProbability);

metrics = struct();

metrics.angular_entropy = angularEntropy;
metrics.radial_entropy = radialEntropy;

metrics.angular_raw_entropy = angularRawEntropy;
metrics.radial_raw_entropy = radialRawEntropy;

metrics.angular_effective_bins = angularEffectiveBins;
metrics.radial_effective_bins = radialEffectiveBins;

metrics.angular_probability = angularProbability;
metrics.radial_probability = radialProbability;

metrics.angular_bin_edges_rad = angularEdges;
metrics.radial_bin_edges_rad_m = radialEdges;

metrics.angular_bin_count = angularBinCount;
metrics.radial_bin_count = radialBinCount;

metrics.half_plane = halfPlane;
metrics.minimum_radius_rad_m = minimumRadiusRadM;
metrics.maximum_radius_rad_m = finiteMaximumRadius;
metrics.total_selected_power = totalPower;

end

function probability = weightedHistogram(values, weights, edges)

binIndex = discretize(values, edges);

validMask = ~isnan(binIndex);

probability = accumarray( ...
    binIndex(validMask), ...
    weights(validMask), ...
    [numel(edges)-1, 1], ...
    @sum, ...
    0);

probability = probability ./ sum(probability);

end

function [normalizedValue, rawValue, effectiveBins] = ...
        normalizedEntropy(probability)

positiveProbability = probability(probability > 0);

rawValue = ...
    -sum(positiveProbability .* log(positiveProbability));

binCount = numel(probability);

if binCount <= 1
    normalizedValue = 0;
else
    normalizedValue = rawValue / log(binCount);
end

effectiveBins = exp(rawValue);

end

function value = getOption(options, name, defaultValue)

if isfield(options, name) && ~isempty(options.(name))
    value = options.(name);
else
    value = defaultValue;
end

end
