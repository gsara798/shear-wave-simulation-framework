function positions = generate(request)
%GENERATE Physical 3D source placement for a projected x-z observation.
% The observation plane does not constrain source y coordinates.
unitXYZ=swsynth.sources.positions.sampleUnitSphere(request);
r=swsynth.sources.positions.sampleRadii(request,3);
positions=request.center_xyz_m+r.*unitXYZ;
positions=swsynth.sources.positions.projected3d.validate( ...
    positions,request.count);
end
