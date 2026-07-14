function material = makeAttenuationMaterial(material_id, options)
%MAKEATTENUATIONMATERIAL Define P/S attenuation laws for one material.
%
% material = kwsim.materials.makeAttenuationMaterial(material_id)
%
% Alpha values are amplitude attenuation coefficients in dB/cm. Reference
% frequencies are in Hz. Separate shear and compressional laws are retained
% because pstdElastic2D requires separate Kelvin-Voigt coefficients.

arguments
    material_id (1,1) {mustBeNumeric, mustBeInteger, mustBePositive}
    options.ShearAlphaRefDbCm (1,1) double = 1.0
    options.ShearReferenceFrequencyHz (1,1) double = 500
    options.ShearPowerY (1,1) double = 1.2
    options.CompressionAlphaRefDbCm (1,1) double = 1.0
    options.CompressionReferenceFrequencyHz (1,1) double = 500
    options.CompressionPowerY (1,1) double = 1.2
end

material = struct();
material.material_id = uint16(material_id);
material.shear = makeLaw(options.ShearAlphaRefDbCm, ...
    options.ShearReferenceFrequencyHz, options.ShearPowerY);
material.compression = makeLaw(options.CompressionAlphaRefDbCm, ...
    options.CompressionReferenceFrequencyHz, options.CompressionPowerY);

end

function law = makeLaw(alpha_ref_db_cm, f_ref_hz, power_y)
law = struct('alpha_ref_db_cm', alpha_ref_db_cm, ...
    'f_ref_hz', f_ref_hz, 'power_y', power_y);
end
