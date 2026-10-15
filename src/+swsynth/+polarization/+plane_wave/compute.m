function result = compute(request)
%COMPUTE Unit transverse polarization for each incident plane wave.
% Input request is normalized by swsynth.polarization.validate.
k=request.direction_xyz;
n=size(k,1);
fallbackCount=0;
switch request.policy
    case "in_plane_sv"
        p=[k(:,3),zeros(n,1),-k(:,1)];
        normP=vecnorm(p,2,2);
        degenerate=normP<1e-10;
        p(degenerate,:)=[ones(nnz(degenerate),1), ...
            zeros(nnz(degenerate),2)];
        normP(degenerate)=1;
        p=p./normP;
        fallbackCount=nnz(degenerate);
    case "transverse_explicit"
        p=request.explicit_polarization_xyz;
    case "transverse_preferred"
        candidate=repmat(request.reference_axis_xyz,n,1);
        [p,fallbackCount]=transverseNormalize(candidate,k,request.geometry);
    case "transverse_random"
        if request.geometry=="planar2d"
            % In a strictly 2D x-z shear model the transverse subspace
            % is 1D: the two polarizations are opposite signs of SV.
            if isfield(request,"stream") && ~isempty(request.stream)
                signs=randn(request.stream,n,1);
            else
                signs=randn(n,1);
            end
            signs(signs>=0)=1;
            signs(signs<0)=-1;
            p=signs.*[k(:,3),zeros(n,1),-k(:,1)];
        else
            if isfield(request,"stream") && ~isempty(request.stream)
                candidate=randn(request.stream,n,3);
            else
                candidate=randn(n,3);
            end
            [p,fallbackCount]=transverseNormalize(candidate,k,request.geometry);
        end
end
result=struct();
result.model="plane_wave";
result.geometry=request.geometry;
result.policy=request.policy;
result.direction_xyz=k;
result.vector_xyz=p;
result.unit_vector_xyz=p;
result.magnitude=ones(n,1);
result.diagnostics=struct("count",n,"fallback_count",fallbackCount, ...
    "maximum_transversality_error",max(abs(sum(p.*k,2))), ...
    "maximum_norm_error",max(abs(vecnorm(p,2,2)-1)));
end

function [p,fallbackCount] = transverseNormalize(v,k,geometry)
% Remove longitudinal component, including for the preferred-axis model.
p=v-sum(v.*k,2).*k;
norms=vecnorm(p,2,2);
degenerate=norms<1e-10;
fallbackCount=nnz(degenerate);
for row=find(degenerate).'
    if geometry=="planar2d"
        % The fallback must remain SV in the x-z plane, never SH in y.
        p(row,:)=[k(row,3),0,-k(row,1)];
    else
        [~,j]=min(abs(k(row,:)));
        axis=zeros(1,3);
        axis(j)=1;
        p(row,:)=axis-dot(axis,k(row,:))*k(row,:);
    end
    norms(row)=norm(p(row,:));
end
p=p./norms;
end
