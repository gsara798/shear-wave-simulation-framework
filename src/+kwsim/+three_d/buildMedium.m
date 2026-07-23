function [medium, truth] = buildMedium(cfg)
%BUILDMEDIUM Build homogeneous or heterogeneous 3D elastic material maps.
%
% Solver arrays use internal orientation [Nx,Ny,Nz]. Full truth maps are
% returned in the same orientation and are converted to public [Nz,Ny,Nx]
% by kwsim.three_d.run.

arguments
    cfg struct
end

truth = ...
    kwsim.three_d.buildMaterialMaps(cfg);

medium = struct();

if truth.homogeneous
    medium.sound_speed_compression = ...
        double(truth.cp_m_s_xyz(1));

    medium.sound_speed_shear = ...
        double(truth.cs_m_s_xyz(1));

    medium.density = ...
        double(truth.rho_kg_m3_xyz(1));
else
    medium.sound_speed_compression = ...
        truth.cp_m_s_xyz;

    medium.sound_speed_shear = ...
        truth.cs_m_s_xyz;

    medium.density = ...
        truth.rho_kg_m3_xyz;
end

if cfg.attenuation.enabled
    error( ...
        "kwsim:ThreeDAttenuationNotImplemented", ...
        "3D material attenuation is not implemented yet.");
end

end
