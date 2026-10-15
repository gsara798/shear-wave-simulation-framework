function forceXYZ = sampleForceDirections(count,stream)
%SAMPLEFORCEDIRECTIONS Random uniform in-plane x-z force orientations.
% Output is count-by-3 for consistency with volumetric force coordinates.
arguments
    count (1,1) double {mustBeInteger,mustBePositive}
    stream = []
end
if isempty(stream)
    theta=2*pi*rand(count,1);
else
    theta=2*pi*rand(stream,count,1);
end
forceXYZ=[cos(theta),zeros(count,1),sin(theta)];
end
