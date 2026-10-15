function sample = buildWavefieldSampleV2(result, scenario, options)
%BUILDWAVEFIELDSAMPLEV2 Adapt modular vector synthesis to wavefield_sample v1.
% Does NOT change the legacy swsynth.run output or create a new schema.
%
% result:   swsynth.propagation.synthesize(scenario), vector U_xyz
% scenario: original V2 request (preserved in provenance)
% options.measurement_axis_xyz: default [0 0 1], unit direction after
%   normalization; only a scalar projection, not ultrasound simulation.
% options.scenario_name: identifier; default "swsynth_v2".
% options.seed: optional user-provided seed, never invented.
% options.commit: optional Git SHA, never inferred.
%
% Example:
%   result=swsynth.propagation.synthesize(scenario);
%   wavefield_sample=swsynth.io.buildWavefieldSampleV2(result,scenario);
%   save("wavefield_sample.mat","wavefield_sample","-v7.3")
%
% k_map is the *local material* 2*pi*f/cs, not |grad(phase)| of an
% Eikonal solution and not the k inferred from an observed spectrum.
arguments
    result (1,1) struct
    scenario (1,1) struct
    options (1,1) struct = struct()
end

needed=["geometry","domain","medium","excitation","propagation", ...
    "U_xyz","quantity","model"];
for field=needed
    if ~isfield(result,field)
        error("swsynth:InvalidV2SampleResult", ...
            "V2 result is missing %s.",field);
    end
end
if ~isfield(result.domain,"geometry") || ...
        string(result.domain.geometry)~=string(result.geometry)
    error("swsynth:InvalidV2SampleResult", ...
        "Inconsistent result geometry and domain.");
end
if ~isfield(scenario,"geometry") || ...
        canonical(scenario.geometry)~=canonical(result.geometry)
    error("swsynth:V2SampleScenarioMismatch", ...
        "Original scenario geometry must match the synthesized result.");
end
if ~isfield(scenario,"excitation") || ...
        ~isstruct(scenario.excitation) || ...
        ~isfield(scenario.excitation,"frequency_hz") || ...
        ~isequal(double(scenario.excitation.frequency_hz), ...
                  double(result.excitation.frequency_hz))
    error("swsynth:V2SampleScenarioMismatch", ...
        "Original scenario frequency must match the synthesized result.");
end

allowedOptions=["measurement_axis_xyz","scenario_name","seed","commit"];
unknown=setdiff(string(fieldnames(options)),allowedOptions);
if ~isempty(unknown)
    error("swsynth:InvalidV2SampleOptions", ...
        "Unknown V2 sample option %s.",unknown(1));
end
axisXYZ=[0 0 1];
if isfield(options,"measurement_axis_xyz")
    axisXYZ=double(options.measurement_axis_xyz);
end
if ~isequal(size(axisXYZ),[1 3]) || any(~isfinite(axisXYZ)) || ...
        ~isreal(axisXYZ) || norm(axisXYZ)<=eps
    error("swsynth:InvalidV2SampleMeasurement", ...
        "measurement_axis_xyz must be a finite nonzero 1-by-3 vector.");
end
axisXYZ=axisXYZ/norm(axisXYZ);
scenarioName="swsynth_v2";
if isfield(options,"scenario_name")
    scenarioName=string(options.scenario_name);
    if ~isscalar(scenarioName) || strlength(scenarioName)==0
        error("swsynth:InvalidV2SampleOptions", ...
            "scenario_name must be a nonempty scalar string.");
    end
end
commit="";
if isfield(options,"commit")
    commit=string(options.commit);
    if ~isscalar(commit)
        error("swsynth:InvalidV2SampleOptions", ...
            "commit must be a scalar string.");
    end
end
seed=[];
if isfield(options,"seed")
    seed=options.seed;
    if ~isnumeric(seed) || ~isscalar(seed) || ~isreal(seed) || ...
            ~isfinite(seed) || seed<0 || seed~=floor(seed)
        error("swsynth:InvalidV2SampleOptions", ...
            "seed must be a finite nonnegative integer.");
    end
end

geometry=canonical(result.geometry);
isVolume=geometry=="volumetric3d";
f=double(result.excitation.frequency_hz);
grid=result.domain;
material=result.medium;
observed=swsynth.observation.projectComponent(result.U_xyz,axisXYZ);
if isVolume
    fieldName="data_zyx";
    speedName="cs_map_zyx";
    materialName="material_id_zyx";
    expected=[numel(grid.z_m),numel(grid.y_m),numel(grid.x_m)];
    order="zyx";
else
    fieldName="data_zx";
    speedName="cs_map_zx";
    materialName="material_id_zx";
    expected=[numel(grid.z_m),numel(grid.x_m)];
    order="zx";
end
if ~isfield(material,speedName) || ...
        ~isfield(material,materialName) || ...
        ~isequal(size(material.(speedName)),expected) || ...
        ~isequal(size(observed),expected)
    error("swsynth:InvalidV2SampleResult", ...
        "Field and medium must share the declared z-x or z-y-x grid.");
end
csMap=material.(speedName);
if ~isnumeric(csMap) || ~isreal(csMap) || ...
        any(~isfinite(csMap(:))) || any(csMap(:)<=0) || ...
        any(~isfinite(observed(:)))
    error("swsynth:InvalidV2SampleResult", ...
        "Material speeds and observed phasor must be finite.");
end
kLocal=2*pi*f./double(csMap);
validMask=isfinite(observed) & isfinite(csMap) & (csMap>0);

sample=struct();
sample.schema_name="wavefield_sample";
sample.schema_version="1.0";
sample.spatial_dimension=2+double(isVolume);
sample.sample_id="";
sample.dataset_id="";
sample.generator=struct( ...
    "name","swsynth", ...
    "backend","fast_synthetic_v2", ...
    "repository","gsara798/shear-wave-simulation-framework", ...
    "commit",commit);
sample.scenario=scenarioName;
% Unknown seed must not be represented by an invented number.
sample.seed=seed;

sample.coordinates=struct();
sample.coordinates.x_m=grid.x_m;
sample.coordinates.z_m=grid.z_m;
sample.coordinates.dx_m=grid.dx_m;
sample.coordinates.dz_m=grid.dz_m;
sample.coordinates.array_order=order;
if isVolume
    sample.coordinates.y_m=grid.y_m;
    sample.coordinates.dy_m=grid.dy_m;
else
    sample.coordinates.observation_plane="x_z";
    sample.coordinates.observation_y_m=grid.observation_y_m;
end

component="projected";
if isequal(axisXYZ,[0 0 1])
    component="z";
end
quantity=string(result.quantity);
switch quantity
    case "relative_motion"
        units="arbitrary_relative_motion";
    case "displacement"
        units="arbitrary_displacement";
    case "velocity"
        units="arbitrary_velocity";
    otherwise
        error("swsynth:InvalidV2SampleQuantity", ...
            "Unsupported V2 measurement quantity.");
end
sample.wavefield=struct();
sample.wavefield.(fieldName)=observed;
sample.wavefield.component=component;
sample.wavefield.quantity=quantity;
sample.wavefield.frequency_hz=f;
sample.wavefield.angular_frequency_rad_s=2*pi*f;
sample.wavefield.is_complex=~isreal(observed);
sample.wavefield.units=units;
sample.wavefield.phasor_convention=string(result.excitation.phasor_convention);
sample.wavefield.output_convention="data_"+order+"("+ ...
    join(string(cellstr(order.')),"")+")";
% Override generic string with the tested data-index ordering.
if isVolume
    sample.wavefield.output_convention="data_zyx(z,y,x)";
else
    sample.wavefield.output_convention="data_zx(z,x)";
end

sample.measurement=struct("quantity",quantity, ...
    "component",component,"axis_xyz",axisXYZ, ...
    "model","signed_vector_projection", ...
    "calibrated",false);

sample.truth=struct();
sample.truth.(speedName)=csMap;
sample.truth.("k_map_"+order)=kLocal;
sample.truth.(materialName)=material.(materialName);
sample.truth.("valid_mask_"+order)=logical(validMask);

sample.medium=struct();
sample.medium.background_cs_m_s=material.background_cs_m_s;
sample.medium.model=material.medium_model;
sample.medium.objects={};
sample.medium.combine_mode="overlay";
if isfield(scenario,"medium")
    if isfield(scenario.medium,"objects")
        objects=scenario.medium.objects;
        if ~isempty(objects)
            sample.medium.objects=objects;
        end
    end
    if isfield(scenario.medium,"combine_mode")
        sample.medium.combine_mode=string(scenario.medium.combine_mode);
    end
end

sample.propagation=struct();
sample.propagation.model=string(result.model);
sample.propagation.geometry=geometry;
sample.propagation.phase_model=string(result.propagation.phase_method);
sample.propagation.normalization=string(result.propagation.normalization);
sample.propagation.reference_cs_m_s=result.propagation.reference_cs_m_s;
sample.propagation.component_count=result.component_count;
sample.propagation.k_map_definition="local_material_2pi_f_over_cs";
sample.propagation.k_map_is_eikonal_phase_gradient=false;
sample.propagation.spatial_phase_sign=result.excitation.spatial_phase_sign;
if isfield(result.propagation,"geometric_decay_exponent")
    sample.propagation.geometric_decay_exponent= ...
        result.propagation.geometric_decay_exponent;
end
if isfield(result.propagation,"solver_options")
    sample.propagation.solver_options=result.propagation.solver_options;
end

sample.directions=struct();
sample.sources=[];
sample.excitation=struct("frequency_hz",f, ...
    "angular_frequency_rad_s",2*pi*f);
if result.model=="plane_wave"
    d=result.incidence.direction_xyz;
    sample.directions.xyz=d;
    sample.directions.ux=d(:,1);
    sample.directions.uy=d(:,2);
    sample.directions.uz=d(:,3);
    sample.directions.retained_count=size(d,1);
    sample.directions.interpretation="incident_plane_wave_direction";
    sample.excitation.relative_amplitude= ...
        result.incidence.relative_amplitude;
    sample.excitation.phase_rad=result.incidence.phase_rad;
    sample.excitation.polarization=result.incidence.polarization;
else
    % Point-source radiation direction varies over space; do not encode
    % a fictitious single direction per source.
    sample.directions.xyz=zeros(0,3);
    sample.directions.ux=zeros(0,1);
    sample.directions.uy=zeros(0,1);
    sample.directions.uz=zeros(0,1);
    sample.directions.retained_count=0;
    sample.directions.interpretation="not_applicable_to_point_sources";
    sample.sources=result.sources;
    sample.excitation.relative_amplitude= ...
        result.sources.sources.relative_amplitude;
    sample.excitation.phase_rad=result.sources.sources.phase_rad;
    sample.excitation.force_direction_xyz= ...
        result.sources.sources.force_direction_xyz;
end

sample.validation=struct();
sample.validation.valid=all(validMask(:));
sample.validation.analysis_ready= ...
    sample.validation.valid && any(abs(observed(:))>0);
sample.validation.output_convention=sample.wavefield.output_convention;
sample.validation.scope="schema_and_finite_phasor_only";
sample.validation.physics_validated=false;

sample.provenance=struct();
sample.provenance.resolved_config=scenario;
sample.provenance.source_bundle=result.sources;
sample.provenance.incident_plane_waves=result.incidence;
sample.provenance.run_id="";
sample.provenance.campaign_id="";
sample.provenance.source_path="";
sample.provenance.created_utc="";

wavefield.validateSample(sample);
end

function geometry=canonical(value)
geometry=string(value);
if ~isscalar(geometry)
    error("swsynth:InvalidV2SampleGeometry", ...
        "Geometry must be a scalar string.");
end
if geometry=="planar2d";geometry="2d";end
if ~ismember(geometry,["2d","projected3d","volumetric3d"])
    error("swsynth:InvalidV2SampleGeometry","Unsupported geometry.");
end
end
