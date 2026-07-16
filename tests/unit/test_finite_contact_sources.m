function tests = test_finite_contact_sources
%TEST_FINITE_CONTACT_SOURCES Unit tests for finite external source geometry.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'benchmarks'));
end

function testReferenceContactGeometryAndDrive(testCase)
cfg = kwsim_benchmarks.finite_contacts_2d.config("directional");
[cfg, preflight] = kwsim.two_d.validateConfig(cfg);
bank = cfg.source.resolved_bank;
verifyTrue(testCase, preflight.valid);
verifyEqual(testCase, bank.vibrator_count, 8);
verifyEqual(testCase, bank.solver_channel_count, 24);
for vibrator = bank.vibrators.'
    verifyEqual(testCase, vibrator.contact_node_count, 3);
    verifyEqual(testCase, vibrator.contact_node_weights, [0.5; 1; 0.5], ...
        'AbsTol', 1e-14);
    verifyEqual(testCase, vibrator.realized_contact_span_m, 4e-3, ...
        'AbsTol', 1e-14);
end
verifyLessThanOrEqual(testCase, bank.drive_power_relative_error, 1e-14);
end

function testDenseFiniteContactIsRejected(testCase)
cfg = kwsim_benchmarks.finite_contacts_2d.config("diffuse");
cfg.source.contact_radius_m = 1.5e-3;
cfg.source.contact_node_spacing_points = 3;
verifyError(testCase, @() kwsim.two_d.validateConfig(cfg), ...
    'kwsim:InvalidConfiguration');
end

function testArbitraryCardinalOrientation(testCase)
cfg = kwsim_benchmarks.finite_contacts_2d.config("directional");
cfg.source.target_angle_deg = 90;
[cfg, ~] = kwsim.two_d.validateConfig(cfg);
vibrators = cfg.source.resolved_bank.vibrators;
verifyEqual(testCase, unique(string({vibrators.side})), "top");
verifyEqual(testCase, vertcat(vibrators.propagation_xz), ...
    repmat([0, 1], numel(vibrators), 1), 'AbsTol', 1e-14);
verifyEqual(testCase, vertcat(vibrators.polarization_xz), ...
    repmat([-1, 0], numel(vibrators), 1), 'AbsTol', 1e-14);
end

function testObliqueDirectionUsesGeometricPhaseGradient(testCase)
cfg = kwsim_benchmarks.finite_contacts_2d.config("directional");
cfg.source.target_angle_deg = 35;
[cfg, ~] = kwsim.two_d.validateConfig(cfg);
vibrators = cfg.source.resolved_bank.vibrators;
direction = [cosd(35), sind(35)];
polarization = [-sind(35), cosd(35)];
verifyEqual(testCase, unique(string({vibrators.side})), "left");
verifyEqual(testCase, vertcat(vibrators.propagation_xz), ...
    repmat(direction, numel(vibrators), 1), 'AbsTol', 1e-14);
verifyEqual(testCase, vertcat(vibrators.polarization_xz), ...
    repmat(polarization, numel(vibrators), 1), 'AbsTol', 1e-14);
k = 2*pi*cfg.source.f0_hz/cfg.medium.cs_m_s;
expected_complex_phase = exp(-1i*k*( ...
    vertcat(vibrators.center_m_xz)*direction.'));
verifyEqual(testCase, exp(1i*[vibrators.phase_rad].'), ...
    expected_complex_phase, 'AbsTol', 1e-12);
end

function testContactModelComparison(testCase)
x_m = (0:9)*0.5e-3;
z_m = (0:7)*0.5e-3;
[X, Z] = meshgrid(x_m, z_m);
field = exp(-1i*2*pi*(X + 0.2*Z)/4e-3);
point = syntheticResult("point", field, x_m, z_m, 0);
finite = syntheticResult("finite_segment", 2i*field, x_m, z_m, 4e-3);
comparison = kwsim_benchmarks.finite_contacts_2d.compareModels(point, finite);
verifyEqual(testCase, comparison.correlation_magnitude, 1, 'AbsTol', 1e-12);
verifyLessThanOrEqual(testCase, ...
    comparison.optimal_scaled_shape_relative_error, 1e-12);
verifyEqual(testCase, comparison.rms_amplitude_ratio_finite_to_point, 2, ...
    'AbsTol', 1e-12);
end

function result = syntheticResult(model, field, x_m, z_m, span_m)
result = struct();
result.source.contact_model = model;
result.axes = struct('x_m', x_m, 'z_m', z_m, 'f0_hz', 500);
result.fields.displacement.axial_total_zx = field;
result.diagnostics.metrics.contact.requested_contact_span_m = span_m;
end
