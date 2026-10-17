function medium = validate(spec, geometry)
%VALIDATE Validate isotropic elastic shear-speed material specifications.
% Density is optional metadata and has NO effect on V2 wave synthesis.
% The medium is independent of excitation frequency.
arguments
    spec (1,1) struct
    geometry (1,1) string
end
if isfield(spec,"frequency_hz") || isfield(spec,"k_map_zx") || ...
        isfield(spec,"k_map_zyx")
    error("swsynth:MediumCannotOwnFrequency", ...
        "Frequency and wavenumber are not intrinsic medium-map inputs.");
end
if isfield(spec,"model")
    model=string(spec.model);
    if ~isscalar(model) || ~ismember(model, ...
            ["isotropic_elastic_shear_speed","homogeneous_elastic"])
        error("swsynth:UnsupportedMediumModel", ...
            "Only isotropic elastic speed-prescribed materials are implemented.");
    end
end
allowed=["model","cs_m_s","background_cs_m_s", ...
    "combine_mode","objects","density_kg_m3","viscoelastic"];
unknown=setdiff(string(fieldnames(spec)),allowed);
if ~isempty(unknown)
    error("swsynth:UnsupportedMediumProperty", ...
        "Unsupported medium property %s; do not silently ignore physics.", ...
        unknown(1));
end
if geometry=="planar2d";geometry="2d";end
if ~ismember(geometry,["2d","projected3d","volumetric3d"])
    error("swsynth:InvalidMediumGeometry","Unsupported medium geometry.");
end
hasCs=isfield(spec,"cs_m_s");
hasBackground=isfield(spec,"background_cs_m_s");
if hasCs==hasBackground
    error("swsynth:InvalidMediumSpeed", ...
        "Specify exactly one of cs_m_s or background_cs_m_s.");
end
if hasCs;cs=spec.cs_m_s;else;cs=spec.background_cs_m_s;end
if ~isValidPositive(cs)
    error("swsynth:InvalidMediumSpeed", ...
        "Background shear speed must be a positive finite real scalar.");
end
mode="overlay";
if isfield(spec,"combine_mode")
    mode=string(spec.combine_mode);
end
if ~isscalar(mode) || ~ismember(mode,["overlay","blend","max","min"]) || ...
        (geometry=="volumetric3d" && mode~="overlay")
    error("swsynth:InvalidMediumCombineMode", ...
        "3D supports overlay; 2D supports overlay/blend/max/min.");
end
objects={};
if isfield(spec,"objects")
    objects=spec.objects;
end
if isempty(objects);objects={};end
if ~iscell(objects)
    error("swsynth:InvalidMediumObjects", ...
        "objects must be a cell array of scalar structs.");
end
for i=1:numel(objects)
    obj=objects{i};
    if ~isstruct(obj) || ~isscalar(obj) || ...
            ~isfield(obj,"type") || ~isfield(obj,"cs_m_s")
        error("swsynth:InvalidMediumObject", ...
            "Each object must specify type and cs_m_s.");
    end
    obj.type=string(obj.type);
    sourceCs=obj.cs_m_s;
    if ~isValidPositive(sourceCs)
        error("swsynth:InvalidMediumObject", ...
            "Inclusion cs_m_s must be a positive real scalar.");
    end
    obj.cs_m_s=double(sourceCs);
    if ~isscalar(obj.type) || ~isValidPositive(obj.cs_m_s)
        error("swsynth:InvalidMediumObject", ...
            "Invalid inclusion type or shear speed.");
    end
    if geometry=="volumetric3d"
        allowed=["sphere","box","slab","custom"];
    else
        allowed=["circle","bilayer","s_curve","custom"];
    end
    if ~ismember(obj.type,allowed)
        error("swsynth:InvalidMediumObjectType", ...
            "Unsupported inclusion %s for %s.",obj.type,geometry);
    end
    if geometry~="volumetric3d"
        if ~isfield(obj,"edge_sigma_m")
            obj.edge_sigma_m=0;
        end
        sigma=obj.edge_sigma_m;
        if ~isnumeric(sigma) || ~isscalar(sigma) || ...
                ~isreal(sigma) || ~isfinite(sigma) || sigma<0
            error("swsynth:InvalidMediumObject", ...
                "edge_sigma_m must be nonnegative.");
        end
        obj.edge_sigma_m=sigma;
    end
    switch obj.type
        case {"circle","sphere"}
            if obj.type=="circle"
                obj.center_xz_m=vectorField(obj,"center_xz_m",2);
            else
                obj.center_xyz_m=vectorField(obj,"center_xyz_m",3);
            end
            requirePositive(obj,"radius_m");
        case "bilayer"
            requireFinite(obj,"normal_angle_rad");
            requireFinite(obj,"offset_m");
        case "s_curve"
            obj.center_xz_m=vectorField(obj,"center_xz_m",2);
            requireFinite(obj,"amplitude_m");
            requirePositive(obj,"wavelength_m");
            requirePositive(obj,"thickness_m");
        case "box"
            obj.center_xyz_m=vectorField(obj,"center_xyz_m",3);
            obj.size_xyz_m=vectorField(obj,"size_xyz_m",3);
            if any(obj.size_xyz_m<=0)
                error("swsynth:InvalidMediumObject","Box size must be positive.");
            end
        case "slab"
            obj.normal_xyz=vectorField(obj,"normal_xyz",3);
            if norm(obj.normal_xyz)<=eps
                error("swsynth:InvalidMediumObject","Slab normal must be nonzero.");
            end
            obj.normal_xyz=obj.normal_xyz/norm(obj.normal_xyz);
            requireFinite(obj,"offset_m");
        case "custom"
            field="mask_zx";
            if geometry=="volumetric3d";field="mask_zyx";end
            if ~isfield(obj,field)
                error("swsynth:InvalidMediumObject", ...
                    "Custom mask field %s is required.",field);
            end
            mask=obj.(field);
            if ~(isnumeric(mask) || islogical(mask)) || ...
                    isempty(mask) || ~isreal(mask) || ...
                    any(~isfinite(double(mask(:))))
                error("swsynth:InvalidMediumObject", ...
                    "Custom mask must be finite numeric/logical.");
            end
            obj.(field)=logical(mask);
    end
    objects{i}=obj;
end
medium=struct("background_cs_m_s",cs,"combine_mode",mode, ...
    "objects",{objects},"geometry",geometry);
if isfield(spec,"viscoelastic")
    medium.viscoelastic=spec.viscoelastic;
end
if isfield(spec,"density_kg_m3")
    rho=spec.density_kg_m3;
    if ~isValidPositive(rho)
        error("swsynth:InvalidMediumDensity", ...
            "density_kg_m3 must be positive and finite.");
    end
    medium.density_kg_m3=double(rho);
end
end

function good=isValidPositive(value)
good=isnumeric(value) && isscalar(value) && isreal(value) && ...
    isfinite(value) && value>0;
end

function requireFinite(obj,name)
if ~isfield(obj,name)
    error("swsynth:InvalidMediumObject","Missing inclusion field %s.",name);
end
v=obj.(name);
if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~isfinite(v)
    error("swsynth:InvalidMediumObject","%s must be finite.",name);
end
end

function requirePositive(obj,name)
requireFinite(obj,name);
if double(obj.(name))<=0
    error("swsynth:InvalidMediumObject","%s must be positive.",name);
end
end

function value=vectorField(obj,name,count)
if ~isfield(obj,name)
    error("swsynth:InvalidMediumObject","Missing inclusion field %s.",name);
end
value=double(obj.(name));
if ~isnumeric(obj.(name)) || ~isreal(value) || ...
        numel(value)~=count || any(~isfinite(value(:)))
    error("swsynth:InvalidMediumObject", ...
        "%s must have %d finite real values.",name,count);
end
value=reshape(value,1,[]);
end
