function result = run(requestedConfig)
%RUN Execute one fast synthetic shear-wave simulation.
%
% Usage:
%   cfg = swsynth.defaultConfig();
%   result = swsynth.run(cfg);
%
% Result fields:
%   config
%   validation
%   coordinates
%   medium
%   directions
%   direction_metrics
%   wavefield
%   truth
%   output_convention

arguments
    requestedConfig (1,1) struct = swsynth.defaultConfig()
end

[cfg, validation] = swsynth.validateConfig(requestedConfig);
maps = swsynth.buildMediumMaps(cfg);
directions = swsynth.generateDirections(cfg);
directionMetrics = swsynth.summarizePlaneIntersection(directions);
wavefield = swsynth.synthesizeWavefield2D(cfg, maps, directions);

result = struct();
result.config = cfg;
result.validation = validation;

result.coordinates = struct();
result.coordinates.x_m = maps.x_m;
result.coordinates.z_m = maps.z_m;
result.coordinates.dx_m = maps.dx_m;
result.coordinates.dz_m = maps.dz_m;

result.medium = maps;
result.directions = directions;
result.direction_metrics = directionMetrics;
result.wavefield = wavefield;

result.truth = struct();
result.truth.cs_map_zx = maps.cs_map_zx;
result.truth.k_map_zx = maps.k_map_zx;
result.truth.material_id_zx = maps.material_id_zx;
result.truth.valid_mask_zx = true(size(maps.cs_map_zx));

result.output_convention = "U(z,x), maps(z,x)";

end
