function positions = generate(request)
%GENERATE Physical source positions around a volumetric 3D domain.
% 3D source coordinates have the same mathematical sampling as projected3d.
unitXYZ=swsynth.sources.positions.sampleUnitSphere(request);
r=swsynth.sources.positions.sampleRadii(request,3);
positions=request.center_xyz_m+r.*unitXYZ;
positions=swsynth.sources.positions.volumetric3d.validate( ...
    positions,request.count);
end
