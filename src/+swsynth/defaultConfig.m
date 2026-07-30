function cfg = defaultConfig()
%DEFAULTCONFIG Return the default fast synthetic wavefield configuration.
%
% The synthetic backend produces a complex two-dimensional observation
% field with public orientation U(z,x). Propagation directions may be
% restricted to the x-z plane or sampled in three dimensions.
%
% Example:
%   cfg = swsynth.defaultConfig();

cfg = struct();

cfg.schema_version = "1.0";
cfg.scenario = "synthetic_wavefield_2d";
cfg.seed = 1;

cfg.domain = struct();
cfg.domain.Lx_m = 0.05;
cfg.domain.Lz_m = 0.05;
cfg.domain.dx_m = 1e-4;
cfg.domain.dz_m = 1e-4;
cfg.domain.observation_y_m = 0.0;

cfg.medium = struct();
cfg.medium.background_cs_m_s = 2.0;
cfg.medium.combine_mode = "overlay";
cfg.medium.objects = {};

cfg.wavefield = struct();
cfg.wavefield.frequency_hz = 700;
cfg.wavefield.observed_component = "axial";

cfg.propagation = struct();
cfg.propagation.model = "spherical_wave";
cfg.propagation.phase_model = "local_k_distance";

% Behavior for projected3d_eikonal directions that become evanescent in
% part of the heterogeneous medium:
%   "error"  : reject the complete run
%   "filter" : remove those directional components deterministically
cfg.propagation.nonpropagating_policy = "error";

cfg.propagation.phase_tolerance_rad = 0.03;
cfg.propagation.maximum_refinement_depth = 10;

cfg.directions = struct();
cfg.directions.count = 30;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "random";

% Legacy compatibility flag. New configurations should use
% directions.in_plane_count.
cfg.directions.require_in_plane = false;
cfg.directions.in_plane_count = 0;

cfg.directions.support = struct();
cfg.directions.support.type = "full_sphere";
cfg.directions.support.axis_xyz = [-1, 0, 0];

% Used by support.type = "solid_angle_cap".
% 4*pi is a full sphere and 2*pi is a hemisphere.
cfg.directions.support.solid_angle_sr = 4*pi;

cfg.directions.support.half_angle_deg = 180;
cfg.directions.support.band_half_width_deg = 90;
cfg.directions.support.phi_range_rad = [0, 2*pi];
cfg.directions.support.theta_range_rad = [0, pi];
cfg.directions.support.angle_range_2d_rad = [0, 2*pi];

cfg.sources = struct();
cfg.sources.radius_range_m = [];
cfg.sources.phase_policy = "random_uniform";
cfg.sources.amplitude_jitter_fraction = 0.10;

cfg.polarization = struct();
cfg.polarization.model = "transverse_random";

cfg.amplitude = struct();
cfg.amplitude.geometric_decay_exponent = 0;

cfg.noise = struct();
cfg.noise.snr_db = Inf;

cfg.execution = struct();
cfg.execution.use_parallel = true;

end
