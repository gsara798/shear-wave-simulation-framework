function bundle = validate(bundle,geometry)
%VALIDATE Validate physical sources and optional incident-component mapping.
% A physical point source does not need a global propagation direction.
arguments
    bundle (1,1) struct
    geometry (1,1) string
end
if geometry=="2d"
    geometry="planar2d";
end
if ~isfield(bundle,"sources") || ~isstruct(bundle.sources) || ...
        ~isscalar(bundle.sources)
    error("swsynth:InvalidSourceBundle","bundle.sources must be a struct.");
end
sourceCount=0;
if isfield(bundle.sources,"position_xyz_m") && ...
        ~isempty(bundle.sources.position_xyz_m)
    positions=double(bundle.sources.position_xyz_m);
    sourceCount=size(positions,1);
    observationY=0;
    if isfield(bundle.sources,"observation_y_m")
        observationY=double(bundle.sources.observation_y_m);
    end
    bundle.sources.position_xyz_m= ...
        swsynth.sources.positions.validate( ...
            positions,geometry,sourceCount,observationY);
end
if isfield(bundle,"count") && ...
        (~isscalar(bundle.count) || bundle.count~=sourceCount)
    error("swsynth:SourceBundleCountMismatch", ...
        "bundle.count must equal the number of physical sources.");
end
if isfield(bundle.sources,"source_id")
    sourceIds=double(bundle.sources.source_id(:));
    if ~isequal(sourceIds,(1:sourceCount)')
        error("swsynth:InvalidSourceIds", ...
            "source_id must enumerate physical sources from 1 to count.");
    end
end
excitationFields=["force_direction_xyz","relative_amplitude","phase_rad"];
hasExcitation=arrayfun(@(j) isfield(bundle.sources,excitationFields(j)), ...
    1:numel(excitationFields));
if any(hasExcitation)
    if ~all(hasExcitation) || sourceCount==0
        error("swsynth:InvalidSourceBundle", ...
            "A physical source bundle needs all excitation fields.");
    end
    normalized=swsynth.sources.excitation.validate( ...
        struct("geometry",geometry,"count",sourceCount, ...
        "force_direction_xyz",bundle.sources.force_direction_xyz, ...
        "relative_amplitude",bundle.sources.relative_amplitude, ...
        "phase_rad",bundle.sources.phase_rad));
    bundle.sources.force_direction_xyz=normalized.force_direction_xyz;
    bundle.sources.relative_amplitude=normalized.relative_amplitude;
    bundle.sources.phase_rad=normalized.phase_rad;
end
if isfield(bundle,"aperture") && ~isempty(bundle.aperture)
    if sourceCount==0
        error("swsynth:InvalidSourceBundle", ...
            "Aperture nodes require physical source positions.");
    end
    bundle.aperture=swsynth.sources.aperture.validate( ...
        bundle.aperture,bundle.sources.position_xyz_m, ...
        geometry,observationY);
end

if ~isfield(bundle,"components") || isempty(bundle.components)
    return;
end
if ~isstruct(bundle.components) || ~isscalar(bundle.components)
    error("swsynth:InvalidSourceComponents", ...
        "bundle.components must be a struct.");
end
components=bundle.components;
componentCount=[];
if isfield(components,"direction_xyz") && ...
        ~isempty(components.direction_xyz)
    d=double(components.direction_xyz);
    if size(d,2)~=3 || any(~isfinite(d(:))) || ...
            any(vecnorm(d,2,2)<=0)
        error("swsynth:InvalidSourceComponents", ...
            "Propagation directions must be finite nonzero N-by-3 vectors.");
    end
    if geometry=="planar2d" && any(abs(d(:,2))>1e-10)
        error("swsynth:InvalidSourceComponents", ...
            "Planar incident waves must propagate in the x-z plane.");
    end
    componentCount=size(d,1);
    components.direction_xyz=d./vecnorm(d,2,2);
end
if isfield(components,"source_id") && ~isempty(components.source_id)
    ids=double(components.source_id(:));
    if isempty(componentCount)
        componentCount=numel(ids);
    end
    if sourceCount==0 || numel(ids)~=componentCount || ...
            any(~isfinite(ids)) || any(ids~=floor(ids)) || ...
            any(ids<1) || any(ids>sourceCount)
        error("swsynth:InvalidSourceMapping", ...
            "components.source_id must reference valid physical sources.");
    end
    components.source_id=ids;
end
bundle.components=components;
end
