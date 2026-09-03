function tests = test_finite_contact_sources
%TEST_FINITE_CONTACT_SOURCES Unit tests for finite external source geometry.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
end

function testReferenceContactGeometryAndDrive(testCase)
cfg = finiteContactFixture("directional");
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
cfg = finiteContactFixture("diffuse");
cfg.source.contact_radius_m = 1.5e-3;
cfg.source.contact_node_spacing_points = 3;
verifyError(testCase, @() kwsim.two_d.validateConfig(cfg), ...
    'kwsim:InvalidConfiguration');
end

function testArbitraryCardinalOrientation(testCase)
cfg = finiteContactFixture("directional");
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
cfg = finiteContactFixture("directional");
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

function cfg = finiteContactFixture(regime)
arguments
    regime (1,1) string {mustBeMember(regime, ...
        ["directional","partially_diffuse","diffuse"])} = "directional"
end
cfg = kwsim.two_d.defaultConfig();
cfg.scenario = "finite_contact_unit_fixture_" + regime;
cfg.seed = 1002;
if regime == "directional"
    vibratorCount = 8;
else
    vibratorCount = 16;
end
if regime == "diffuse"
    cfg.time.settling_cycles = 6;
end
cfg = kwsim.sources.configureVibratorBank(cfg,regime,vibratorCount);
cfg = kwsim.sources.configureFiniteContact( ...
    cfg,ContactRadiusM=2e-3,NodeSpacingPoints=4,Profile="raised_cosine");
cfg.source.ramp_cycles = 3;
cfg.sensor.boundary_margin_m = 4e-3;
end
