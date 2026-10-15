function aperture = build(parentXYZ, apertureConfig, geometry, observationY)
%BUILD Expand each physical source into coherent point-force aperture nodes.
% A scalar apertureConfig is shared; a 1-by-N struct array configures
% individual sources. Per-source node weights sum to one.
% Excitation belongs to the parent source; do not re-sample per element.
arguments
    parentXYZ (:,3) double {mustBeFinite}
    apertureConfig (1,:) struct
    geometry (1,1) string = "volumetric3d"
    observationY (1,1) double = 0
end
N=size(parentXYZ,1);
if N<1
    error("swsynth:InvalidSourceCount", ...
        "At least one physical source is required.");
end
if numel(apertureConfig)~=1 && numel(apertureConfig)~=N
    error("swsynth:ApertureCountMismatch", ...
        "apertureConfig must be a scalar struct or one struct per source.");
end
if geometry=="2d";geometry="planar2d";end
if ~isscalar(observationY) || ~isfinite(observationY)
    error("swsynth:InvalidObservationY","observationY must be finite.");
end

perSource=cell(N,1);
nodes=cell(N,1);
weights=cell(N,1);
owner=cell(N,1);
counts=zeros(N,1);
for i=1:N
    index=min(i,numel(apertureConfig));
    a=swsynth.sources.buildCoherentAperture( ...
        parentXYZ(i,:),apertureConfig(index));
    % In planar 2D, every emitting element must remain in the x-z plane.
    swsynth.sources.positions.validate( ...
        a.node_xyz_m,geometry,a.node_count,observationY);
    perSource{i}=a;
    nodes{i}=a.node_xyz_m;
    weights{i}=a.node_weights(:);
    owner{i}=repmat(i,a.node_count,1);
    counts(i)=a.node_count;
end
aperture=struct();
aperture.source_count=N;
aperture.per_source=[perSource{:}];
aperture.node_count_per_source=counts;
aperture.node_xyz_m=vertcat(nodes{:});
aperture.node_weight=vertcat(weights{:});
aperture.node_source_id=vertcat(owner{:});
aperture.node_count=numel(aperture.node_weight);
end
