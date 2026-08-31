function sample = buildWavefieldSample3D(result)
%BUILDWAVEFIELDSAMPLE3D Build a backend-neutral volumetric sample.

arguments
    result (1,1) struct
end

sample = struct();
sample.schema_name = "wavefield_sample";
sample.schema_version = "1.0";
sample.spatial_dimension = 3;
sample.sample_id = "";
sample.dataset_id = "";

sample.generator = struct();
sample.generator.name = "swsynth";
sample.generator.backend = "fast_synthetic_3d";
sample.generator.repository = "gsara798/shear-wave-simulation-framework";
sample.generator.commit = "";

sample.scenario = string(result.config.scenario);
sample.seed = result.config.seed;

sample.coordinates = struct();
sample.coordinates.x_m = result.coordinates.x_m;
sample.coordinates.y_m = result.coordinates.y_m;
sample.coordinates.z_m = result.coordinates.z_m;
sample.coordinates.dx_m = result.coordinates.dx_m;
sample.coordinates.dy_m = result.coordinates.dy_m;
sample.coordinates.dz_m = result.coordinates.dz_m;
sample.coordinates.array_order = "zyx";

sample.wavefield = struct();
sample.wavefield.data_zyx = result.wavefield.U_zyx;
sample.wavefield.component = string(result.wavefield.component);
sample.wavefield.quantity = string(result.wavefield.quantity);
sample.wavefield.frequency_hz = double(result.wavefield.frequency_hz);
sample.wavefield.angular_frequency_rad_s = 2*pi*sample.wavefield.frequency_hz;
sample.wavefield.is_complex = ~isreal(result.wavefield.U_zyx);
sample.wavefield.units = unitsFor(sample.wavefield.quantity);
sample.wavefield.phasor_convention = string(result.wavefield.phasor_convention);
sample.wavefield.output_convention = "data_zyx(z,y,x)";

sample.measurement = struct();
sample.measurement.quantity = sample.wavefield.quantity;
sample.measurement.component = sample.wavefield.component;
sample.measurement.axis_xyz = result.wavefield.measurement_axis_xyz;

sample.truth = struct();
sample.truth.cs_map_zyx = result.truth.cs_map_zyx;
sample.truth.k_map_zyx = result.truth.k_map_zyx;
sample.truth.material_id_zyx = result.truth.material_id_zyx;
sample.truth.valid_mask_zyx = logical(result.truth.valid_mask_zyx);

sample.medium = struct();
sample.medium.background_cs_m_s = result.config.medium.background_cs_m_s;
sample.medium.combine_mode = result.config.medium.combine_mode;
sample.medium.objects = result.config.medium.objects;

sample.propagation = struct();
sample.propagation.model = result.config.propagation.model;
sample.propagation.source_dimension = 3;
sample.propagation.direction_space = result.config.directions.space;
sample.propagation.direction_count = result.directions.count;
sample.propagation.direction_sampling_method = result.directions.sampling_method;
sample.propagation.angular_support = result.config.directions.support;

sample.directions = struct();
sample.directions.xyz = [ ...
    double(result.directions.ux(:)), ...
    double(result.directions.uy(:)), ...
    double(result.directions.uz(:))];
sample.directions.ux = result.directions.ux;
sample.directions.uy = result.directions.uy;
sample.directions.uz = result.directions.uz;
sample.directions.retained_count = result.directions.count;

sample.excitation = struct();
sample.excitation.weights = result.wavefield.source_weights;
sample.excitation.observed_weights = result.wavefield.observed_weights;
sample.excitation.polarization_xyz = result.wavefield.polarization_xyz;
sample.excitation.projection_weights = result.wavefield.projection_weights;

sample.validation = struct();
sample.validation.valid = logical(result.validation.valid);
sample.validation.analysis_ready = ...
    sample.validation.valid && ...
    all(isfinite(sample.wavefield.data_zyx(:))) && ...
    any(abs(sample.wavefield.data_zyx(:)) > 0);
sample.validation.output_convention = "data_zyx(z,y,x)";

sample.provenance = struct();
sample.provenance.resolved_config = result.config;
sample.provenance.run_id = "";
sample.provenance.campaign_id = "";
sample.provenance.source_path = "";
sample.provenance.created_utc = "";

wavefield.validateSample(sample);

end

function units = unitsFor(quantity)
if string(quantity) == "velocity"
    units = "arbitrary_velocity";
else
    units = "arbitrary_displacement";
end
end
