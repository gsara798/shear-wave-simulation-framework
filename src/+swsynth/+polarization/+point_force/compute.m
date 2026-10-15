function result = compute(request)
%COMPUTE Far-field shear displacement direction from one physical force.
% p(r) = (I-n*n') Fhat, n=(r-source)/|r-source|.
% p is NOT unit-normalized: its norm carries angular radiation strength.
% No geometric spreading, travel time, shear attenuation, phase or
% ultrasound measurement effects are applied here.
src=request.source_xyz_m;
obs=request.observation_xyz_m;
force=request.force_direction_xyz;
delta=obs-src;
distance=vecnorm(delta,2,2);
radial=delta./distance;
projection=radial*force.';
p=force-radial.*projection;
strength=vecnorm(p,2,2);
unitP=zeros(size(p));
mask=strength>1e-12;
unitP(mask,:)=p(mask,:)./strength(mask);
result=struct();
result.model="point_force_shear_far_field";
result.geometry=request.geometry;
result.vector_xyz=p;
result.unit_vector_xyz=unitP;
result.magnitude=strength;
result.radial_direction_xyz=radial;
result.distance_m=distance;
result.diagnostics=struct("count",size(obs,1), ...
    "zero_radiation_count",nnz(~mask), ...
    "maximum_transversality_error",max(abs(sum(p.*radial,2))));
end
