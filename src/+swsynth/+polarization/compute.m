function result = compute(request)
%COMPUTE Shear-wave material displacement polarization (no imaging model).
% plane_wave returns N unit transverse vectors. Point-force far-field
% returns M spatial vectors, preserving angular radiation magnitude.
arguments
    request (1,1) struct
end
request=swsynth.polarization.validate(request);
switch request.model
    case "plane_wave"
        result=swsynth.polarization.plane_wave.compute(request);
    case "point_force_shear_far_field"
        result=swsynth.polarization.point_force.compute(request);
end
end
