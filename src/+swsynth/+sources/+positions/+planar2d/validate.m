function positions = validate(positions, count, observationY)
%VALIDATE Validate in-plane source locations.
positions=swsynth.sources.positions.validate( ...
    positions,"planar2d",count,observationY);
end
