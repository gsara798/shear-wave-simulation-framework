function contribution = computeContribution(request)
%COMPUTECONTRIBUTION Vector shear far-field from ONE physical source.
% Uses sources.prepare V2, including an optional coherent line aperture.
% Geometry: 2d/planar2d, projected3d, volumetric3d.
% Phase: homogeneous analytical T=distance/c_s, per aperture node.
% Radiation: (I-n*n') Fhat. Angular magnitude is preserved.
%
% Each aperture node inherits its parent force, amplitude and phase.
% Geometric decay is r^(-exponent), exponent defaults to zero, as in
% existing point-force synthesis. No receiver projection or noise.
%
% Example request:
%   request.source_bundle=swsynth.sources.prepare(sourceRequest);
%   request.source_id=1;
%   request.frequency_hz=500;
%   request.phase=struct("method","analytical","reference_cs_m_s",2);
%   request.x_m=0:.001:.03; request.z_m=0:.001:.03;
arguments
    request (1,1) struct
end
for field=["source_bundle","frequency_hz","phase","x_m","z_m"]
    if ~isfield(request,field)
        error("swsynth:SphericalContributionMissingField", ...
            "Missing point-source contribution field %s.",field);
    end
end
bundle=request.source_bundle;
if ~isstruct(bundle) || ~isscalar(bundle) || ...
        ~isfield(bundle,"geometry") || ...
        ~isfield(bundle,"sources") || ~isfield(bundle,"aperture")
    error("swsynth:InvalidSphericalSourceBundle", ...
        "source_bundle must be the V2 output of sources.prepare.");
end
geometry=canonicalGeometry(bundle.geometry);
if isfield(request,"geometry") && ...
        canonicalGeometry(request.geometry)~=geometry
    error("swsynth:SphericalContributionGeometryMismatch", ...
        "Requested geometry conflicts with source_bundle geometry.");
end
bundle=swsynth.sources.validate(bundle,geometry);
if ~isfield(bundle.sources,"position_xyz_m") || ...
        ~isfield(bundle.sources,"force_direction_xyz") || ...
        ~isfield(bundle.sources,"relative_amplitude") || ...
        ~isfield(bundle.sources,"phase_rad")
    error("swsynth:InvalidSphericalSourceBundle", ...
        "source_bundle must provide positions and source-level excitation.");
end
n=size(bundle.sources.position_xyz_m,1);
sourceID=1;
if isfield(request,"source_id")
    sourceID=double(request.source_id);
elseif n~=1
    error("swsynth:SphericalContributionMissingSourceID", ...
        "Select source_id explicitly for a multi-source bundle.");
end
if ~isscalar(sourceID) || ~isreal(sourceID) || ...
        ~isfinite(sourceID) || sourceID~=floor(sourceID) || ...
        sourceID<1 || sourceID>n
    error("swsynth:InvalidSphericalSourceID", ...
        "source_id must be an integer between 1 and source_bundle.count.");
end
frequency=double(request.frequency_hz);
if ~isscalar(frequency) || ~isreal(frequency) || ...
        ~isfinite(frequency) || frequency<=0
    error("swsynth:InvalidSphericalFrequency", ...
        "frequency_hz must be a positive finite scalar.");
end
phaseRequest=request.phase;
if ~isstruct(phaseRequest) || ~isscalar(phaseRequest) || ...
        ~isfield(phaseRequest,"method") || ...
        ~isfield(phaseRequest,"reference_cs_m_s")
    error("swsynth:InvalidSphericalPhaseRequest", ...
        "phase must specify method and reference_cs_m_s.");
end
method=string(phaseRequest.method);
if ~isscalar(method) || ~ismember(method, ...
        ["analytical","homogeneous_analytic","eikonal"])
    error("swsynth:UnsupportedSphericalPhaseMethod", ...
        "V2 point-source contribution currently supports homogeneous analytical phase only.");
end
if isfield(phaseRequest,"model") && ...
        (~isscalar(string(phaseRequest.model)) || ...
         string(phaseRequest.model)~="spherical_wave")
    error("swsynth:SphericalContributionModelMismatch", ...
        "Phase model must be spherical_wave.");
end
if isfield(phaseRequest,"geometry") && ...
        canonicalGeometry(phaseRequest.geometry)~=geometry
    error("swsynth:SphericalContributionGeometryMismatch", ...
        "Phase geometry conflicts with source geometry.");
end
cs=double(phaseRequest.reference_cs_m_s);
if ~isscalar(cs) || ~isreal(cs) || ~isfinite(cs) || cs<=0
    error("swsynth:InvalidSphericalReferenceSpeed", ...
        "reference_cs_m_s must be a positive real scalar.");
end
decayExponent=0;
if isfield(request,"geometric_decay_exponent")
    decayExponent=double(request.geometric_decay_exponent);
end
if ~isscalar(decayExponent) || ~isreal(decayExponent) || ...
        ~isfinite(decayExponent) || decayExponent<0
    error("swsynth:InvalidGeometricDecayExponent", ...
        "geometric_decay_exponent must be finite and nonnegative.");
end

x=checkAxis(request.x_m,"x_m");
z=checkAxis(request.z_m,"z_m");
if geometry=="volumetric3d"
    if ~isfield(request,"y_m")
        error("swsynth:SphericalContributionMissingField", ...
            "volumetric3d requires y_m.");
    end
    y=checkAxis(request.y_m,"y_m");
    [Z,Y,X]=ndgrid(z,y,x);
    targetXYZ=[X(:),Y(:),Z(:)];
    spatialSize=[numel(z),numel(y),numel(x)];
    outputConvention="U(z,y,x,component_xyz)";
else
    observationY=0;
    if isfield(request,"observation_y_m")
        observationY=double(request.observation_y_m);
    elseif isfield(bundle.sources,"observation_y_m")
        observationY=double(bundle.sources.observation_y_m);
    end
    if ~isscalar(observationY) || ~isreal(observationY) || ...
            ~isfinite(observationY)
        error("swsynth:InvalidObservationY", ...
            "observation_y_m must be finite.");
    end
    if geometry=="2d" && isfield(bundle.sources,"observation_y_m") && ...
            observationY~=double(bundle.sources.observation_y_m)
        error("swsynth:SphericalContributionGeometryMismatch", ...
            "Planar observation must use the source bundle's y plane.");
    end
    [Z,X]=ndgrid(z,x);
    targetXYZ=[X(:),repmat(observationY,numel(X),1),Z(:)];
    spatialSize=[numel(z),numel(x)];
    outputConvention="U(z,x,component_xyz)";
end

sourcePosition=double(bundle.sources.position_xyz_m(sourceID,:));
force=double(bundle.sources.force_direction_xyz(sourceID,:));
amplitude=double(bundle.sources.relative_amplitude(sourceID));
initialPhase=double(bundle.sources.phase_rad(sourceID));
nodes=double(bundle.aperture.per_source(sourceID).node_xyz_m);
weights=double(bundle.aperture.per_source(sourceID).node_weights(:));
nodeCount=size(nodes,1);

% Allocate one vector field for a single physical source; each coherent
% aperture element contributes its full 3D point-force radiation vector.
fieldXYZ=complex(zeros(numel(X),3));
for j=1:nodeCount
    phaseForNode=struct("model","spherical_wave", ...
        "method",method,"geometry",geometry, ...
        "reference_cs_m_s",cs, ...
        "source_xyz_m",nodes(j,:), ...
        "target_xyz_m",targetXYZ);
    if method=="eikonal"
        if geometry~="projected3d" || nodeCount~=1 || ...
                ~isfield(request,"phase_speed_map_zx") || ...
                ~isfield(request,"attenuation_map_np_m")
            error("swsynth:UnsupportedPointSourceEikonal", ...
                "Heterogeneous source Eikonal needs an internal on-plane point source.");
        end
        opts=struct();
        if isfield(request,"solver_options");opts=request.solver_options;end
        if isfield(request,"attenuation_interface")
            opts.AttenuationPlane=request.attenuation_interface;
        end
        useExtended=nodes(j,1)<x(1) || nodes(j,1)>x(end) || ...
            nodes(j,3)<z(1) || nodes(j,3)>z(end) || ...
            abs(nodes(j,2)-observationY)>1e-12;
        if useExtended
            [timeZX,opticalZX,extendedDiagnostics]= ...
                swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
                request.phase_speed_map_zx,request.attenuation_map_np_m, ...
                x(:).',z(:),nodes(j,:),observationY,opts);
        else
            [timeZX,~]=swsynth.phase.eikonal.projected3d.computePointSourceTravelTime( ...
                request.phase_speed_map_zx,x(:).',z(:),nodes(j,:),opts);
        end
        tau=timeZX(:);
    else
        phaseResult=swsynth.phase.compute(phaseForNode);
        tau=double(phaseResult.travel_time_s(:));
    end
    % The far-field point-force radiation tensor is undefined at its own
    % source. For internal Eikonal sources, exclude a grid-scale near-source
    % region rather than evaluating a singular or invented polarization.
    coreMask=false(size(tau));
    radiationTargets=targetXYZ;
    if method=="eikonal"
        coreRadius=1.5*hypot(mean(diff(x)),mean(diff(z)));
        coreMask=vecnorm(targetXYZ-nodes(j,:),2,2)<=coreRadius;
        radiationTargets(coreMask,:)=repmat( ...
            nodes(j,:)+[coreRadius,0,0],nnz(coreMask),1);
    end
    radiationRequest=struct("model","point_force_shear_far_field", ...
        "geometry",geometry, ...
        "source_xyz_m",nodes(j,:), ...
        "observation_xyz_m",radiationTargets, ...
        "force_direction_xyz",force);
    if geometry=="2d"
        radiationRequest.observation_y_m=observationY;
    end
    pol=swsynth.polarization.compute(radiationRequest);
    distance=double(pol.distance_m);
    spreading=ones(size(distance));
    if decayExponent>0
        spreading=distance.^(-decayExponent);
    end
    if isfield(request,"attenuation_np_m")
        alpha=double(request.attenuation_np_m);
        if ~isscalar(alpha)||~isfinite(alpha)||alpha<0
            error("swsynth:InvalidAttenuation","attenuation_np_m must be nonnegative.");
        end
        spreading=spreading.*exp(-alpha*distance);
    end
    if method=="eikonal"
        if useExtended
            optical=opticalZX;
        else
            optical=swsynth.propagation.attenuation.integratePointSource2D( ...
                timeZX,request.attenuation_map_np_m,x(:).',z(:),nodes(j,:));
        end
        spreading=spreading.*exp(-optical(:));
    end
    scalar=amplitude*weights(j).*spreading.* ...
        exp(1i*(2*pi*frequency*tau+initialPhase));
    nodeField=scalar.*double(pol.vector_xyz);
    nodeField(coreMask,:)=0; % Near-source physics is deliberately unresolved.
    fieldXYZ=fieldXYZ+nodeField;
end
U=reshape(fieldXYZ,[spatialSize,3]);
U=complex(real(U),imag(U));

contribution=struct();
contribution.model="spherical_wave";
contribution.radiation_model="point_force_shear_far_field";
contribution.geometry=geometry;
contribution.frequency_hz=frequency;
contribution.phase_sign=1;
contribution.phase_solver="homogeneous_spherical_distance";
if method=="eikonal"
    contribution.phase_solver="internal_point_source_eikonal_2d";
    if useExtended
        contribution.phase_solver="extended_point_source_eikonal_3d";
        contribution.phase_diagnostics=extendedDiagnostics;
    end
end
contribution.source_id=sourceID;
contribution.source_xyz_m=sourcePosition;
contribution.force_direction_xyz=force;
contribution.amplitude=amplitude;
contribution.phase_rad=initialPhase;
contribution.geometric_decay_exponent=decayExponent;
contribution.reference_cs_m_s=cs;
contribution.aperture_node_count=nodeCount;
contribution.x_m=x(:).';
contribution.z_m=z(:).';
if geometry=="volumetric3d"
    contribution.y_m=y(:).';
else
    contribution.observation_y_m=observationY;
end
contribution.U_xyz=U;
contribution.output_convention=outputConvention;
end

function geometry=canonicalGeometry(value)
geometry=string(value);
if ~isscalar(geometry)
    error("swsynth:InvalidSphericalGeometry","geometry must be scalar.");
end
if geometry=="planar2d";geometry="2d";end
if ~ismember(geometry,["2d","projected3d","volumetric3d"])
    error("swsynth:InvalidSphericalGeometry", ...
        "Unsupported point-source geometry %s.",geometry);
end
end

function axis=checkAxis(value,name)
if ~isnumeric(value) || ~isvector(value) || isempty(value) || ...
        ~isreal(value) || any(~isfinite(value(:)))
    error("swsynth:InvalidSphericalGrid", ...
        "%s must be a finite real vector.",name);
end
axis=double(value(:));
if any(diff(axis)<=0)
    error("swsynth:InvalidSphericalGrid", ...
        "%s must be strictly increasing.",name);
end
end
