function tests = test_stage3_sources
%TEST_STAGE3_SOURCES Unit tests for reproducible labelled vibrator banks.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
end

function testBanksAreNormalizedTransverseAndReproducible(testCase)
for regime = ["directional", "partially_diffuse", "diffuse"]
    cfg = kwsim.two_d.stage3Config(regime);
    [first, preflight] = kwsim.two_d.validateConfig(cfg);
    [second, ~] = kwsim.two_d.validateConfig(cfg);
    bank = first.source.resolved_bank;
    verifyTrue(testCase, preflight.valid);
    verifyEqual(testCase, bank.label_mask_xz, ...
        second.source.resolved_bank.label_mask_xz);
    verifyEqual(testCase, unique(bank.label_mask_xz), ...
        uint16((0:bank.vibrator_count).'));
    verifyEqual(testCase, [bank.vibrators.contact_node_count], ...
        ones(1, bank.vibrator_count));
    verifyLessThanOrEqual(testCase, bank.drive_power_relative_error, 1e-14);
    for vibrator = bank.vibrators.'
        verifyLessThanOrEqual(testCase, abs(dot(vibrator.propagation_xz, ...
            vibrator.polarization_xz)), 1e-14);
    end
end
end

function testPartialBankSplitsPrescribedDriveEqually(testCase)
cfg = kwsim.two_d.stage3Config("partially_diffuse");
[cfg, ~] = kwsim.two_d.validateConfig(cfg);
vibrators = cfg.source.resolved_bank.vibrators;
groups = string({vibrators.group});
coherent = sum([vibrators(groups == "coherent").drive_power_weight]);
diffuse = sum([vibrators(groups == "diffuse").drive_power_weight]);
verifyEqual(testCase, coherent, 0.5, 'AbsTol', 1e-14);
verifyEqual(testCase, diffuse, 0.5, 'AbsTol', 1e-14);
end

function testTotalDriveDoesNotDependOnVibratorCount(testCase)
cfg = kwsim.two_d.stage3Config("directional");
requested = cfg.source.total_drive_rms_squared_m2_s2;
for count = [4, 8, 12]
    cfg.source.vibrator_count = count;
    [resolved, ~] = kwsim.two_d.validateConfig(cfg);
    realized = resolved.source.resolved_bank.total_drive_rms_squared_m2_s2;
    verifyEqual(testCase, realized, requested, 'RelTol', 1e-14);
end
end

function testPlaneWaveAngularSpectrumUsesPublicAngleConvention(testCase)
cfg = kwsim.two_d.stage3Config("directional");
x_m = (0:79)*cfg.grid.dx_m;
z_m = (0:79)*cfg.grid.dz_m;
[X, ~] = meshgrid(x_m, z_m);
k = 2*pi*cfg.source.f0_hz/cfg.medium.cs_m_s;
plane_wave = exp(-1i*k*X);
result = struct();
result.config_resolved = cfg;
result.axes = struct('x_m', x_m, 'z_m', z_m, ...
    'f0_hz', cfg.source.f0_hz);
result.truth.cs_m_s_zx = cfg.medium.cs_m_s*ones(size(plane_wave));
result.fields.displacement.lateral_shear_zx = zeros(size(plane_wave));
result.fields.displacement.axial_shear_zx = plane_wave;
metrics = kwsim.diagnostics.angularSpectrum2D(result);
verifyGreaterThan(testCase, metrics.target_concentration, 0.95);
verifyLessThanOrEqual(testCase, abs(metrics.dominant_angle_deg), 2.5);
verifyEqual(testCase, metrics.spectral_speed_m_s, cfg.medium.cs_m_s, ...
    'RelTol', 0.03);
verifyGreaterThan(testCase, metrics.nearest_neighbor_spatial_coherence, 0.99);
end
