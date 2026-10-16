function a=factor(distance,exponent,referenceDistance)
%FACTOR Geometric amplitude spreading with explicit reference distance.
% exponent 0=plane, 0.5=ideal cylindrical, 1=far-field spherical.
arguments
    distance {mustBeNumeric}
    exponent (1,1) double {mustBeNonnegative}
    referenceDistance (1,1) double {mustBePositive}
end
if any(~isfinite(distance(:))) || any(distance(:)<0)
    error("swsynth:InvalidSpreadingDistance","Distances must be finite nonnegative.");
end
a=(referenceDistance./max(double(distance),referenceDistance)).^exponent;
end
