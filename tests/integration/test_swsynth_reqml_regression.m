function test_swsynth_reqml_regression()
%TEST_SWSYNTH_REQML_REGRESSION Compare new and legacy synthetic engines.

frameworkRoot = "/Users/sara/local/shear-wave-simulation-framework";
reqmlRoot = "/Users/sara/local/req-ml";

addpath(fullfile(frameworkRoot, "src"));
addpath(fullfile(reqmlRoot, "src"));

fprintf("\n=== CASE 1: 2D PLANE-WAVE FIELD ===\n");
comparePlaneWave2D();

fprintf("\n=== CASE 2: 3D-DIRECTION SPHERICAL FIELD ===\n");
compareSpherical3D();

fprintf("\nAll legacy-to-swsynth regression comparisons passed.\n");

end

function comparePlaneWave2D()

legacy = struct();
legacy.MaskType = "homogeneous";
legacy.cs_bg = 2.0;
legacy.cs_inc = 3.0;
legacy.Lx = 0.012;
legacy.Lz = 0.010;
legacy.dx = 0.001;
legacy.dz = 0.001;
legacy.f0 = 100;
legacy.y0 = 0;
legacy.Nwaves = 8;
legacy.rmin = 0.015;
legacy.rmax = 0.020;
legacy.AmpJitter = 0.10;
legacy.DecayAlpha = 0;
legacy.Seed = 77;
legacy.UseParfor = false;
legacy.SNR = Inf;
legacy.Is2D = true;
legacy.AngleRange2D = [0, 2*pi];
legacy.SourceSampling = "ranges";
legacy.AngularSamplingMethod = "fibonacci";
legacy.ForceInPlaneWave = false;
legacy.WaveModel = "planewave";

[legacyU, legacyX, legacyZ, legacyCs, legacyK, legacyDiag] = ...
    reqml.simulate.simulate_rswe_plane(legacy);

cfg = swsynth.defaultConfig();
cfg.seed = legacy.Seed;

cfg.domain.Lx_m = legacy.Lx;
cfg.domain.Lz_m = legacy.Lz;
cfg.domain.dx_m = legacy.dx;
cfg.domain.dz_m = legacy.dz;
cfg.domain.observation_y_m = legacy.y0;

cfg.medium.background_cs_m_s = legacy.cs_bg;
cfg.medium.objects = {};

cfg.wavefield.frequency_hz = legacy.f0;
cfg.propagation.model = "plane_wave";

cfg.directions.count = legacy.Nwaves;
cfg.directions.space = "two_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.require_in_plane = false;
cfg.directions.support.type = "full_circle";
cfg.directions.support.angle_range_2d_rad = legacy.AngleRange2D;

cfg.sources.radius_range_m = [legacy.rmin, legacy.rmax];
cfg.sources.amplitude_jitter_fraction = legacy.AmpJitter;
cfg.polarization.model = "in_plane_sv";

cfg.amplitude.geometric_decay_exponent = legacy.DecayAlpha;
cfg.noise.snr_db = legacy.SNR;
cfg.execution.use_parallel = false;

result = swsynth.run(cfg);

assertClose("plane U", legacyU, result.wavefield.U_zx, 1e-6);
assertClose("plane x", legacyX, result.coordinates.x_m, 0);
assertClose("plane z", legacyZ, result.coordinates.z_m, 0);
assertClose("plane cs", legacyCs, result.truth.cs_map_zx, 0);
assertClose("plane k", legacyK, result.truth.k_map_zx, 0);
assertClose("plane ux", legacyDiag.waveDirs.ux, result.directions.ux, 0);
assertClose("plane uy", legacyDiag.waveDirs.uy, result.directions.uy, 0);
assertClose("plane uz", legacyDiag.waveDirs.uz, result.directions.uz, 0);
assertClose("plane pz", legacyDiag.wavePol.pz, result.wavefield.polarization_z, 0);
assertClose("plane weights", legacyDiag.sources.w, result.wavefield.weights, 1e-7);

fprintf("Plane-wave maximum |ΔU|: %.3e\n", ...
    max(abs(legacyU(:) - result.wavefield.U_zx(:))));

end

function compareSpherical3D()

legacy = struct();
legacy.MaskType = "homogeneous";
legacy.cs_bg = 2.5;
legacy.cs_inc = 3.5;
legacy.Lx = 0.010;
legacy.Lz = 0.008;
legacy.dx = 0.001;
legacy.dz = 0.001;
legacy.f0 = 120;
legacy.y0 = 0;
legacy.Nwaves = 10;
legacy.rmin = 0.015;
legacy.rmax = 0.020;
legacy.AmpJitter = 0.05;
legacy.DecayAlpha = 0.5;
legacy.Seed = 123;
legacy.UseParfor = false;
legacy.PhiRange = [0, 2*pi];
legacy.ThetaRange = [0, pi];
legacy.SNR = Inf;
legacy.Is2D = false;
legacy.SourceSampling = "ranges";
legacy.AngularSamplingMethod = "fibonacci";
legacy.ForceInPlaneWave = false;
legacy.WaveModel = "spherical";

[legacyU, legacyX, legacyZ, legacyCs, legacyK, legacyDiag] = ...
    reqml.simulate.simulate_rswe_plane(legacy);

cfg = swsynth.defaultConfig();
cfg.seed = legacy.Seed;

cfg.domain.Lx_m = legacy.Lx;
cfg.domain.Lz_m = legacy.Lz;
cfg.domain.dx_m = legacy.dx;
cfg.domain.dz_m = legacy.dz;
cfg.domain.observation_y_m = legacy.y0;

cfg.medium.background_cs_m_s = legacy.cs_bg;
cfg.medium.objects = {};

cfg.wavefield.frequency_hz = legacy.f0;
cfg.propagation.model = "spherical_wave";

cfg.directions.count = legacy.Nwaves;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.require_in_plane = false;
cfg.directions.support.type = "full_sphere";
cfg.directions.support.phi_range_rad = legacy.PhiRange;
cfg.directions.support.theta_range_rad = legacy.ThetaRange;

cfg.sources.radius_range_m = [legacy.rmin, legacy.rmax];
cfg.sources.amplitude_jitter_fraction = legacy.AmpJitter;
cfg.polarization.model = "transverse_random";

cfg.amplitude.geometric_decay_exponent = legacy.DecayAlpha;
cfg.noise.snr_db = legacy.SNR;
cfg.execution.use_parallel = false;

result = swsynth.run(cfg);

assertClose("spherical U", legacyU, result.wavefield.U_zx, 1e-6);
assertClose("spherical x", legacyX, result.coordinates.x_m, 0);
assertClose("spherical z", legacyZ, result.coordinates.z_m, 0);
assertClose("spherical cs", legacyCs, result.truth.cs_map_zx, 0);
assertClose("spherical k", legacyK, result.truth.k_map_zx, 0);
assertClose("spherical ux", legacyDiag.waveDirs.ux, result.directions.ux, 1e-7);
assertClose("spherical uy", legacyDiag.waveDirs.uy, result.directions.uy, 1e-7);
assertClose("spherical uz", legacyDiag.waveDirs.uz, result.directions.uz, 1e-7);
assertClose("spherical pz", legacyDiag.wavePol.pz, result.wavefield.polarization_z, 1e-7);
assertClose("spherical weights", legacyDiag.sources.w, result.wavefield.weights, 1e-7);
assertClose("spherical source x", legacyDiag.sources.x, result.wavefield.sources.x_m, 1e-7);
assertClose("spherical source y", legacyDiag.sources.y, result.wavefield.sources.y_m, 1e-7);
assertClose("spherical source z", legacyDiag.sources.z, result.wavefield.sources.z_m, 1e-7);

fprintf("Spherical maximum |ΔU|: %.3e\n", ...
    max(abs(legacyU(:) - result.wavefield.U_zx(:))));

end

function assertClose(label, expected, actual, tolerance)

if ~isequal(size(expected), size(actual))
    error("Regression:SizeMismatch", ...
        "%s size mismatch: expected %s, actual %s.", ...
        label, mat2str(size(expected)), mat2str(size(actual)));
end

difference = max(abs(double(expected(:)) - double(actual(:))));

if isempty(difference)
    difference = 0;
end

if difference > tolerance
    error("Regression:ValueMismatch", ...
        "%s maximum absolute difference %.6e exceeds tolerance %.6e.", ...
        label, difference, tolerance);
end

fprintf("%-24s max |Δ| = %.3e\n", label, difference);

end
