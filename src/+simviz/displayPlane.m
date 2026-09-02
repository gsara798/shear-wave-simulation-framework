function [x_mm,z_mm,U_zx,cs_zx,description] = displayPlane(sample)
%DISPLAYPLANE Return the public x-z plane used by standard run figures.
arguments
    sample (1,1) struct
end
x_mm = 1e3*double(sample.coordinates.x_m(:));
z_mm = 1e3*double(sample.coordinates.z_m(:));
if double(sample.spatial_dimension) == 2
    U_zx = sample.wavefield.data_zx;
    cs_zx = sample.truth.cs_map_zx;
    description = "x-z observation plane";
elseif double(sample.spatial_dimension) == 3
    U = sample.wavefield.data_zyx;
    cs = sample.truth.cs_map_zyx;
    yIndex = round((size(U,2)+1)/2);
    U_zx = squeeze(U(:,yIndex,:));
    cs_zx = squeeze(cs(:,yIndex,:));
    description = sprintf("central x-z slice (y index %d)",yIndex);
else
    error("simviz:UnsupportedDimension","Only 2D and 3D samples are supported.");
end
U_zx = double(U_zx);
cs_zx = double(cs_zx);
end
