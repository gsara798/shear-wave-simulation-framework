function positions = validate(positions, count)
%VALIDATE Validate 3D sources for projected observations.
positions=swsynth.sources.positions.validate(positions,"projected3d",count);
end
