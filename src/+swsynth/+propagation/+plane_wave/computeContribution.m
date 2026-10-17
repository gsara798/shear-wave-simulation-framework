function contribution = computeContribution(request)
%COMPUTECONTRIBUTION Complex vector field from ONE harmonic shear plane wave.
%
% request.geometry = "2d"/"planar2d", "projected3d", "volumetric3d"
% request.direction_xyz = 1x3 incidence vector (not actuator force)
% request.frequency_hz > 0, request.amplitude >= 0, request.phase_rad
% request.phase = struct("method",...,"reference_cs_m_s",...,
%     "x_m",...,"z_m",...) with y_m / cs_map / solver_options as needed
% request.polarization = struct("policy",...,"reference_axis_xyz",...)
%
% Returns U_xyz of shape [Nz,Nx,3] or [Nz,Ny,Nx,3], whose last dimension
% holds vector x,y,z components. Uses the legacy spatial phasor sign
% exp(+1i*(omega*T+phase_rad)); no measurement projection is applied.
% No noise, amplitude normalization by N, material attenuation, or
% implicit RNG reseeding. Do not interpret this as a source-force model.
arguments
    request (1,1) struct
end
required=["geometry","direction_xyz","frequency_hz","phase","polarization"];
for name=required
    if ~isfield(request,name)
        error("swsynth:PlaneContributionMissingField", ...
            "Missing plane-wave contribution field %s.",name);
    end
end
geometry=string(request.geometry);
if ~isscalar(geometry)
    error("swsynth:InvalidPlaneContributionGeometry", ...
        "geometry must be scalar.");
end
if geometry=="planar2d";geometry="2d";end
if ~ismember(geometry,["2d","projected3d","volumetric3d"])
    error("swsynth:InvalidPlaneContributionGeometry", ...
        "Unsupported plane-wave geometry %s.",geometry);
end
d=double(request.direction_xyz);
if ~isequal(size(d),[1 3]) || ~isreal(d) || ...
        any(~isfinite(d)) || norm(d)<=eps
    error("swsynth:InvalidPlaneContributionDirection", ...
        "direction_xyz must be a finite nonzero 1-by-3 vector.");
end
d=d/norm(d);
if geometry=="2d" && abs(d(2))>1e-10
    error("swsynth:InvalidPlaneContributionDirection", ...
        "An in-plane 2D wave must have direction_y=0.");
end
freq=double(request.frequency_hz);
if ~isscalar(freq) || ~isreal(freq) || ~isfinite(freq) || freq<=0
    error("swsynth:InvalidPlaneContributionFrequency", ...
        "frequency_hz must be a positive finite scalar.");
end
amplitude=1;
if isfield(request,"amplitude")
    amplitude=double(request.amplitude);
end
if ~isscalar(amplitude) || ~isreal(amplitude) || ...
        ~isfinite(amplitude) || amplitude<0
    error("swsynth:InvalidPlaneContributionAmplitude", ...
        "amplitude must be a nonnegative finite scalar.");
end
phase0=0;
if isfield(request,"phase_rad")
    phase0=double(request.phase_rad);
end
if ~isscalar(phase0) || ~isreal(phase0) || ~isfinite(phase0)
    error("swsynth:InvalidPlaneContributionPhase", ...
        "phase_rad must be a finite real scalar.");
end
if ~isstruct(request.phase) || ~isscalar(request.phase) || ...
        ~isfield(request.phase,"method")
    error("swsynth:InvalidPlaneContributionPhaseRequest", ...
        "request.phase must be a struct with a phase method.");
end
if ~isstruct(request.polarization) || ...
        ~isscalar(request.polarization) || ...
        ~isfield(request.polarization,"policy")
    error("swsynth:InvalidPlaneContributionPolarizationRequest", ...
        "request.polarization must specify a polarization policy.");
end
phaseRequest=request.phase;
polRequest=request.polarization;
if isfield(phaseRequest,"model") && string(phaseRequest.model)~="plane_wave"
    error("swsynth:PlaneContributionModelMismatch", ...
        "Phase model must be plane_wave.");
end
if isfield(polRequest,"model") && string(polRequest.model)~="plane_wave"
    error("swsynth:PlaneContributionModelMismatch", ...
        "Polarization model must be plane_wave.");
end
if isfield(phaseRequest,"geometry") && ...
        ~sameGeometry(phaseRequest.geometry,geometry)
    error("swsynth:PlaneContributionGeometryMismatch", ...
        "Phase geometry conflicts with the requested geometry.");
end
if isfield(polRequest,"geometry") && ...
        ~sameGeometry(polRequest.geometry,geometry)
    error("swsynth:PlaneContributionGeometryMismatch", ...
        "Polarization geometry conflicts with the requested geometry.");
end
if isfield(phaseRequest,"direction_xyz") && ...
        ~sameDirection(phaseRequest.direction_xyz,d)
    error("swsynth:PlaneContributionDirectionMismatch", ...
        "Phase direction conflicts with the requested direction.");
end
if isfield(polRequest,"direction_xyz") && ...
        ~sameDirection(polRequest.direction_xyz,d)
    error("swsynth:PlaneContributionDirectionMismatch", ...
        "Polarization direction conflicts with the requested direction.");
end
phaseRequest.model="plane_wave";
phaseRequest.geometry=geometry;
phaseRequest.direction_xyz=d;
polRequest.model="plane_wave";
polRequest.geometry=geometry;
polRequest.direction_xyz=d;

% Validate spatial axes before calling the selected phase solver so the
% contract cannot silently transpose, reshape, or drop a spatial axis.
for name=["x_m","z_m"]
    if ~isfield(phaseRequest,name)
        error("swsynth:PlaneContributionMissingGrid", ...
            "request.phase.%s is required.",name);
    end
end
x=checkGridAxis(phaseRequest.x_m,"x_m");
z=checkGridAxis(phaseRequest.z_m,"z_m");
if geometry=="volumetric3d"
    if ~isfield(phaseRequest,"y_m")
        error("swsynth:PlaneContributionMissingGrid", ...
            "volumetric3d requires request.phase.y_m.");
    end
    y=checkGridAxis(phaseRequest.y_m,"y_m");
    spatialSize=[numel(z),numel(y),numel(x)];
else
    spatialSize=[numel(z),numel(x)];
end
phaseResult=swsynth.phase.compute(phaseRequest);
T=double(phaseResult.travel_time_s);
if ~isequal(size(T),spatialSize) || ~isreal(T) || ...
        any(~isfinite(T(:)))
    error("swsynth:InvalidPlaneContributionTravelTime", ...
        "Phase solver must return finite real travel times with the expected grid shape.");
end
polResult=swsynth.polarization.compute(polRequest);
p=double(polResult.vector_xyz);
if ~isequal(size(p),[1 3]) || any(~isfinite(p))
    error("swsynth:InvalidPlaneContributionPolarization", ...
        "Polarization must be a finite unit 1-by-3 vector.");
end

% Algebraic spatial phasor sign matches existing REQ synthetic backends.
theta=2*pi*freq*T+phase0;
scalarField=amplitude*exp(1i*theta);
if isfield(request,"attenuation_map_np_m")
    if geometry~="projected3d" || string(phaseRequest.method)~="eikonal"
        error("swsynth:UnsupportedAttenuation", ...
            "Spatially varying attenuation requires projected3d Eikonal.");
    end
    alphaMap=double(request.attenuation_map_np_m);
    optical=swsynth.propagation.attenuation.integrateEikonal2D( ...
        T,alphaMap,x(:).',z(:));
    scalarField=scalarField.*exp(-optical);
end
if isfield(request,"attenuation_np_m")
    alpha=double(request.attenuation_np_m);
    if ~isscalar(alpha)||~isfinite(alpha)||alpha<0
        error("swsynth:InvalidAttenuation","attenuation_np_m must be nonnegative.");
    end
    % Path length measured from the first wavefront touching the FOV.
    if geometry=="volumetric3d"
        [ZZ,YY,XX]=ndgrid(z,y,x);
        path=XX*d(1)+YY*d(2)+ZZ*d(3);
    else
        [ZZ,XX]=ndgrid(z,x);
        path=XX*d(1)+ZZ*d(3);
    end
    path=path-min(path(:));
    scalarField=scalarField.*exp(-alpha*path);
end
% MATLAB can collapse a zero-amplitude complex phasor to real zeros.
% Keep the harmonic-field contract complex even for the zero field.
scalarField=complex(real(scalarField),imag(scalarField));
polShape=[ones(1,numel(spatialSize)),3];
vectorField=reshape(scalarField,[spatialSize,1]).*reshape(p,polShape);
vectorField=complex(real(vectorField),imag(vectorField));

contribution=struct();
contribution.model="plane_wave";
contribution.geometry=geometry;
contribution.frequency_hz=freq;
% Include physical coordinate axes so accumulation can reject displaced
% grids even when their arrays happen to have identical dimensions.
contribution.x_m=x(:).';
contribution.z_m=z(:).';
if geometry=="volumetric3d"
    contribution.y_m=y(:).';
end
contribution.direction_xyz=d;
contribution.amplitude=amplitude;
contribution.phase_rad=phase0;
contribution.phase_sign=+1;
contribution.travel_time_s=T;
contribution.phase_solver=phaseResult.solver;
contribution.phase_diagnostics=phaseResult.diagnostics;
contribution.polarization_xyz=p;
contribution.polarization_diagnostics=polResult.diagnostics;
contribution.scalar_phasor=scalarField;
contribution.U_xyz=vectorField;
if geometry=="volumetric3d"
    contribution.output_convention="U(z,y,x,component_xyz)";
else
    contribution.output_convention="U(z,x,component_xyz)";
end
end

function x=checkGridAxis(v,name)
if ~isnumeric(v) || ~isvector(v) || isempty(v) || ~isreal(v) || ...
        any(~isfinite(v(:)))
    error("swsynth:InvalidPlaneContributionGrid", ...
        "%s must be a finite real spatial coordinate vector.",name);
end
x=double(v(:));
if any(diff(x)<=0)
    error("swsynth:InvalidPlaneContributionGrid", ...
        "%s must be strictly increasing.",name);
end
end

function yes=sameGeometry(value,target)
s=string(value);
if ~isscalar(s)
    yes=false;return;
end
if s=="planar2d";s="2d";end
yes=(s==target);
end

function yes=sameDirection(value,target)
candidate=double(value);
if ~isequal(size(candidate),[1 3]) || ~isreal(candidate) || ...
        any(~isfinite(candidate)) || norm(candidate)<=eps
    yes=false;return;
end
candidate=candidate/norm(candidate);
yes=norm(candidate-target)<=1e-10;
end
