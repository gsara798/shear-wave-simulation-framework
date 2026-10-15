function request = validate(request)
%VALIDATE Validate polarization physics without making a measurement projection.
% For plane_wave: direction_xyz (N x 3), policy, optional reference_axis_xyz,
% explicit_polarization_xyz or stream. For point_force_shear_far_field:
% source_xyz_m (1 x 3), observation_xyz_m (M x 3), force_direction_xyz.
arguments
    request (1,1) struct
end
for field=["model","geometry"]
    if ~isfield(request,field)
        error("swsynth:PolarizationMissingField","Missing %s.",field);
    end
end
model=string(request.model);
geometry=string(request.geometry);
if ~isscalar(model) || ~isscalar(geometry)
    error("swsynth:InvalidPolarizationRequest", ...
        "model and geometry must be scalar strings.");
end
if geometry=="2d";geometry="planar2d";end
if ~ismember(geometry,["planar2d","projected3d","volumetric3d"])
    error("swsynth:InvalidPolarizationGeometry","Unsupported geometry %s.",geometry);
end
if ~ismember(model,["plane_wave","point_force_shear_far_field"])
    error("swsynth:InvalidPolarizationModel","Unsupported polarization model %s.",model);
end
request.model=model;
request.geometry=geometry;

if isfield(request,"stream") && ~isempty(request.stream) && ...
        ~isa(request.stream,"RandStream")
    error("swsynth:InvalidPolarizationStream","stream must be a RandStream.");
end

switch model
    case "plane_wave"
        if ~isfield(request,"direction_xyz")
            error("swsynth:PolarizationMissingField", ...
                "Plane waves require direction_xyz.");
        end
        k=double(request.direction_xyz);
        if ~ismatrix(k) || size(k,2)~=3 || isempty(k) || ~isreal(k) || ...
                any(~isfinite(k(:))) || any(vecnorm(k,2,2)<=eps)
            error("swsynth:InvalidPolarizationDirections", ...
                "direction_xyz must be finite nonzero N-by-3 vectors.");
        end
        k=k./vecnorm(k,2,2);
        if geometry=="planar2d" && any(abs(k(:,2))>1e-10)
            error("swsynth:PolarizationOutsidePlane", ...
                "Planar2d propagation requires zero y components.");
        end
        request.direction_xyz=k;
        if ~isfield(request,"policy") || isempty(request.policy)
            request.policy="transverse_random";
        end
        policy=string(request.policy);
        if ~isscalar(policy) || ...
                ~ismember(policy,["transverse_random","transverse_preferred", ...
                "in_plane_sv","transverse_explicit"])
            error("swsynth:InvalidPolarizationPolicy", ...
                "Unsupported plane-wave polarization policy.");
        end
        request.policy=policy;
        if policy=="transverse_preferred"
            if ~isfield(request,"reference_axis_xyz")
                error("swsynth:PolarizationMissingField", ...
                    "transverse_preferred requires reference_axis_xyz.");
            end
            ref=double(request.reference_axis_xyz);
            if ~isequal(size(ref),[1 3]) || ~isreal(ref) || ...
                    any(~isfinite(ref)) || norm(ref)<=eps
                error("swsynth:InvalidPolarizationAxis", ...
                    "reference_axis_xyz must be a finite nonzero 1-by-3 vector.");
            end
            ref=ref/norm(ref);
            if geometry=="planar2d" && abs(ref(2))>1e-10
                error("swsynth:PolarizationOutsidePlane", ...
                    "Planar2d reference axis must be in the x-z plane.");
            end
            request.reference_axis_xyz=ref;
        elseif policy=="transverse_explicit"
            if ~isfield(request,"explicit_polarization_xyz")
                error("swsynth:PolarizationMissingField", ...
                    "transverse_explicit requires explicit_polarization_xyz.");
            end
            p=double(request.explicit_polarization_xyz);
            if ~isequal(size(p),size(k)) || ~isreal(p) || ...
                    any(~isfinite(p(:))) || ...
                    any(vecnorm(p,2,2)<=eps)
                error("swsynth:InvalidExplicitPolarization", ...
                    "explicit_polarization_xyz must be N-by-3 finite nonzero vectors.");
            end
            p=p./vecnorm(p,2,2);
            if any(abs(sum(p.*k,2))>1e-9) || ...
                    (geometry=="planar2d" && any(abs(p(:,2))>1e-10))
                error("swsynth:NonTransversePolarization", ...
                    "Explicit polarization must be transverse and in-plane in 2D.");
            end
            request.explicit_polarization_xyz=p;
        end
    case "point_force_shear_far_field"
        for field=["source_xyz_m","observation_xyz_m","force_direction_xyz"]
            if ~isfield(request,field)
                error("swsynth:PolarizationMissingField","Missing %s.",field);
            end
        end
        src=double(request.source_xyz_m);
        obs=double(request.observation_xyz_m);
        force=double(request.force_direction_xyz);
        if ~isequal(size(src),[1 3]) || ~isreal(src) || ...
                any(~isfinite(src)) || ...
                ~ismatrix(obs) || size(obs,2)~=3 || isempty(obs) || ...
                ~isreal(obs) || ...
                any(~isfinite(obs(:))) || ...
                ~isequal(size(force),[1 3]) || ~isreal(force) || ...
                any(~isfinite(force)) || norm(force)<=eps
            error("swsynth:InvalidPointForcePolarization", ...
                "Require finite source 1-by-3, observations M-by-3 and nonzero force 1-by-3.");
        end
        if any(vecnorm(obs-src,2,2)<=eps)
            error("swsynth:ObservationAtPointForce", ...
                "Observation positions must differ from source position.");
        end
        if geometry=="planar2d"
            y=0;
            if isfield(request,"observation_y_m")
                y=double(request.observation_y_m);
            end
            if ~isscalar(y) || ~isfinite(y)
                error("swsynth:InvalidObservationY", ...
                    "observation_y_m must be finite.");
            end
            if abs(src(2)-y)>1e-10 || ...
                    any(abs(obs(:,2)-y)>1e-10) || abs(force(2))>1e-10
                error("swsynth:PolarizationOutsidePlane", ...
                    "Planar2d point-force geometry and force must be in the x-z plane.");
            end
            request.observation_y_m=y;
        end
        request.source_xyz_m=src;
        request.observation_xyz_m=obs;
        request.force_direction_xyz=force/norm(force);
end
end
