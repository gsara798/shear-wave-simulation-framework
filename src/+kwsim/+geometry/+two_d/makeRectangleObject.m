function object = makeRectangleObject(bounds_m_xz, material_id, cs_m_s, rho_kg_m3, name)
%MAKERECTANGLEOBJECT Define one axis-aligned 2D rectangle in SI units.
%
% bounds_m_xz is [x_min, x_max, z_min, z_max] in metres. Bounds are
% inclusive when rasterized on the solver grid. Objects retain the existing
% ordered overwrite semantics.

arguments
    bounds_m_xz (1,4) double {mustBeFinite, mustBeNonnegative}
    material_id (1,1) {mustBeInteger, mustBePositive}
    cs_m_s (1,1) double {mustBeFinite, mustBePositive}
    rho_kg_m3 (1,1) double {mustBeFinite, mustBePositive}
    name {mustBeTextScalar} = "rectangle"
end

if bounds_m_xz(2) <= bounds_m_xz(1) || ...
        bounds_m_xz(4) <= bounds_m_xz(3)
    error('kwsim:InvalidRectangleBounds', ...
        'Rectangle bounds must satisfy x_max>x_min and z_max>z_min.');
end
if material_id == 1
    error('kwsim:ReservedMaterialId', ...
        'material_id=1 is reserved for the homogeneous background.');
end

object = struct();
object.type = "rectangle";
object.name = string(name);
object.center_m_xz = [NaN, NaN];
object.radius_m = NaN;
object.bounds_m_xz = bounds_m_xz;
object.material_id = uint16(material_id);
object.cs_m_s = cs_m_s;
object.rho_kg_m3 = rho_kg_m3;
end
