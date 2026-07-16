function object = makeCircleObject(center_m_xz, radius_m, material_id, cs_m_s, rho_kg_m3, name)
%MAKECIRCLEOBJECT Define one circular 2D material object in SI units.
%
% object = kwsim.geometry.two_d.makeCircleObject(center_m_xz, radius_m, ...
%     material_id, cs_m_s, rho_kg_m3, name)
%
% center_m_xz is [x,z] in metres. The returned definition contains no grid
% indices and can therefore be rasterized reproducibly on different grids.
% Objects are composed in configuration order; later objects overwrite
% earlier objects where they overlap. The circular-inclusion benchmark validates a single circle,
% while this ordered contract is retained for the later mask library.

arguments
    center_m_xz (1,2) double {mustBeFinite, mustBeNonnegative}
    radius_m (1,1) double {mustBeFinite, mustBePositive}
    material_id (1,1) {mustBeInteger, mustBePositive}
    cs_m_s (1,1) double {mustBeFinite, mustBePositive}
    rho_kg_m3 (1,1) double {mustBeFinite, mustBePositive}
    name {mustBeTextScalar} = "circle"
end

if material_id == 1
    error('kwsim:ReservedMaterialId', ...
        'material_id=1 is reserved for the homogeneous background.');
end

object = struct();
object.type = "circle";
object.name = string(name);
object.center_m_xz = center_m_xz;
object.radius_m = radius_m;
object.material_id = uint16(material_id);
object.cs_m_s = cs_m_s;
object.rho_kg_m3 = rho_kg_m3;

end
