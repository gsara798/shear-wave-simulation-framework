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
