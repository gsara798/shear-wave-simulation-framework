function wavefield = accumulate(contributions, options)
%ACCUMULATE Coherently superpose harmonic vector wave contributions.
%
% contributions: nonempty struct array or cell array of scalar structs
%   from plane_wave.computeContribution or spherical.point_source.computeContribution.
% options.normalization: "none" (default), "sqrt_count" (divide by sqrt(N)).
%
% The complex fields are added before any optional normalization. This
% preserves relative phases and signs; no projection, noise or new physics.
% Matching geometry, frequency, phase sign AND coordinate axes are required.
% The output vector convention is [z,x,xyz] or [z,y,x,xyz].
arguments
    contributions
    options (1,1) struct = struct()
end

if isstruct(contributions)
    if isempty(contributions)
        error("swsynth:EmptyWaveContributions", ...
            "Provide at least one wave contribution.");
    end
    components=num2cell(contributions(:));
elseif iscell(contributions)
    if isempty(contributions)
        error("swsynth:EmptyWaveContributions", ...
            "Provide at least one wave contribution.");
    end
    components=contributions(:);
else
    error("swsynth:InvalidWaveContributions", ...
        "contributions must be a struct array or cell array of structs.");
end

normalization="none";
if isfield(options,"normalization")
    normalization=string(options.normalization);
end
if ~isscalar(normalization) || ...
        ~ismember(normalization,["none","sqrt_count"])
    error("swsynth:InvalidWaveNormalization", ...
        "normalization must be none or sqrt_count.");
end
n=numel(components);
first=validateComponent(components{1});
referenceGeometry=first.geometry;
referenceFrequency=first.frequency_hz;
referencePhaseSign=first.phase_sign;
referenceSize=first.field_size;
referenceAxes=first.axes;

% Accumulate in double precision without stacking every wave into an
% extra dimension. The inputs already carry each component's amplitude
% and initial phase, so they must not be applied a second time.
summed=complex(zeros(referenceSize));
for index=1:n
    component=validateComponent(components{index});
    if component.geometry~=referenceGeometry
        error("swsynth:WaveContributionGeometryMismatch", ...
            "Contribution %d has incompatible geometry.",index);
    end
    if component.frequency_hz~=referenceFrequency
        error("swsynth:WaveContributionFrequencyMismatch", ...
            "Contribution %d has incompatible frequency_hz.",index);
    end
    if component.phase_sign~=referencePhaseSign
        error("swsynth:WaveContributionPhaseConventionMismatch", ...
            "Contribution %d uses a different spatial phase sign.",index);
    end
    if ~isequal(component.field_size,referenceSize)
        error("swsynth:WaveContributionSizeMismatch", ...
            "Contribution %d has incompatible spatial dimensions.",index);
    end
    if ~isequal(component.axes.x,referenceAxes.x) || ...
            ~isequal(component.axes.z,referenceAxes.z) || ...
            (referenceGeometry=="volumetric3d" && ...
             ~isequal(component.axes.y,referenceAxes.y)) || ...
            (referenceGeometry~="volumetric3d" && ...
             component.axes.observation_y_m~=referenceAxes.observation_y_m)
        error("swsynth:WaveContributionGridMismatch", ...
            "Contribution %d uses different physical spatial coordinates.",index);
    end
    summed=summed+double(component.U_xyz);
end

switch normalization
    case "none"
        factor=1;
    case "sqrt_count"
        factor=1/sqrt(n);
end
summed=summed*factor;
% In all-zero or purely real special cases, MATLAB may drop the complex
% storage flag. Preserve the documented harmonic phasor representation.
summed=complex(real(summed),imag(summed));

wavefield=struct();
wavefield.model="coherent_superposition";
wavefield.geometry=referenceGeometry;
wavefield.frequency_hz=referenceFrequency;
wavefield.phase_sign=referencePhaseSign;
wavefield.component_count=n;
wavefield.normalization=normalization;
wavefield.normalization_factor=factor;
wavefield.x_m=referenceAxes.x;
wavefield.z_m=referenceAxes.z;
if referenceGeometry=="volumetric3d"
    wavefield.y_m=referenceAxes.y;
    wavefield.output_convention="U(z,y,x,component_xyz)";
else
    wavefield.observation_y_m=referenceAxes.observation_y_m;
    wavefield.output_convention="U(z,x,component_xyz)";
end
wavefield.U_xyz=summed;
end

function component = validateComponent(value)
if ~isstruct(value) || ~isscalar(value)
    error("swsynth:InvalidWaveContribution", ...
        "Each contribution must be a scalar struct.");
end
required=["model","geometry","frequency_hz","phase_sign", ...
    "x_m","z_m","U_xyz"];
for field=required
    if ~isfield(value,field)
        error("swsynth:WaveContributionMissingField", ...
            "Missing contribution field %s.",field);
    end
end
model=string(value.model);
if ~isscalar(model) || ...
        ~ismember(model,["plane_wave","spherical_wave"])
    error("swsynth:InvalidWaveContributionModel", ...
        "Accumulator accepts plane_wave and spherical_wave contributions.");
end
geometry=string(value.geometry);
if ~isscalar(geometry)
    error("swsynth:InvalidWaveContributionGeometry", ...
        "geometry must be a scalar string.");
end
if geometry=="planar2d"; geometry="2d"; end
if ~ismember(geometry,["2d","projected3d","volumetric3d"])
    error("swsynth:InvalidWaveContributionGeometry", ...
        "Unsupported contribution geometry %s.",geometry);
end
frequency=double(value.frequency_hz);
if ~isscalar(frequency) || ~isreal(frequency) || ...
        ~isfinite(frequency) || frequency<=0
    error("swsynth:InvalidWaveContributionFrequency", ...
        "frequency_hz must be a positive real scalar.");
end
phaseSign=double(value.phase_sign);
if ~isscalar(phaseSign) || ~isreal(phaseSign) || ...
        ~isfinite(phaseSign) || ~ismember(phaseSign,[-1,1])
    error("swsynth:InvalidWavePhaseConvention", ...
        "phase_sign must be +1 or -1.");
end

axes=struct();
axes.x=checkAxis(value.x_m,"x_m");
axes.z=checkAxis(value.z_m,"z_m");
if geometry=="volumetric3d"
    if ~isfield(value,"y_m")
        error("swsynth:WaveContributionMissingField", ...
            "Volumetric contributions require y_m.");
    end
    axes.y=checkAxis(value.y_m,"y_m");
    expectedSize=[numel(axes.z),numel(axes.y),numel(axes.x),3];
else
    axes.observation_y_m=0;
    if isfield(value,"observation_y_m")
        axes.observation_y_m=double(value.observation_y_m);
    end
    if ~isscalar(axes.observation_y_m) || ...
            ~isreal(axes.observation_y_m) || ...
            ~isfinite(axes.observation_y_m)
        error("swsynth:InvalidWaveContributionGrid", ...
            "observation_y_m must be finite.");
    end
    expectedSize=[numel(axes.z),numel(axes.x),3];
end
field=value.U_xyz;
if ~isnumeric(field) || isempty(field) || ...
        ~isequal(size(field),expectedSize) || any(~isfinite(field(:)))
    error("swsynth:InvalidWaveContributionField", ...
        "U_xyz must be finite with the expected spatial and XYZ-component dimensions.");
end
component=struct();
component.model=model;
component.geometry=geometry;
component.frequency_hz=frequency;
component.phase_sign=phaseSign;
component.axes=axes;
component.field_size=expectedSize;
component.U_xyz=field;
end

function values=checkAxis(axis,name)
if ~isnumeric(axis) || ~isreal(axis) || ~isvector(axis) || ...
        isempty(axis) || any(~isfinite(axis(:)))
    error("swsynth:InvalidWaveContributionGrid", ...
        "%s must be a finite real coordinate vector.",name);
end
values=double(axis(:).');
if any(diff(values)<=0)
    error("swsynth:InvalidWaveContributionGrid", ...
        "%s must be strictly increasing.",name);
end
end
