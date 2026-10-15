function result = runVolumetric(requestedConfig)
%RUNVOLUMETRIC Internal volumetric backend; public entry is swsynth.run.

arguments
    requestedConfig (1,1) struct = swsynth.defaultConfig3D()
end

[cfg, validation] = swsynth.validateConfig3D(requestedConfig);
maps = swsynth.buildMediumMaps3D(cfg);

phaseSolver = "";
switch cfg.propagation.model
    case "plane_wave"
        solver = swsynth.phase.validateCompatibility( ...
            "plane_wave",cfg.propagation.phase_model,"volumetric3d", ...
            ~isempty(cfg.medium.objects));
        phaseSolver = solver;
        field = swsynth.propagation.plane_wave.synthesizeVolumetric3D( ...
            cfg,maps);

    case "spherical_wave"
        phaseSolver = "spherical_point_force_analytical_3d";
        field = swsynth.propagation.spherical.point_source.shear_far_field.synthesizeVolumetric3D(cfg, maps);

    otherwise
        error("swsynth:UnsupportedVolumetricPropagationModel", ...
            "Unsupported volumetric wave model: %s.", ...
            cfg.propagation.model);
end

% Record execution and request separately from legacy backend labels.
field.phase_solver = phaseSolver;
field.requested_phase_model = string(requestedConfig.propagation.phase_model);
field.requested_propagation_model = string(requestedConfig.propagation.model);

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
