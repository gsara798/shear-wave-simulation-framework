function maps = buildMaps(grid, spec)
%BUILDMAPS Sample frequency-independent mechanical properties on a V2 grid.
% Material-map contract: cs_map_zx / cs_map_zyx, material IDs and masks.
% No frequency, k map, phase, density-based radiation or attenuation.
arguments
    grid (1,1) struct
    spec (1,1) struct
end
required=["geometry","x_m","z_m","spatial_size"];
for field=required
    if ~isfield(grid,field)
        error("swsynth:InvalidMediumGrid", ...
            "Grid missing %s; use swsynth.domain.buildGrid.",field);
    end
end
geometry=string(grid.geometry);
if geometry=="planar2d";geometry="2d";end
if ~ismember(geometry,["2d","projected3d","volumetric3d"])
    error("swsynth:InvalidMediumGrid","Unrecognized grid geometry.");
end
x=checkAxis(grid.x_m);
z=checkAxis(grid.z_m);
if geometry=="volumetric3d"
    if ~isfield(grid,"y_m")
        error("swsynth:InvalidMediumGrid","Volumetric grid needs y_m.");
    end
    y=checkAxis(grid.y_m);
    shape=[numel(z),numel(y),numel(x)];
else
    shape=[numel(z),numel(x)];
end
if ~isequal(double(grid.spatial_size),shape)
    error("swsynth:InvalidMediumGrid", ...
        "grid.spatial_size is inconsistent with coordinate vectors.");
end

medium=swsynth.medium.validate(spec,geometry);
if geometry=="volumetric3d"
    [cs,ids,alpha]=build3D(x,y,z,medium);
else
    [cs,ids,alpha]=build2D(x,z,medium);
end
maps=struct();
maps.geometry=geometry;
maps.x_m=x;
maps.z_m=z;
maps.dx_m=(x(end)-x(1))/(numel(x)-1);
maps.dz_m=(z(end)-z(1))/(numel(z)-1);
if geometry=="volumetric3d"
    maps.y_m=y;
    maps.dy_m=(y(end)-y(1))/(numel(y)-1);
    maps.cs_map_zyx=cs;
    maps.material_id_zyx=ids;
    maps.object_alpha_zyx=alpha;
    maps.output_convention="maps(z,y,x)";
else
    if isfield(grid,"observation_y_m")
        maps.observation_y_m=grid.observation_y_m;
    else
        maps.observation_y_m=0;
    end
    maps.cs_map_zx=cs;
    maps.material_id_zx=ids;
    maps.object_alpha_zx=alpha;
    maps.output_convention="maps(z,x)";
end
maps.medium_model="isotropic_elastic_shear_speed";
maps.background_cs_m_s=medium.background_cs_m_s;
if isfield(medium,"density_kg_m3")
    maps.density_kg_m3=medium.density_kg_m3;
end
end

function [csZX,idZX,alphaZX]=build2D(x,z,medium)
% Keep the legacy 2D ndgrid(x,z) evaluation order, then transpose to zx.
[X,Z]=ndgrid(x,z);
nx=numel(x);nz=numel(z);
n=numel(medium.objects);
csXZ=medium.background_cs_m_s*ones(nx,nz);
idXZ=zeros(nx,nz,"uint16");
alphaXZ=cell(1,n);
for i=1:n
    alphaXZ{i}=alpha2D(X,Z,medium.objects{i});
end
switch medium.combine_mode
    case "overlay"
        for i=1:n
            a=alphaXZ{i};
            csXZ=(1-a).*csXZ+a.*medium.objects{i}.cs_m_s;
            idXZ(a>=.5)=uint16(i);
        end
    case "blend"
        numerator=zeros(nx,nz);
        denominator=zeros(nx,nz);
        for i=1:n
            numerator=numerator+alphaXZ{i}.*medium.objects{i}.cs_m_s;
            denominator=denominator+alphaXZ{i};
        end
        total=min(denominator,1);
        blended=numerator./max(denominator,eps);
        csXZ=(1-total).*medium.background_cs_m_s+total.*blended;
        for i=1:n
            idXZ(alphaXZ{i}>=.5)=uint16(i);
        end
    case {"min","max"}
        for i=1:n
            a=alphaXZ{i};
            local=(1-a).*medium.background_cs_m_s+a.*medium.objects{i}.cs_m_s;
            if medium.combine_mode=="max"
                mask=local>csXZ;
                csXZ=max(csXZ,local);
            else
                mask=local<csXZ;
                csXZ=min(csXZ,local);
            end
            idXZ(mask)=uint16(i);
        end
end
csZX=csXZ.';
idZX=idXZ.';
alphaZX=cell(1,n);
for i=1:n
    alphaZX{i}=alphaXZ{i}.';
end
end

function alpha=alpha2D(X,Z,obj)
switch obj.type
    case "circle"
        c=obj.center_xz_m;
        % Compare squared distances, avoiding sqrt rounding at the boundary.
        distanceSquared=(X-c(1)).^2+(Z-c(2)).^2;
        mask=distanceSquared<=obj.radius_m^2;
    case "bilayer"
        normal=[cos(obj.normal_angle_rad);sin(obj.normal_angle_rad)];
        signed=X*normal(1)+Z*normal(2)-obj.offset_m;
        mask=signed>0;
    case "s_curve"
        c=obj.center_xz_m;
        localX=X-c(1);
        localZ=Z-c(2);
        curveZ=obj.amplitude_m.*sin(2*pi*localX/obj.wavelength_m);
        mask=abs(localZ-curveZ)<=obj.thickness_m/2;
    case "custom"
        expectedSize=fliplr(size(X));
        if ~isequal(size(obj.mask_zx),expectedSize)
            error("swsynth:CustomMaskSizeMismatch", ...
                "custom mask_zx must be [Nz,Nx].");
        end
        mask=logical(obj.mask_zx.');
end
if obj.edge_sigma_m<=0
    alpha=double(mask);
    return;
end
if exist("imgaussfilt","file")~=2
    error("swsynth:MissingImageProcessingToolbox", ...
        "Nonzero edge_sigma_m requires imgaussfilt.");
end
dx=mean(diff(unique(X(:,1))));
dz=mean(diff(unique(Z(1,:))));
sigmaPixels=max(.5,obj.edge_sigma_m/max(dx,dz));
filterSize=2*ceil(3*sigmaPixels)+1;
alpha=imgaussfilt(double(mask),sigmaPixels, ...
    FilterSize=filterSize,Padding="replicate");
maximum=max(alpha(:));
if maximum>0
    alpha=alpha/maximum;
end
end

function [cs,id,alpha]=build3D(x,y,z,medium)
[Z,Y,X]=ndgrid(z,y,x);
shape=[numel(z),numel(y),numel(x)];
cs=medium.background_cs_m_s*ones(shape);
id=zeros(shape,"uint16");
alpha=cell(1,numel(medium.objects));
for i=1:numel(medium.objects)
    obj=medium.objects{i};
    switch obj.type
        case "sphere"
            c=obj.center_xyz_m;
            mask=(X-c(1)).^2+(Y-c(2)).^2+(Z-c(3)).^2 ...
                <=obj.radius_m^2;
        case "box"
            c=obj.center_xyz_m;
            h=obj.size_xyz_m/2;
            mask=abs(X-c(1))<=h(1) & ...
                abs(Y-c(2))<=h(2) & abs(Z-c(3))<=h(3);
        case "slab"
            n=obj.normal_xyz(:);
            signed=X*n(1)+Y*n(2)+Z*n(3);
            mask=signed>=obj.offset_m;
        case "custom"
            mask=logical(obj.mask_zyx);
            if ~isequal(size(mask),shape)
                error("swsynth:Custom3DMaskSizeMismatch", ...
                    "custom mask_zyx must be [Nz,Ny,Nx].");
            end
    end
    alpha{i}=double(mask);
    cs(mask)=obj.cs_m_s;
    id(mask)=uint16(i);
end
end

function axis=checkAxis(value)
if ~isnumeric(value) || ~isreal(value) || ~isvector(value) || ...
        numel(value)<2 || any(~isfinite(value(:)))
    error("swsynth:InvalidMediumGrid","Grid axes must be finite real vectors.");
end
axis=double(value(:).');
if any(diff(axis)<=0)
    error("swsynth:InvalidMediumGrid", ...
        "Grid axes must increase strictly.");
end
end
