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
