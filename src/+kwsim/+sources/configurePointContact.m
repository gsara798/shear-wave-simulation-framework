function cfg = configurePointContact(cfg, options)
%CONFIGUREPOINTCONTACT Represent each physical vibrator by one solver node.
%
% ContactRadiusM remains relevant as placement clearance for vibrator banks.

arguments
    cfg struct

    options.ContactRadiusM (1,1) double ...
        {mustBePositive} = 1e-3
end

cfg.source.contact_model = "point";
cfg.source.contact_sampling = "point";
cfg.source.contact_profile = "uniform";
cfg.source.contact_node_spacing_points = 1;
cfg.source.contact_radius_m = options.ContactRadiusM;

end
