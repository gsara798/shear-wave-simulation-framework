function bundle = prepare(request, directions)
%PREPARE Assemble physical source positions, excitation and coherent apertures.
%
% New API: bundle = swsynth.sources.prepare(request)
% request.geometry: 2d/planar2d, projected3d, volumetric3d
% request.count: number of PHYSICAL sources
% request.positions: request for swsynth.sources.positions.generate
% request.excitation: request for swsynth.sources.excitation.generate
% request.aperture: scalar or per-source aperture definition (optional)
% request.streams.positions/excitation: optional independent RandStreams.
%
% Legacy API: swsynth.sources.prepare(cfg, directions)
% Preserves historic draws/outputs until synthesizers are migrated.
arguments
    request (1,1) struct
    directions = []
end
if nargin==2
    if ~isstruct(directions) || ~isscalar(directions)
        error("swsynth:InvalidLegacyDirections", ...
            "Legacy sources.prepare requires a direction struct.");
    end
    bundle=swsynth.sources.compat.prepareLegacy(request,directions);
    return;
end
if ~isfield(request,"geometry") || ~isfield(request,"count")
    error("swsynth:SourceBundleMissingField", ...
        "The modular source request needs geometry and count.");
end
geometry=normalizeGeometry(request.geometry);
n=double(request.count);
if ~isscalar(n) || ~isfinite(n) || n<1 || n~=floor(n)
    error("swsynth:InvalidSourceCount", ...
        "count must be a positive integer.");
end
if ~isfield(request,"positions") || ~isstruct(request.positions) || ...
        ~isscalar(request.positions)
    error("swsynth:SourceBundleMissingField", ...
        "request.positions must contain a position-generation request.");
end
if ~isfield(request,"excitation") || ~isstruct(request.excitation) || ...
        ~isscalar(request.excitation)
    error("swsynth:SourceBundleMissingField", ...
        "request.excitation must contain an excitation-generation request.");
end
posReq=request.positions;
excReq=request.excitation;
if isfield(posReq,"geometry") && normalizeGeometry(posReq.geometry)~=geometry
    error("swsynth:SourceBundleGeometryMismatch", ...
        "Position geometry differs from source bundle geometry.");
end
if isfield(excReq,"geometry") && normalizeGeometry(excReq.geometry)~=geometry
    error("swsynth:SourceBundleGeometryMismatch", ...
        "Excitation geometry differs from source bundle geometry.");
end
if (isfield(posReq,"count") && ~isequal(double(posReq.count),n)) || ...
        (isfield(excReq,"count") && ~isequal(double(excReq.count),n))
    error("swsynth:SourceBundleCountMismatch", ...
        "Position and excitation counts must match physical sources.");
end
posReq.count=n;
excReq.count=n;
posReq.geometry=geometry;
excReq.geometry=geometry;

observationY=0;
if isfield(request,"observation_y_m")
    observationY=double(request.observation_y_m);
elseif isfield(posReq,"observation_y_m")
    observationY=double(posReq.observation_y_m);
end
if ~isscalar(observationY) || ~isfinite(observationY)
    error("swsynth:InvalidObservationY", ...
        "observation_y_m must be a finite scalar.");
end
if isfield(posReq,"observation_y_m") && ...
        ~isequal(double(posReq.observation_y_m),observationY)
    error("swsynth:SourceBundleGeometryMismatch", ...
        "Conflicting observation_y_m in bundle and positions.");
end
posReq.observation_y_m=observationY;

if isfield(request,"streams")
    streams=request.streams;
    if ~isstruct(streams) || ~isscalar(streams)
        error("swsynth:InvalidSourceStreams", ...
            "streams must be a struct containing optional RandStreams.");
    end
    if isfield(streams,"positions")
        if isfield(posReq,"stream")
            error("swsynth:AmbiguousSourceStream", ...
                "Set positions stream in only one place.");
        end
        posReq.stream=streams.positions;
    end
    if isfield(streams,"excitation")
        if isfield(excReq,"stream")
            error("swsynth:AmbiguousSourceStream", ...
                "Set excitation stream in only one place.");
        end
        excReq.stream=streams.excitation;
    end
end

xyz=swsynth.sources.positions.generate(posReq);
exc=swsynth.sources.excitation.generate(excReq);
if ~isfield(request,"aperture") || isempty(request.aperture)
    apertureConfig=struct("model","point","span_m",0, ...
        "axis_xyz",[0 0 1],"node_spacing_m",5e-4);
else
    apertureConfig=request.aperture;
    if ~isstruct(apertureConfig) || isempty(apertureConfig)
        error("swsynth:InvalidApertureConfig", ...
            "aperture must be a scalar or per-source struct array.");
    end
end
aperture=swsynth.sources.aperture.build( ...
    xyz,apertureConfig,geometry,observationY);
aperture=swsynth.sources.aperture.validate( ...
    aperture,xyz,geometry,observationY);

sources=struct();
sources.source_id=(1:n)';
sources.position_xyz_m=xyz;
sources.force_direction_xyz=exc.force_direction_xyz;
sources.relative_amplitude=exc.relative_amplitude;
sources.phase_rad=exc.phase_rad;
sources.observation_y_m=observationY;
sources.aperture=aperture.per_source;

bundle=struct();
bundle.geometry=geometry;
bundle.count=n;
bundle.sources=sources;
bundle.excitation=exc;
bundle.aperture=aperture;
bundle=swsynth.sources.validate(bundle,geometry);
end

function geometry = normalizeGeometry(value)
geometry=string(value);
if ~isscalar(geometry)
    error("swsynth:InvalidSourceGeometry", ...
        "Source geometry must be a scalar string.");
end
if geometry=="2d"; geometry="planar2d";end
if ~ismember(geometry,["planar2d","projected3d","volumetric3d"])
    error("swsynth:InvalidSourceGeometry", ...
        "Unsupported physical source geometry %s.",geometry);
end
end
