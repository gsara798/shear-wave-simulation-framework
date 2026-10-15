function positions = validate(positions, count)
%VALIDATE Validate volumetric 3D source locations.
positions=swsynth.sources.positions.validate(positions,"volumetric3d",count);
end
