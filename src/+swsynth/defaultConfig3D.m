function cfg = defaultConfig3D()
%DEFAULTCONFIG3D Return default volumetric 3D synthetic configuration.
%
% The backend produces one observed complex harmonic field with public
% orientation U(z,y,x). OCE-like simulations use this same 3D physics path
% and differ only through the measurement model.

base = swsynth.defaultConfig();

cfg = struct();
cfg.schema_version = "1.0";
cfg.scenario = "synthetic_wavefield_3d";
cfg.seed = base.seed;

cfg.domain = struct();
cfg.domain.Lx_m = base.domain.Lx_m;
cfg.domain.Ly_m = base.domain.Lx_m;
cfg.domain.Lz_m = base.domain.Lz_m;
cfg.domain.dx_m = base.domain.dx_m;
cfg.domain.dy_m = base.domain.dx_m;
cfg.domain.dz_m = base.domain.dz_m;

cfg.medium = struct();
cfg.medium.background_cs_m_s = base.medium.background_cs_m_s;
cfg.medium.combine_mode = "overlay";
cfg.medium.objects = {};

cfg.wavefield = struct();
cfg.wavefield.frequency_hz = base.wavefield.frequency_hz;
cfg.wavefield.quantity = "velocity";
cfg.wavefield.observed_component = "axial_total";

cfg.measurement = struct();
cfg.measurement.axis_xyz = [0, 0, 1];

cfg.propagation = struct();
cfg.propagation.model = "plane_wave";
cfg.propagation.eikonal = struct();
cfg.propagation.eikonal.maximum_iterations = 200;
cfg.propagation.eikonal.tolerance_s = 1e-10;

cfg.directions = base.directions;
cfg.directions.space = "three_dimensional";
cfg.directions.in_plane_count = 0;

cfg.sources = struct();
cfg.sources.phase_policy = "random_uniform";
cfg.sources.amplitude_jitter_fraction = base.sources.amplitude_jitter_fraction;

cfg.polarization = struct();
cfg.polarization.model = "transverse_random";

cfg.noise = struct();
cfg.noise.snr_db = Inf;

cfg.execution = struct();
cfg.execution.use_parallel = true;
cfg.execution.synthesis_batch_size = 128;

end
