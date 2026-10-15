function positions = generate(request)
%GENERATE Place physical emitters; independent of wave propagation directions.
% Methods: explicit XYZ, random angular/radial, deterministic fibonacci.
% Geometry selects the physical spatial placement algorithm.
arguments
    request (1,1) struct
end
request=swsynth.sources.positions.validateRequest(request);
if request.method=="explicit"
    positions=request.position_xyz_m;
    return;
end
switch request.geometry
    case "planar2d"
        positions=swsynth.sources.positions.planar2d.generate(request);
    case "projected3d"
        positions=swsynth.sources.positions.projected3d.generate(request);
    case "volumetric3d"
        positions=swsynth.sources.positions.volumetric3d.generate(request);
end
end
