function bundle = validate(bundle, geometry)
%VALIDATE Validate the physical source/component relationship.
% This V2 contract does not require one source per incident component.
arguments
    bundle (1,1) struct
    geometry (1,1) string
end
if ~isfield(bundle,"components") || ~isstruct(bundle.components) || ...
        ~isfield(bundle.components,"direction_xyz")
    error("swsynth:InvalidSourceComponents", ...
        "bundle.components.direction_xyz is required.");
end
d=double(bundle.components.direction_xyz);
if size(d,2)~=3 || any(~isfinite(d(:))) || ...
        any(vecnorm(d,2,2)<=0)
    error("swsynth:InvalidSourceComponents", ...
        "Component directions must be N-by-3 finite nonzero vectors.");
end
if geometry=="planar2d" && any(abs(d(:,2))>1e-10)
    error("swsynth:InvalidSourceComponents", ...
        "Planar2d component directions must have zero y component.");
end
bundle.components.direction_xyz=d./vecnorm(d,2,2);
if ~isfield(bundle,"sources") || ~isstruct(bundle.sources)
    error("swsynth:InvalidSourceBundle","bundle.sources struct is required.");
end
if isfield(bundle.sources,"position_xyz_m") && ...
        ~isempty(bundle.sources.position_xyz_m)
    positions=double(bundle.sources.position_xyz_m);
    S=size(positions,1);
    y=0;
    if isfield(bundle.sources,"observation_y_m")
        y=double(bundle.sources.observation_y_m);
    end
    bundle.sources.position_xyz_m= ...
        swsynth.sources.positions.validate(positions,geometry,S,y);
    if isfield(bundle.components,"source_id") && ...
            ~isempty(bundle.components.source_id)
        ids=double(bundle.components.source_id(:));
        if numel(ids)~=size(d,1) || any(~isfinite(ids)) || ...
                any(ids~=floor(ids)) || any(ids<1) || any(ids>S)
            error("swsynth:InvalidSourceMapping", ...
                "components.source_id must reference a valid physical source.");
        end
    end
elseif isfield(bundle.components,"source_id") && ...
        ~isempty(bundle.components.source_id)
    error("swsynth:InvalidSourceMapping", ...
        "Source IDs require actual physical sources.");
end
end
