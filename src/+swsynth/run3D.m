function result = run3D(requestedConfig)
%RUN3D Execute one volumetric analytical 3D shear-wave simulation.

arguments
    requestedConfig (1,1) struct = swsynth.defaultConfig3D()
end

[cfg, validation] = swsynth.validateConfig3D(requestedConfig);
field = swsynth.synthesizePlaneWave3D(cfg);

Nz = numel(field.z_m);
Ny = numel(field.y_m);
Nx = numel(field.x_m);
cs = cfg.medium.background_cs_m_s;
k0 = field.k0_rad_m;

result = struct();
result.config = cfg;
result.validation = validation;
result.coordinates = struct( ...
    "x_m", field.x_m, ...
    "y_m", field.y_m, ...
    "z_m", field.z_m, ...
    "dx_m", field.dx_m, ...
    "dy_m", field.dy_m, ...
    "dz_m", field.dz_m);
result.medium = struct( ...
    "background_cs_m_s", cs, ...
    "cs_map_zyx", cs * ones(Nz,Ny,Nx));
result.directions = field.directions;
result.wavefield = field;
result.truth = struct();
result.truth.cs_map_zyx = cs * ones(Nz,Ny,Nx);
result.truth.k_map_zyx = k0 * ones(Nz,Ny,Nx);
result.truth.material_id_zyx = ones(Nz,Ny,Nx,"uint16");
result.truth.valid_mask_zyx = true(Nz,Ny,Nx);
result.output_convention = "U(z,y,x), maps(z,y,x)";
result.sample = swsynth.buildWavefieldSample3D(result);

end
