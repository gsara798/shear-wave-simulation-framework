function result = run3D(requestedConfig)
%RUN3D Execute one volumetric 3D synthetic shear-wave simulation.

arguments
    requestedConfig (1,1) struct = swsynth.defaultConfig3D()
end

[cfg, validation] = swsynth.validateConfig3D(requestedConfig);
maps = swsynth.buildMediumMaps3D(cfg);

switch cfg.propagation.model
    case "plane_wave"
        field = swsynth.synthesizePlaneWave3D(cfg);

    case "volumetric_eikonal"
        field = swsynth.synthesizeVolumetricEikonal3D(cfg, maps);

    otherwise
        error("swsynth:UnsupportedVolumetricPropagationModel", ...
            "Unsupported volumetric propagation model: %s.", ...
            cfg.propagation.model);
end

result = struct();
result.config = cfg;
result.validation = validation;
result.coordinates = struct( ...
    "x_m", maps.x_m, ...
    "y_m", maps.y_m, ...
    "z_m", maps.z_m, ...
    "dx_m", maps.dx_m, ...
    "dy_m", maps.dy_m, ...
    "dz_m", maps.dz_m);
result.medium = maps;
result.medium.background_cs_m_s = cfg.medium.background_cs_m_s;
result.directions = field.directions;
result.wavefield = field;
result.truth = struct();
result.truth.cs_map_zyx = maps.cs_map_zyx;
result.truth.k_map_zyx = maps.k_map_zyx;
result.truth.material_id_zyx = maps.material_id_zyx;
result.truth.valid_mask_zyx = true(size(maps.cs_map_zyx));
result.output_convention = "U(z,y,x), maps(z,y,x)";
result.sample = swsynth.buildWavefieldSample3D(result);

end
