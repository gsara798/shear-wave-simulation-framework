function maps=buildMaps(medium,materialMaps,frequency)
%BUILDMAPS Local phase speed and intrinsic loss per material label.
% Homogeneous constituents and sharp overlay boundaries only.
arguments
    medium (1,1) struct
    materialMaps (1,1) struct
    frequency (1,1) double {mustBePositive}
end
if isfield(medium,"combine_mode") && string(medium.combine_mode)~="overlay"
    error("swsynth:UnsupportedViscoelasticMixing", ...
        "Spatial viscoelastic maps require overlay combine_mode.");
end
vol=string(materialMaps.geometry)=="volumetric3d";
if vol
    ids=materialMaps.material_id_zyx;
else
    ids=materialMaps.material_id_zx;
end
if ~isfield(medium,"viscoelastic")
    error("swsynth:InvalidViscoelasticMedium", ...
        "medium.viscoelastic is required for heterogeneous attenuation.");
end
background=swsynth.medium.viscoelastic.dispersion(medium.viscoelastic,frequency);
speed=background.phase_speed_m_s*ones(size(ids));
loss=background.attenuation_np_m*ones(size(ids));
for i=1:numel(medium.objects)
    obj=medium.objects{i};
    if isfield(obj,"edge_sigma_m") && obj.edge_sigma_m>0
        error("swsynth:UnsupportedViscoelasticMixing", ...
            "Smoothed interfaces need explicit constitutive mixing.");
    end
    if ~isfield(obj,"viscoelastic")
        error("swsynth:InvalidViscoelasticMedium", ...
            "Every inclusion requires its own viscoelastic specification.");
    end
    d=swsynth.medium.viscoelastic.dispersion(obj.viscoelastic,frequency);
    mask=ids==i;
    speed(mask)=d.phase_speed_m_s;
    loss(mask)=d.attenuation_np_m;
end
maps=struct("phase_speed",speed,"attenuation_np_m",loss, ...
    "reference_phase_speed_m_s",background.phase_speed_m_s, ...
    "background",background, ...
    "wavenumber_rad_m",2*pi*frequency./speed+1i*loss);
end
