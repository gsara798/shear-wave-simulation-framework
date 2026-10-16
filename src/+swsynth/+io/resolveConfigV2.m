function [scenario,meta] = resolveConfigV2(config)
%RESOLVECONFIGV2 Resolve versioned swsynth V2 JSON configuration.
% Config is a V2 scenario plus schema_version, scenario/seed, measurement.
% Dry-run validates grid/material/frequency and supported routing WITHOUT
% generating wavefields or consuming RNG.
arguments
    config (1,1) struct
end
if ~isfield(config,"schema_version") || ...
        string(config.schema_version)~="2.0"
    error("swsynth:V2ConfigSchemaRequired", ...
        "V2 swsynth configuration requires schema_version=2.0.");
end
allowed=["schema_version","scenario","seed","measurement", ...
    "geometry","domain","medium","harmonic","propagation", ...
    "incidence","sources","execution","shear_noise"];
extra=setdiff(string(fieldnames(config)),allowed);
if ~isempty(extra)
    error("swsynth:V2ConfigUnexpectedField", ...
        "Unsupported V2 configuration field %s.",extra(1));
end
required=["geometry","domain","medium","harmonic","propagation"];
for f=required
    if ~isfield(config,f)
        error("swsynth:V2ConfigMissingField","Missing %s.",f);
    end
end
scenario=rmfield(config,intersect(string(fieldnames(config)), ...
    ["schema_version","scenario","seed","measurement"]));
% jsondecode may return a flat JSON XYZ array as a 3-by-1 column.
% Normalize only known XYZ vector fields here; don't transpose N-by-3
% matrices or mutate the general MATLAB synthesis API.
scenario=normalizeJsonXYZVectors(scenario);
% Expand deterministic direction specifications into the explicit V2 incidence API.
if isfield(scenario,"incidence") && isstruct(scenario.incidence) && ...
        isscalar(scenario.incidence) && isfield(scenario.incidence,"sampling")
    inc=scenario.incidence;
    if isfield(inc,"direction_xyz")
        error("swsynth:InvalidDirectionSampling", ...
            "Choose incidence.sampling or incidence.direction_xyz, not both.");
    end
    inc.direction_xyz=swsynth.incidence.sampleDirections( ...
        inc.sampling,string(scenario.geometry));
    inc=rmfield(inc,"sampling");
    scenario.incidence=inc;
end
% Resolve optional phase policy for plane-wave incidence using an isolated
% local RNG stream; DryRun and repeated runs do not modify global RNG.
if isfield(scenario,"incidence") && isstruct(scenario.incidence) && ...
        isscalar(scenario.incidence) && isfield(scenario.incidence,"phase_policy")
    inc=scenario.incidence;
    policy=string(inc.phase_policy);
    if ~isscalar(policy) || ~ismember(policy,["fixed","random_uniform"])
        error("swsynth:V2InvalidPhasePolicy", ...
            "incidence.phase_policy must be fixed or random_uniform.");
    end
    if policy=="random_uniform"
        if isfield(inc,"phase_rad")
            error("swsynth:V2InvalidPhasePolicy", ...
                "Use phase_policy=random_uniform or phase_rad, not both.");
        end
        if ~isfield(config,"seed") || ~isnumeric(config.seed) || ...
                ~isscalar(config.seed) || ~isfinite(config.seed) || ...
                config.seed<0 || config.seed~=fix(config.seed) || ...
                config.seed>2^32-1
            error("swsynth:V2SeedRequired", ...
                "Random incident phases require a valid config.seed.");
        end
        n=size(inc.direction_xyz,1);
        stream=RandStream("mt19937ar","Seed",double(config.seed));
        inc.phase_rad=2*pi*rand(stream,n,1);
    end
    inc=rmfield(inc,"phase_policy");
    scenario.incidence=inc;
end
% JSON arrays of material objects become MATLAB struct arrays; the medium
% contract expects a cell array of scalar struct objects.
if isstruct(scenario.medium) && isscalar(scenario.medium) && ...
        isfield(scenario.medium,"objects")
    objects=scenario.medium.objects;
    if isempty(objects)
        scenario.medium.objects={};
    elseif isstruct(objects)
        scenario.medium.objects=reshape(num2cell(objects),[],1);
    elseif ~iscell(objects)
        error("swsynth:V2InvalidMediumObjects", ...
            "medium.objects must be a JSON array of objects.");
    end
end
geometry=string(scenario.geometry);
if geometry=="planar2d";geometry="2d";end
if ~isscalar(geometry) || ...
        ~ismember(geometry,["2d","projected3d","volumetric3d"])
    error("swsynth:V2InvalidGeometry", ...
        "Unsupported scenario geometry.");
end
scenario.geometry=geometry;
if ~isstruct(scenario.domain) || ~isscalar(scenario.domain)
    error("swsynth:V2InvalidDomain","domain must be a scalar struct.");
end
gridReq=scenario.domain;
if isfield(gridReq,"geometry") && ...
        string(gridReq.geometry)~=geometry
    error("swsynth:V2ConfigGeometryMismatch", ...
        "domain.geometry conflicts with scenario.geometry.");
end
gridReq.geometry=geometry;
grid=swsynth.domain.buildGrid(gridReq);
maps=swsynth.medium.buildMaps(grid,scenario.medium);
drive=swsynth.excitation.resolve(scenario.harmonic);

if ~isstruct(scenario.propagation) || ...
        ~isscalar(scenario.propagation) || ...
        ~isfield(scenario.propagation,"model")
    error("swsynth:V2InvalidPropagation", ...
        "propagation.model is required.");
end
model=string(scenario.propagation.model);
if ~isscalar(model) || ...
        ~ismember(model,["plane_wave","spherical_wave"])
    error("swsynth:V2InvalidPropagation","Unsupported propagation model.");
end
phaseMethod="analytical";
if isfield(scenario.propagation,"phase_method")
    phaseMethod=string(scenario.propagation.phase_method);
end
if ~isscalar(phaseMethod) || ~ismember(phaseMethod, ...
        ["analytical","homogeneous_analytic","eikonal"])
    error("swsynth:V2InvalidPropagation", ...
        "Unsupported phase method.");
end
if phaseMethod=="eikonal" && (model=="spherical_wave" || geometry=="2d")
    error("swsynth:V2UnsupportedPhase", ...
        "Eikonal is supported only for incident plane waves in projected3d/volumetric3d.");
end
if geometry=="projected3d" && model=="plane_wave" && ...
        grid.observation_y_m~=0
    error("swsynth:V2UnsupportedPlane", ...
        "Projected plane-wave synthesis currently requires observation_y_m=0.");
end
if isfield(scenario.propagation,"attenuation")
    a=scenario.propagation.attenuation;
    if ~isstruct(a) || ~isscalar(a) || ~isfield(a,"enabled") || ...
            ~islogical(a.enabled) || ~isscalar(a.enabled) || ...
            ~isempty(setdiff(string(fieldnames(a)),["enabled","constitutive"]))
        error("swsynth:InvalidAttenuation","Invalid propagation.attenuation.");
    end
    if a.enabled
        if ~isfield(a,"constitutive") || phaseMethod=="eikonal"
            error("swsynth:UnsupportedAttenuation", ...
                "Stage 1 attenuation requires homogeneous analytical propagation.");
        end
        swsynth.medium.viscoelastic.dispersion(a.constitutive,drive.frequency_hz);
        if geometry=="volumetric3d"
            localCS=maps.cs_map_zyx;
        else
            localCS=maps.cs_map_zx;
        end
        if any(abs(localCS(:)-maps.background_cs_m_s)>1e-10)
            error("swsynth:UnsupportedAttenuation","Heterogeneous attenuation is not yet supported.");
        end
    end
end
if model=="plane_wave"
    if ~isfield(scenario,"incidence") || isfield(scenario,"sources")
        error("swsynth:V2InvalidIncidentWaves", ...
            "Plane waves require incidence, and may not have sources.");
    end
    validateIncidenceWithoutSynthesis(scenario.incidence,geometry);
else
    if ~isfield(scenario,"sources") || isfield(scenario,"incidence")
        error("swsynth:V2InvalidPointSources", ...
            "Spherical waves require sources, and may not have incidence.");
    end
    validateSourcesWithoutSynthesis(scenario.sources,geometry,grid);
end
if geometry=="volumetric3d"
    cs=maps.cs_map_zyx;
else
    cs=maps.cs_map_zx;
end
background=maps.background_cs_m_s;
if phaseMethod~="eikonal" && ...
        any(abs(cs(:)-background)>1e-10*max(1,abs(background)))
    error("swsynth:V2AnalyticalRequiresHomogeneous", ...
        "Heterogeneous elastic media require supported plane-wave Eikonal.");
end

if isfield(config,"shear_noise")
    swsynth.noise.validateConfig(config.shear_noise);
    if config.shear_noise.enabled && ~isfield(config.shear_noise,"seed") && ~isfield(config,"seed")
        error("swsynth:ShearNoiseSeedRequired", ...
            "Enabled shear noise requires shear_noise.seed or config.seed.");
    end
end

meta=struct();
meta.scenario_name="swsynth_v2";
if isfield(config,"scenario")
    meta.scenario_name=string(config.scenario);
    if ~isscalar(meta.scenario_name) || strlength(meta.scenario_name)==0
        error("swsynth:V2InvalidScenarioName", ...
            "scenario must be a nonempty scalar string.");
    end
end
meta.seed=[];
if isfield(config,"seed")
    seed=config.seed;
    if ~isnumeric(seed) || ~isscalar(seed) || ~isreal(seed) || ...
            ~isfinite(seed) || seed<0 || seed~=fix(seed) || seed>2^32-1
        error("swsynth:V2InvalidSeed", ...
            "seed must be an integer in [0,2^32-1].");
    end
    meta.seed=double(seed);
end
if isempty(meta.seed) && usesRandomness(scenario)
    error("swsynth:V2SeedRequired", ...
        "Stochastic V2 JSON configurations must specify seed.");
end
meta.measurement_axis_xyz=[0 0 1];
if isfield(config,"measurement")
    m=config.measurement;
    if ~isstruct(m) || ~isscalar(m) || ...
            ~isfield(m,"axis_xyz") || ...
            ~isequal(string(fieldnames(m)),"axis_xyz")
        error("swsynth:V2InvalidMeasurement", ...
            "measurement must have exactly axis_xyz.");
    end
    axis=double(m.axis_xyz);
    if ~isnumeric(m.axis_xyz) || ~isvector(axis) || ...
            numel(axis)~=3
        error("swsynth:V2InvalidMeasurement", ...
            "measurement.axis_xyz must have three numeric components.");
    end
    axis=reshape(axis,1,3);
    if ~isreal(axis) || ...
            any(~isfinite(axis)) || norm(axis)<=eps
        error("swsynth:V2InvalidMeasurement", ...
            "measurement.axis_xyz must be finite nonzero 1-by-3.");
    end
    meta.measurement_axis_xyz=axis/norm(axis);
end
meta.geometry=geometry;
meta.dimension=2+double(geometry=="volumetric3d");
meta.model=model;
meta.phase_method=phaseMethod;
meta.frequency_hz=drive.frequency_hz;
meta.background_cs_m_s=background;
meta.material_object_count=0;
if isfield(scenario.medium,"objects")
    meta.material_object_count=numel(scenario.medium.objects);
end
meta.spatial_size=grid.spatial_size;
meta.validation_scope="configuration_material_and_routing";
meta.valid=true;
end

function validateIncidenceWithoutSynthesis(inc,geometry)
if ~isstruct(inc) || ~isscalar(inc) || ...
        ~isfield(inc,"direction_xyz") || ~isfield(inc,"polarization")
    error("swsynth:V2InvalidIncidentWaves", ...
        "incidence requires direction_xyz and polarization.");
end
allowed=["direction_xyz","polarization","relative_amplitude","phase_rad"];
if ~isempty(setdiff(string(fieldnames(inc)),allowed))
    error("swsynth:V2InvalidIncidentWaves", ...
        "Unsupported incidence configuration property.");
end
d=inc.direction_xyz;
if ~isnumeric(d) || ~ismatrix(d) || size(d,2)~=3 || ...
        isempty(d) || any(~isfinite(d(:))) || ~isreal(d) || ...
        any(vecnorm(d,2,2)<=eps)
    error("swsynth:V2InvalidIncidentWaves", ...
        "direction_xyz must contain nonzero finite N-by-3 vectors.");
end
n=size(d,1);
if geometry=="2d" && any(abs(d(:,2))>1e-10)
    error("swsynth:V2InvalidIncidentWaves", ...
        "Planar directions must have zero out-of-plane component.");
end
for f=["relative_amplitude","phase_rad"]
    if isfield(inc,f)
        values=inc.(f);
        if ~isnumeric(values) || ~isreal(values) || ...
                ~isvector(values) || ...
                ~ismember(numel(values),[1,n]) || ...
                any(~isfinite(values(:)))
            error("swsynth:V2InvalidIncidentWaves", ...
                "%s must contain one or N finite real values.",f);
        end
        if f=="relative_amplitude" && any(values(:)<0)
            error("swsynth:V2InvalidIncidentWaves", ...
                "Relative amplitudes must be nonnegative.");
        end
    end
end
pol=inc.polarization;
if ~isstruct(pol) || ~isscalar(pol) || ~isfield(pol,"policy")
    error("swsynth:V2InvalidIncidentWaves", ...
        "polarization.policy is required.");
end
if string(pol.policy)=="transverse_explicit" && ...
        isfield(pol,"explicit_polarization_xyz") && ...
        size(pol.explicit_polarization_xyz,1)==1 && n>1
    pol.explicit_polarization_xyz=repmat( ...
        pol.explicit_polarization_xyz,n,1);
end
pol.model="plane_wave";
pol.geometry=geometry;
pol.direction_xyz=d;
swsynth.polarization.validate(pol);
end

function validateSourcesWithoutSynthesis(source,geometry,grid)
if ~isstruct(source) || ~isscalar(source) || ...
        ~isfield(source,"positions") || ...
        ~isfield(source,"excitation")
    error("swsynth:V2InvalidPointSources", ...
        "sources needs positions and excitation.");
end
% Use independent local streams: dry-run checks geometry/forces/positions
% and coherent apertures without modifying the global RNG or wavefields.
req=source;
req.geometry=geometry;
if geometry~="volumetric3d"
    req.observation_y_m=grid.observation_y_m;
end
if isfield(req,"streams")
    error("swsynth:V2ConfigUnexpectedField", ...
        "JSON configurations must not contain RandStream objects.");
end
req.streams=struct( ...
    "positions",RandStream("mt19937ar","Seed",401), ...
    "excitation",RandStream("mt19937ar","Seed",402));
swsynth.sources.prepare(req);
end

function required=usesRandomness(s)
required=false;
if string(s.propagation.model)=="plane_wave"
    if isfield(s.incidence,"polarization") && ...
            isfield(s.incidence.polarization,"policy") && ...
            string(s.incidence.polarization.policy)=="transverse_random"
        required=true;
    end
    return;
end
positions=s.sources.positions;
if isfield(positions,"method")
    method=string(positions.method);
    if method~="explicit"
        required=true;
    end
elseif ~isfield(positions,"position_xyz_m")
    required=true;
end
ex=s.sources.excitation;
for name=["force_policy","amplitude_policy","phase_policy"]
    if isfield(ex,name) && ...
            startsWith(string(ex.(name)),"random_")
        required=true;
    end
end
end

function scenario=normalizeJsonXYZVectors(scenario)
if isfield(scenario,"domain") && isstruct(scenario.domain) && isscalar(scenario.domain) && ...
        isfield(scenario.domain,"origin_xyz_m")
    scenario.domain.origin_xyz_m=asXYZRowIfVector(scenario.domain.origin_xyz_m);
end
% Only convert single 3-element XYZ JSON arrays to MATLAB [1,3].
% Leave valid N-by-3 multiwave/multisource arrays intact.
if isfield(scenario,"incidence") && isstruct(scenario.incidence) && ...
        isscalar(scenario.incidence)
    inc=scenario.incidence;
    if isfield(inc,"direction_xyz")
        inc.direction_xyz=asXYZRowIfVector(inc.direction_xyz);
    end
    if isfield(inc,"polarization") && isstruct(inc.polarization) && ...
            isscalar(inc.polarization)
        for name=["explicit_polarization_xyz","reference_axis_xyz"]
            if isfield(inc.polarization,name)
                inc.polarization.(name)= ...
                    asXYZRowIfVector(inc.polarization.(name));
            end
        end
    end
    scenario.incidence=inc;
end
if ~isfield(scenario,"sources") || ~isstruct(scenario.sources) || ...
        ~isscalar(scenario.sources)
    return
end
sources=scenario.sources;
if isfield(sources,"positions") && isstruct(sources.positions) && ...
        isscalar(sources.positions)
    positions=sources.positions;
    for name=["center_xyz_m","position_xyz_m"]
        if isfield(positions,name)
            positions.(name)=asXYZRowIfVector(positions.(name));
        end
    end
    sources.positions=positions;
end
if isfield(sources,"excitation") && ...
        isstruct(sources.excitation) && isscalar(sources.excitation)
    ex=sources.excitation;
    if isfield(ex,"force_direction_xyz")
        ex.force_direction_xyz= ...
            asXYZRowIfVector(ex.force_direction_xyz);
    end
    sources.excitation=ex;
end
if isfield(sources,"aperture") && isstruct(sources.aperture)
    aperture=sources.aperture;
    for i=1:numel(aperture)
        if isfield(aperture(i),"axis_xyz")
            aperture(i).axis_xyz= ...
                asXYZRowIfVector(aperture(i).axis_xyz);
        end
    end
    sources.aperture=aperture;
end
scenario.sources=sources;
end

function value=asXYZRowIfVector(value)
if isnumeric(value) && isvector(value) && numel(value)==3
    value=reshape(value,1,3);
end
end
