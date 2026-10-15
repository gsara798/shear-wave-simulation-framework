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
    "geometry","domain","medium","excitation","propagation", ...
    "incidence","sources"];
extra=setdiff(string(fieldnames(config)),allowed);
if ~isempty(extra)
    error("swsynth:V2ConfigUnexpectedField", ...
        "Unsupported V2 configuration field %s.",extra(1));
end
required=["geometry","domain","medium","excitation","propagation"];
for f=required
    if ~isfield(config,f)
        error("swsynth:V2ConfigMissingField","Missing %s.",f);
    end
end
scenario=rmfield(config,intersect(string(fieldnames(config)), ...
    ["schema_version","scenario","seed","measurement"]));
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
drive=swsynth.excitation.resolve(scenario.excitation);

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
if model=="plane_wave"
    if ~isfield(scenario,"incidence") || isfield(scenario,"sources")
        error("swsynth:V2InvalidIncidentWaves", ...
            "Plane waves require incidence, and may not have sources.");
    end
else
    if ~isfield(scenario,"sources") || isfield(scenario,"incidence")
        error("swsynth:V2InvalidPointSources", ...
            "Spherical waves require sources, and may not have incidence.");
    end
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
    if ~isequal(size(axis),[1 3]) || ~isreal(axis) || ...
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
