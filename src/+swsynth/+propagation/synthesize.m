function result = synthesize(scenario)
%SYNTHESIZE Modular harmonic vector shear-wave synthesis (V2).
% Required: geometry, domain, medium, excitation, propagation.
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
for field=["geometry","domain","medium","excitation","propagation"]
    if ~isfield(scenario,field)
        error("swsynth:SynthesisMissingField", ...
            "Missing V2 scenario field %s.",field);
    end
end
allowedScenario=["geometry","domain","medium","excitation", ...
    "propagation","sources","incidence"];
unknownScenario=setdiff(string(fieldnames(scenario)),allowedScenario);
if ~isempty(unknownScenario)
    error("swsynth:UnsupportedSynthesisField", ...
        "Unsupported V2 scenario field %s; use excitation.frequency_hz for the harmonic drive.", ...
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
drive=swsynth.excitation.resolve(scenario.excitation);

if ~isstruct(scenario.propagation) || ~isscalar(scenario.propagation) || ...
        ~isfield(scenario.propagation,"model")
    error("swsynth:InvalidSynthesisPropagation", ...
        "propagation.model must be plane_wave or spherical_wave.");
end
prop=scenario.propagation;
allowed=["model","phase_method","normalization", ...
    "geometric_decay_exponent","solver_options"];
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
if model=="spherical_wave" && method=="eikonal"
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
    if isfield(prop,"solver_options")
        error("swsynth:UnsupportedSynthesisOption", ...
            "Spherical analytical phase does not use solver_options.");
    end
end

mapCS=maps.cs_map_zx;
if geometry=="volumetric3d"
    mapCS=maps.cs_map_zyx;
end
background=double(maps.background_cs_m_s);
uniform=all(abs(mapCS(:)-background)<= ...
    1e-10*max(1,abs(background)));
if (method=="analytical" || method=="homogeneous_analytic") && ~uniform
    error("swsynth:SynthesisAnalyticalRequiresHomogeneousMedium", ...
        "Analytical travel time requires a homogeneous medium; use supported Eikonal for heterogeneous plane waves.");
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
        for i=1:count
            phaseRequest=struct("method",method, ...
                "reference_cs_m_s",background, ...
                "x_m",grid.x_m,"z_m",grid.z_m);
            if geometry=="volumetric3d"
                phaseRequest.y_m=grid.y_m;
                phaseRequest.cs_map_zyx=maps.cs_map_zyx;
            else
                phaseRequest.cs_map_zx=maps.cs_map_zx;
            end
            if method=="eikonal" && isfield(prop,"solver_options")
                phaseRequest.solver_options=prop.solver_options;
            end
            pol=incidence.polarization;
            if string(pol.policy)=="transverse_explicit"
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
                "Specify frequency only as scenario.excitation.frequency_hz.");
        end
        if geometry=="2d" && isfield(sourceReq,"observation_y_m") && ...
                ~isequal(double(sourceReq.observation_y_m),grid.observation_y_m)
            error("swsynth:SynthesisGeometryMismatch", ...
                "Planar source and observation y positions must match.");
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
        for i=1:count
            req=struct("source_bundle",sourceBundle, ...
                "source_id",i,"frequency_hz",drive.frequency_hz, ...
                "phase",struct("method",method, ...
                    "reference_cs_m_s",background), ...
                "x_m",grid.x_m,"z_m",grid.z_m, ...
                "geometric_decay_exponent",exponent);
            if geometry=="volumetric3d"
                req.y_m=grid.y_m;
            else
                req.observation_y_m=grid.observation_y_m;
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
    "spatial_phase_sign",wavefield.phase_sign);
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
