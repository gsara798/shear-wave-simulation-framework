function cfg = configureFiniteContact(cfg, options)
%CONFIGUREFINITECONTACT Represent each vibrator by a tapered finite segment.
%
% The defaults reproduce the validated reference contact on the current
% 0.5 mm grid: a 4 mm span sampled at three non-adjacent nodes.

arguments
    cfg struct

    options.ContactRadiusM (1,1) double ...
        {mustBePositive} = 2e-3

    options.NodeSpacingPoints (1,1) double ...
        {mustBeInteger, mustBePositive} = 4

    options.Profile (1,1) string {mustBeMember(options.Profile, ...
        ["raised_cosine", "gaussian", "uniform"])} = ...
        "raised_cosine"
end

cfg.source.contact_model = "finite_segment";
cfg.source.contact_sampling = "sparse_patch";
cfg.source.contact_profile = options.Profile;
cfg.source.contact_node_spacing_points = ...
    options.NodeSpacingPoints;
cfg.source.contact_radius_m = options.ContactRadiusM;

end
