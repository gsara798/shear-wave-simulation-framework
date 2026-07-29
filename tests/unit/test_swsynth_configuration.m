function tests = test_swsynth_configuration
%TEST_SWSYNTH_CONFIGURATION Unit tests for synthetic configuration handling.

tests = functiontests(localfunctions);

end

function testDefaultConfigurationIsValid(testCase)

cfg = swsynth.defaultConfig();
[resolved, report] = swsynth.validateConfig(cfg);

verifyTrue(testCase, report.valid);
verifyEqual(testCase, resolved.schema_version, "1.0");
verifyEqual(testCase, resolved.propagation.model, "spherical_wave");
verifyEqual( ...
    testCase, ...
    resolved.propagation.phase_model, ...
    "local_k_distance");
verifyEqual( ...
    testCase, ...
    resolved.propagation.phase_tolerance_rad, ...
    0.03);
verifyEqual( ...
    testCase, ...
    resolved.propagation.maximum_refinement_depth, ...
    10);
verifyEqual(testCase, resolved.directions.count, 30);
verifyEqual(testCase, report.output_convention, "U(z,x)");
verifyEqual(testCase, report.grid_size_zx, [501, 501]);

end

function testPartialConfigurationMergesWithDefaults(testCase)

requested = struct();
requested.seed = 11;
requested.domain = struct("Lx_m", 0.02, "Lz_m", 0.03);
requested.directions = struct("count", 12);

[resolved, report] = swsynth.validateConfig(requested);

verifyEqual(testCase, resolved.seed, 11);
verifyEqual(testCase, resolved.domain.Lx_m, 0.02);
verifyEqual(testCase, resolved.domain.Lz_m, 0.03);
verifyEqual(testCase, resolved.domain.dx_m, 1e-4);
verifyEqual(testCase, resolved.directions.count, 12);
verifyEqual(testCase, report.grid_size_zx, [301, 201]);

end

function testUnknownFieldsAreRejected(testCase)

cfg = swsynth.defaultConfig();
cfg.unknown_field = 1;

verifyError( ...
    testCase, ...
    @() swsynth.validateConfig(cfg), ...
    "swsynth:UnknownConfigField");

end

function testPlaneWaveRejectsHeterogeneousMedium(testCase)

cfg = swsynth.defaultConfig();
cfg.propagation.model = "plane_wave";
cfg.medium.objects = {
    struct( ...
        "type", "circle", ...
        "cs_m_s", 3, ...
        "center_xz_m", [0.025, 0.025], ...
        "radius_m", 0.005)
};

verifyError( ...
    testCase, ...
    @() swsynth.validateConfig(cfg), ...
    "swsynth:PlaneWaveRequiresHomogeneousMedium");

end

function testStraightRayConfigurationIsAccepted(testCase)

cfg = swsynth.defaultConfig();
cfg.propagation.phase_model = "straight_ray_numerical";
cfg.propagation.phase_tolerance_rad = 0.02;
cfg.propagation.maximum_refinement_depth = 12;

[resolved, report] = swsynth.validateConfig(cfg);

verifyEqual( ...
    testCase, ...
    resolved.propagation.phase_model, ...
    "straight_ray_numerical");
verifyEqual(testCase, resolved.propagation.phase_tolerance_rad, 0.02);
verifyEqual(testCase, resolved.propagation.maximum_refinement_depth, 12);
verifyEqual(testCase, report.phase_model, "straight_ray_numerical");

end

function testUnknownPhaseModelIsRejected(testCase)

cfg = swsynth.defaultConfig();
cfg.propagation.phase_model = "invalid_phase_model";

verifyError( ...
    testCase, ...
    @() swsynth.validateConfig(cfg), ...
    "swsynth:InvalidChoice");

end

function testJsonEmptyMediumObjectsAreNormalized(testCase)

requested = jsondecode( ...
    '{"medium":{"objects":[]}}');

[resolved, report] = swsynth.validateConfig(requested);

verifyTrue(testCase, report.valid);
verifyTrue(testCase, iscell(resolved.medium.objects));
verifyEmpty(testCase, resolved.medium.objects);

end

function testJsonObjectStructIsNormalizedToCell(testCase)

json = [ ...
    '{"medium":{' ...
    '"objects":[{' ...
    '"type":"circle",' ...
    '"cs_m_s":3.0,' ...
    '"center_xz_m":[0.025,0.025],' ...
    '"radius_m":0.005' ...
    '}]}}'];

requested = jsondecode(json);
[resolved, report] = swsynth.validateConfig(requested);

verifyTrue(testCase, report.valid);
verifyTrue(testCase, iscell(resolved.medium.objects));
verifyNumElements(testCase, resolved.medium.objects, 1);
verifyEqual( ...
    testCase, ...
    resolved.medium.objects{1}.type, ...
    "circle");
verifyEqual( ...
    testCase, ...
    resolved.medium.objects{1}.cs_m_s, ...
    3.0);

end

function testJsonMultipleObjectsAreNormalizedToCell(testCase)

json = [ ...
    '{"medium":{' ...
    '"objects":[' ...
    '{' ...
    '"type":"circle",' ...
    '"cs_m_s":3.0,' ...
    '"center_xz_m":[0.020,0.025],' ...
    '"radius_m":0.004' ...
    '},' ...
    '{' ...
    '"type":"circle",' ...
    '"cs_m_s":4.0,' ...
    '"center_xz_m":[0.035,0.025],' ...
    '"radius_m":0.003' ...
    '}' ...
    ']}}'];

requested = jsondecode(json);
[resolved, report] = swsynth.validateConfig(requested);

verifyTrue(testCase, report.valid);
verifyTrue(testCase, iscell(resolved.medium.objects));
verifyNumElements(testCase, resolved.medium.objects, 2);
verifyEqual(testCase, resolved.medium.objects{1}.cs_m_s, 3.0);
verifyEqual(testCase, resolved.medium.objects{2}.cs_m_s, 4.0);

end
