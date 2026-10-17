function result = synthesize(scenario)
%SYNTHESIZE Modular harmonic vector shear-wave synthesis (V2).
% Required: geometry, domain, medium, harmonic, propagation.
% plane_wave requires incidence.direction_xyz and incidence.polarization.
% spherical_wave requires sources request for sources.prepare V2.
%
% Uses domain.buildGrid -> medium.buildMaps -> excitation.resolve ->
% one contribution per incident wave or physical parent source ->
% propagation.accumulate. Does not alter any legacy swsynth.run path.
%
% This version stores N component fields before accumulating them; large
% N/volumetric runs need a future streaming path to reduce peak memory.
arguments
    scenario (1,1) struct
end
for field=["geometry","domain","medium","harmonic","propagation"]
    if ~isfield(scenario,field)
        error("swsynth:SynthesisMissingField", ...
            "Missing V2 scenario field %s.",field);
    end
end
allowedScenario=["geometry","domain","medium","harmonic", ...
    "propagation","sources","incidence","execution","shear_noise"];
unknownScenario=setdiff(string(fieldnames(scenario)),allowedScenario);
if ~isempty(unknownScenario)
    error("swsynth:UnsupportedSynthesisField", ...
        "Unsupported V2 scenario field %s; use harmonic.frequency_hz for the harmonic drive.", ...
        unknownScenario(1));
end
geometry=canonicalGeometry(scenario.geometry);
if ~isstruct(scenario.domain) || ~isscalar(scenario.domain)
    error("swsynth:InvalidSynthesisDomain","domain must be a scalar struct.");
end
domainReq=scenario.domain;
if isfield(domainReq,"frequency_hz") || ...
        isfield(domainReq,"wavefield")
    error("swsynth:DuplicateSynthesisFrequency", ...
        "The computational domain cannot own the drive frequency.");
end
if isfield(domainReq,"geometry") && ...
        canonicalGeometry(domainReq.geometry)~=geometry
    error("swsynth:SynthesisGeometryMismatch", ...
        "domain.geometry must match scenario.geometry.");
end
domainReq.geometry=geometry;
grid=swsynth.domain.buildGrid(domainReq);
maps=swsynth.medium.buildMaps(grid,scenario.medium);
drive=swsynth.excitation.resolve(scenario.harmonic);

if ~isstruct(scenario.propagation) || ~isscalar(scenario.propagation) || ...
        ~isfield(scenario.propagation,"model")
    error("swsynth:InvalidSynthesisPropagation", ...
        "propagation.model must be plane_wave or spherical_wave.");
end
prop=scenario.propagation;
allowed=["model","phase_method","normalization", ...
    "geometric_decay_exponent","solver_options","attenuation"];
unknown=setdiff(string(fieldnames(prop)),allowed);
if ~isempty(unknown)
    error("swsynth:UnsupportedSynthesisOption", ...
        "Unsupported propagation option %s.",unknown(1));
end
model=string(prop.model);
if ~isscalar(model) || ...
        ~ismember(model,["plane_wave","spherical_wave"])
    error("swsynth:UnsupportedSynthesisModel", ...
        "Only plane_wave and spherical_wave are implemented.");
end
method="analytical";
if isfield(prop,"phase_method")
    method=string(prop.phase_method);
end
if ~isscalar(method) || ...
        ~ismember(method,["analytical","homogeneous_analytic","eikonal"])
    error("swsynth:UnsupportedSynthesisPhase", ...
        "Supported phase methods are analytical and directional eikonal.");
end
if model=="spherical_wave" && method=="eikonal" && geometry~="projected3d"
    error("swsynth:UnsupportedSynthesisPhase", ...
        "Spherical source Eikonal is not implemented.");
end
if model=="plane_wave" && method=="eikonal" && geometry=="2d"
    error("swsynth:UnsupportedSynthesisPhase", ...
        "Planar 2D directional Eikonal is not implemented.");
end
normalization="none";
if isfield(prop,"normalization")
    normalization=string(prop.normalization);
end
if ~isscalar(normalization) || ...
        ~ismember(normalization,["none","sqrt_count"])
    error("swsynth:InvalidWaveNormalization", ...
        "normalization must be none or sqrt_count.");
end
if model=="plane_wave"
    if isfield(prop,"geometric_decay_exponent")
        error("swsynth:UnsupportedSynthesisOption", ...
            "Geometric decay is a spherical-source option.");
    end
else
    if isfield(prop,"solver_options") && method~="eikonal"
        error("swsynth:UnsupportedSynthesisOption", ...
            "Spherical analytical phase does not use solver_options.");
    end
end

% Material maps are named by their spatial array convention.
% Do not touch cs_map_zx for volumetric3d: that field does not exist.
if geometry=="volumetric3d"
    mapCS=maps.cs_map_zyx;
else
    mapCS=maps.cs_map_zx;
end
background=double(maps.background_cs_m_s);
uniform=all(abs(mapCS(:)-background)<= ...
    1e-10*max(1,abs(background)));
if (method=="analytical" || method=="homogeneous_analytic") && ~uniform
    error("swsynth:SynthesisAnalyticalRequiresHomogeneousMedium", ...
        "Analytical travel time requires a homogeneous medium; use supported Eikonal for heterogeneous plane waves.");
end

% Homogeneous elastic/Kelvin-Voigt dispersion, opt-in only.
materialLoss=[];
propagationSpeed=background;
if isfield(prop,"attenuation") && isfield(prop.attenuation,"enabled") && prop.attenuation.enabled
    a=prop.attenuation;
    if method~="eikonal" && ~isfield(a,"constitutive")
        error("swsynth:InvalidAttenuation","attenuation.constitutive required.");
    end
    if method=="eikonal"
        if geometry~="projected3d"
            error("swsynth:UnsupportedAttenuation", ...
                "Heterogeneous attenuation currently supports projected3d plane-wave Eikonal.");
        end
        if ~isfield(scenario.medium,"viscoelastic")
            error("swsynth:InvalidViscoelasticMedium", ...
                "Heterogeneous Eikonal requires medium.viscoelastic.");
        end
        materialLoss=swsynth.medium.viscoelastic.buildMaps( ...
            swsynth.medium.validate(scenario.medium,geometry),maps,drive.frequency_hz);
        propagationSpeed=materialLoss.reference_phase_speed_m_s;
    else
        if ~uniform
            error("swsynth:UnsupportedAttenuation", ...
                "Heterogeneous attenuation requires Eikonal phase.");
        end
        materialLoss=swsynth.medium.viscoelastic.dispersion(a.constitutive,drive.frequency_hz);
        propagationSpeed=materialLoss.phase_speed_m_s;
    end
end
% parfor(...,0) runs serially, without starting a worker pool.
workerLimit=0;
if isfield(scenario,"execution")
    opts=scenario.execution;
    validFields=["parallel","num_workers"];
    if ~isstruct(opts) || ~isscalar(opts) || ...
            ~isempty(setdiff(string(fieldnames(opts)),validFields)) || ...
            ~isfield(opts,"parallel") || ~islogical(opts.parallel) || ...
            ~isscalar(opts.parallel)
        error("swsynth:InvalidExecution", ...
            "execution.parallel must be a logical scalar.");
    end
    w=inf; % Use all workers in the active/default MATLAB pool.
    if isfield(opts,"num_workers")
        w=double(opts.num_workers);
        if ~isnumeric(opts.num_workers) || ~isscalar(w) || ...
                ~isfinite(w) || w~=fix(w) || w<1
            error("swsynth:InvalidExecution", ...
                "execution.num_workers must be a positive integer.");
        end
    end
    if opts.parallel
        if exist("parpool","file")~=2
            error("swsynth:ParallelToolboxRequired", ...
                "Parallel execution requires Parallel Computing Toolbox.");
        end
        workerLimit=w;
    end
end

components={};
sourceBundle=[];
incidence=[];
switch model
    case "plane_wave"
        if isfield(scenario,"sources")
            error("swsynth:InvalidSynthesisComponents", ...
                "Plane-wave incidence is specified by incidence, not physical sources.");
        end
        if ~isfield(scenario,"incidence")
            error("swsynth:SynthesisMissingField", ...
                "Plane-wave synthesis requires scenario.incidence.");
        end
        % Projected3d plane-wave phase is currently evaluated at y=0.
        % Off-plane observation requires an explicit phase-reference shift
        % or a true 3D travel-time calculation, not silent reuse.
        if geometry=="projected3d" && grid.observation_y_m~=0
            error("swsynth:ProjectedPlaneWaveRequiresYZero", ...
                "Projected plane-wave phase currently supports observation_y_m=0 only.");
        end
        incidence=validateIncidence(scenario.incidence);
        count=size(incidence.direction_xyz,1);
        components=cell(count,1);
        % Draw random polarizations on the client, in a stable order,
        % before dispatching independent wave contributions to workers.
        sampledP=[];
        if string(incidence.polarization.policy)=="transverse_random"
            sampledP=zeros(count,3);
            for j=1:count
                polReq=incidence.polarization;
                polReq.model="plane_wave";
                polReq.geometry=geometry;
                polReq.direction_xyz=incidence.direction_xyz(j,:);
                polResult=swsynth.polarization.compute(polReq);
                sampledP(j,:)=polResult.vector_xyz;
            end
        end
        parfor (i=1:count,workerLimit)
            phaseRequest=struct("method",method, ...
                "reference_cs_m_s",propagationSpeed, ...
                "x_m",grid.x_m,"z_m",grid.z_m);
            if geometry=="volumetric3d"
                phaseRequest.y_m=grid.y_m;
                phaseRequest.cs_map_zyx=maps.cs_map_zyx;
            else
                phaseRequest.cs_map_zx=maps.cs_map_zx;
            end
            % The material speed map remains the nondispersive reference.
            % The homogeneous Kelvin-Voigt phase speed is frequency-dependent.
            % The medium's spatial homogeneity was already checked above.
            if ~isempty(materialLoss) && method~="eikonal"
                if isfield(phaseRequest,"cs_map_zx")
                    phaseRequest=rmfield(phaseRequest,"cs_map_zx");
                end
                if isfield(phaseRequest,"cs_map_zyx")
                    phaseRequest=rmfield(phaseRequest,"cs_map_zyx");
                end
            end
            if ~isempty(materialLoss) && method=="eikonal"
                if abs(incidence.direction_xyz(i,2))>1e-10
                    error("swsynth:UnsupportedAttenuationDirection", ...
                        "Heterogeneous 2D ray tracing requires in-plane incidence.");
                end
                phaseRequest.cs_map_zx=materialLoss.phase_speed;
            end
            if method=="eikonal" && isfield(prop,"solver_options")
                phaseRequest.solver_options=prop.solver_options;
            end
            pol=incidence.polarization;
            if ~isempty(sampledP)
                pol=struct("policy","transverse_explicit", ...
                    "explicit_polarization_xyz",sampledP(i,:));
            elseif string(pol.policy)=="transverse_explicit"
                explicit=double(pol.explicit_polarization_xyz);
                if size(explicit,1)==1
                    pol.explicit_polarization_xyz=explicit;
                else
                    pol.explicit_polarization_xyz=explicit(i,:);
                end
            end
            req=struct("geometry",geometry, ...
                "direction_xyz",incidence.direction_xyz(i,:), ...
                "frequency_hz",drive.frequency_hz, ...
                "amplitude",incidence.relative_amplitude(i), ...
                "phase_rad",incidence.phase_rad(i), ...
                "phase",phaseRequest,"polarization",pol);
            if ~isempty(materialLoss)
                if method=="eikonal"
                    req.attenuation_map_np_m=materialLoss.attenuation_np_m;
                else
                    req.attenuation_np_m=materialLoss.attenuation_np_m;
                end
            end
            components{i}=swsynth.propagation.plane_wave.computeContribution(req);
        end
    case "spherical_wave"
        if isfield(scenario,"incidence")
            error("swsynth:InvalidSynthesisComponents", ...
                "Spherical sources are specified by sources, not incidence.");
        end
        if ~isfield(scenario,"sources") || ...
                ~isstruct(scenario.sources) || ...
                ~isscalar(scenario.sources)
            error("swsynth:SynthesisMissingField", ...
                "Spherical-wave synthesis requires scenario.sources request.");
        end
        sourceReq=scenario.sources;
        if isfield(sourceReq,"geometry") && ...
                canonicalGeometry(sourceReq.geometry)~=geometry
            error("swsynth:SynthesisGeometryMismatch", ...
                "Physical source geometry differs from scenario geometry.");
        end
        if isfield(sourceReq,"frequency_hz") || ...
                (isfield(sourceReq,"excitation") && ...
                 isstruct(sourceReq.excitation) && ...
                 isfield(sourceReq.excitation,"frequency_hz"))
            error("swsynth:DuplicateSynthesisFrequency", ...
                "Specify frequency only as scenario.harmonic.frequency_hz.");
        end
        if geometry=="volumetric3d"
            if isfield(sourceReq,"observation_y_m")
                error("swsynth:SynthesisGeometryMismatch", ...
                    "Volumetric source geometry does not have an observation_y_m plane.");
            end
        elseif isfield(sourceReq,"observation_y_m") && ...
                ~isequal(double(sourceReq.observation_y_m),grid.observation_y_m)
            error("swsynth:SynthesisGeometryMismatch", ...
                "Source and computational observation planes must match.");
        end
        sourceReq.geometry=geometry;
        % Slice geometries share the domain observation plane. Volume
        % geometry has no observation_y_m scalar at all.
        if geometry~="volumetric3d"
            sourceReq.observation_y_m=grid.observation_y_m;
        end
        sourceBundle=swsynth.sources.prepare(sourceReq);
        count=double(sourceBundle.count);
        components=cell(count,1);
        exponent=0;
        if isfield(prop,"geometric_decay_exponent")
            exponent=prop.geometric_decay_exponent;
        end
        parfor (i=1:count,workerLimit)
            req=struct("source_bundle",sourceBundle, ...
                "source_id",i,"frequency_hz",drive.frequency_hz, ...
                "phase",struct("method",method, ...
                    "reference_cs_m_s",propagationSpeed), ...
                "x_m",grid.x_m,"z_m",grid.z_m, ...
                "geometric_decay_exponent",exponent);
            if geometry=="volumetric3d"
                req.y_m=grid.y_m;
            else
                req.observation_y_m=grid.observation_y_m;
            end
            if ~isempty(materialLoss)
                if method=="eikonal"
                    req.phase_speed_map_zx=materialLoss.phase_speed;
                    req.attenuation_map_np_m=materialLoss.attenuation_np_m;
                    % Exact planar loss integration is available when the
                    % material geometry is an unambiguous single sharp bilayer.
                    if numel(scenario.medium.objects)==1
                        interfaceObj=scenario.medium.objects{1};
                        if string(interfaceObj.type)=="bilayer" && ...
                                (~isfield(interfaceObj,"edge_sigma_m") || ...
                                interfaceObj.edge_sigma_m==0)
                            objectDisp=swsynth.medium.viscoelastic.dispersion( ...
                                interfaceObj.viscoelastic,drive.frequency_hz);
                            angle=double(interfaceObj.normal_angle_rad);
                            req.attenuation_interface=struct( ...
                                "normal_xyz",[cos(angle),0,sin(angle)], ...
                                "offset_m",double(interfaceObj.offset_m), ...
                                "alpha_negative_np_m", ...
                                materialLoss.background.attenuation_np_m, ...
                                "alpha_positive_np_m",objectDisp.attenuation_np_m);
                        end
                    end
                    if isfield(prop,"solver_options")
                        req.solver_options=prop.solver_options;
                    end
                else
                    req.attenuation_np_m=materialLoss.attenuation_np_m;
                end
            end
            components{i}=swsynth.propagation.spherical.point_source.computeContribution(req);
        end
end

wavefield=swsynth.propagation.accumulate(components, ...
    struct("normalization",normalization));
result=struct();
result.schema_version="2.0";
result.model=model;
result.geometry=geometry;
result.domain=grid;
result.medium=maps;
result.excitation=drive;
result.propagation=struct( ...
    "model",model,"phase_method",method, ...
    "normalization",normalization, ...
    "reference_cs_m_s",background, ...
    "spatial_phase_sign",wavefield.phase_sign);
if model=="spherical_wave"
    result.propagation.geometric_decay_exponent=exponent;
elseif method=="eikonal" && isfield(prop,"solver_options")
    result.propagation.solver_options=prop.solver_options;
end
if ~isempty(materialLoss)
    result.propagation.material_dispersion=materialLoss;
end
result.component_count=wavefield.component_count;
result.field=wavefield;
result.U_xyz=wavefield.U_xyz;
result.quantity=drive.quantity;
result.sources=sourceBundle;
result.incidence=incidence;
end

function inc=validateIncidence(value)
if ~isstruct(value) || ~isscalar(value) || ...
        ~isfield(value,"direction_xyz") || ...
        ~isfield(value,"polarization")
    error("swsynth:InvalidSynthesisIncidence", ...
        "incidence needs direction_xyz and polarization.");
end
allowed=["direction_xyz","polarization","relative_amplitude","phase_rad"];
unknown=setdiff(string(fieldnames(value)),allowed);
if ~isempty(unknown)
    error("swsynth:UnsupportedSynthesisIncidence", ...
        "Unsupported incidence field %s.",unknown(1));
end
d=value.direction_xyz;
if ~isnumeric(d) || ~ismatrix(d) || size(d,2)~=3 || ...
        isempty(d) || ~isreal(d) || any(~isfinite(d(:))) || ...
        any(vecnorm(double(d),2,2)<=eps)
    error("swsynth:InvalidSynthesisIncidence", ...
        "direction_xyz must be finite nonzero N-by-3 vectors.");
end
n=size(d,1);
if ~isstruct(value.polarization) || ...
        ~isscalar(value.polarization) || ...
        ~isfield(value.polarization,"policy")
    error("swsynth:InvalidSynthesisIncidence", ...
        "incidence.polarization.policy is required.");
end
pol=value.polarization;
if string(pol.policy)=="transverse_explicit"
    if ~isfield(pol,"explicit_polarization_xyz") || ...
            ~isnumeric(pol.explicit_polarization_xyz) || ...
            size(pol.explicit_polarization_xyz,2)~=3 || ...
            ~ismember(size(pol.explicit_polarization_xyz,1),[1,n])
        error("swsynth:InvalidSynthesisIncidence", ...
            "Explicit polarizations must have one row or N rows.");
    end
end
amp=ones(n,1);
if isfield(value,"relative_amplitude")
    amp=value.relative_amplitude;
end
phase=zeros(n,1);
if isfield(value,"phase_rad")
    phase=value.phase_rad;
end
amp=validatePerWave(amp,n,true,"relative_amplitude");
phase=validatePerWave(phase,n,false,"phase_rad");
inc=struct();
inc.direction_xyz=double(d)./vecnorm(double(d),2,2);
inc.relative_amplitude=amp;
inc.phase_rad=phase;
inc.polarization=pol;
end

function values=validatePerWave(input,n,nonnegative,name)
if ~isnumeric(input) || ~isreal(input) || ...
        ~isvector(input) || isempty(input) || ...
        any(~isfinite(input(:)))
    error("swsynth:InvalidSynthesisIncidence", ...
        "%s must contain finite real values.",name);
end
values=double(input(:));
if numel(values)==1
    values=repmat(values,n,1);
elseif numel(values)~=n
    error("swsynth:InvalidSynthesisIncidence", ...
        "%s must contain one or N values.",name);
end
if nonnegative && any(values<0)
    error("swsynth:InvalidSynthesisIncidence", ...
        "%s must be nonnegative.",name);
end
end

function geometry=canonicalGeometry(value)
geometry=string(value);
if ~isscalar(geometry)
    error("swsynth:InvalidSynthesisGeometry", ...
        "geometry must be a scalar.");
end
if geometry=="planar2d";geometry="2d";end
if ~ismember(geometry,["2d","projected3d","volumetric3d"])
    error("swsynth:InvalidSynthesisGeometry", ...
        "Unsupported geometry %s.",geometry);
end
end
