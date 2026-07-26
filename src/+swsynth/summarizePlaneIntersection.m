function summary = summarizePlaneIntersection(directions, options)
%SUMMARIZEPLANEINTERSECTION Summarize direction coverage of the y=0 plane.
%
% A propagation direction lies in the x-z observation plane when uy = 0.
%
% Usage:
%   summary = swsynth.summarizePlaneIntersection(directions);
%   summary = swsynth.summarizePlaneIntersection( ...
%       directions, Tolerance=1e-6);

arguments
    directions (1,1) struct
    options.Tolerance (1,1) double {mustBeNonnegative} = 1e-6
end

if ~isfield(directions, "uy")
    error("swsynth:MissingDirectionComponent", ...
        "directions must contain field uy.");
end

tolerance = options.Tolerance;
uy = double(directions.uy(:));
uy = uy(isfinite(uy));

if isempty(uy)
    summary = struct( ...
        "tolerance", tolerance, ...
        "n_directions", 0, ...
        "min_abs_uy", NaN, ...
        "median_abs_uy", NaN, ...
        "p01_abs_uy", NaN, ...
        "p05_abs_uy", NaN, ...
        "count_in_plane", 0, ...
        "has_in_plane_direction", false, ...
        "nearest_index", NaN);
    return;
end

absUy = abs(uy);
[minAbsUy, nearestIndex] = min(absUy);

summary = struct();
summary.tolerance = tolerance;
summary.n_directions = numel(uy);
summary.min_abs_uy = minAbsUy;
summary.median_abs_uy = median(absUy);
summary.p01_abs_uy = localPercentile(absUy, 1);
summary.p05_abs_uy = localPercentile(absUy, 5);
summary.count_in_plane = sum(absUy <= tolerance);
summary.has_in_plane_direction = summary.count_in_plane > 0;
summary.nearest_index = nearestIndex;

end

function value = localPercentile(values, percentileValue)

values = sort(values(:));
index = ceil(percentileValue / 100 * numel(values));
index = max(1, min(numel(values), index));
value = values(index);

end
