function tests = test_attenuation_power_law
%TEST_ATTENUATION_POWER_LAW Unit tests for power-law and Kelvin-Voigt mapping.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
addpath(fullfile(root, 'benchmarks'));
end

function testBenchmarkConfigurationIsDeterministic(testCase)

first = kwsim_benchmarks.attenuation_power_law_2d.config( ...
    ShearAlphaRefDbCm=1.7, ...
    ShearReferenceFrequencyHz=450, ...
    ShearPowerY=1.1, ...
    Seed=42);

second = kwsim_benchmarks.attenuation_power_law_2d.config( ...
    ShearAlphaRefDbCm=1.7, ...
    ShearReferenceFrequencyHz=450, ...
    ShearPowerY=1.1, ...
    Seed=42);

verifyEqual(testCase, first, second);

law = first.attenuation.materials(1).shear;

verifyEqual(testCase, law.alpha_ref_db_cm, 1.7);
verifyEqual(testCase, law.f_ref_hz, 450);
verifyEqual(testCase, law.power_y, 1.1);
verifyEqual(testCase, first.seed, 42);

end

function testPowerLawEvaluation(testCase)
alpha = kwsim.materials.evaluatePowerLawAttenuation(1, 500, 1.2, 250);
verifyEqual(testCase, alpha, 0.5^1.2, 'AbsTol', 1e-14);
end

function testReferenceConversionAndTruthMaps(testCase)
cfg = kwsim_benchmarks.attenuation_power_law_2d.config();
[resolved, preflight] = kwsim.two_d.validateConfig(cfg);
[medium, truth] = kwsim.two_d.buildMedium(resolved);
verifyTrue(testCase, preflight.valid);
verifyEqual(testCase, resolved.source.layout, "single_contact");
verifyEqual(testCase, resolved.source.contact_model, "point");
verifyEqual(testCase, unique(medium.alpha_coeff_shear), 4e6, ...
    'RelTol', 1e-14);
verifyEqual(testCase, unique(truth.attenuation_db_cm_xz), 1, ...
    'AbsTol', 1e-14);
verifyGreaterThanOrEqual(testCase, min(truth.attenuation.chi_pa_s_xz, [], 'all'), 0);
end

function testLosslessModeOmitsSolverCoefficients(testCase)
cfg = kwsim.two_d.defaultConfig();
[resolved, ~] = kwsim.two_d.validateConfig(cfg);
[medium, truth] = kwsim.two_d.buildMedium(resolved);
verifyFalse(testCase, isfield(medium, 'alpha_coeff_shear'));
verifyFalse(testCase, truth.attenuation.enabled);
verifyEqual(testCase, truth.attenuation_db_cm_xz, ...
    zeros(cfg.grid.Nx, cfg.grid.Nz));
end

function testHeterogeneousMaterialsMapExactly(testCase)
cfg = heterogeneousAttenuationConfig();
cfg.stage = 4;
cfg.grid.cfl = 0.025;
% This unit test validates heterogeneous material rasterization only;
% the full sensor is intentionally not executed at the viscous time step.
cfg.diagnostics.maximum_sensor_memory_bytes = Inf;
cfg.attenuation.enabled = true;
cfg.attenuation.materials = [ ...
    kwsim.materials.makeAttenuationMaterial(1), ...
    kwsim.materials.makeAttenuationMaterial(2, ShearAlphaRefDbCm=2, ...
        CompressionAlphaRefDbCm=2)];
[resolved, ~] = kwsim.two_d.validateConfig(cfg);
[~, truth] = kwsim.two_d.buildMedium(resolved);
background = truth.material_id_xz == 1;
inclusion = truth.material_id_xz == 2;
verifyEqual(testCase, unique( ...
    truth.attenuation.shear_alpha_at_f0_db_cm_xz(background)), 1);
verifyEqual(testCase, unique( ...
    truth.attenuation.shear_alpha_at_f0_db_cm_xz(inclusion)), 2);
end

function testRejectsMissingMaterialLaw(testCase)
cfg = heterogeneousAttenuationConfig();
cfg.stage = 4;
cfg.grid.cfl = 0.05;
cfg.attenuation.enabled = true;
verifyError(testCase, @() kwsim.two_d.validateConfig(cfg), ...
    'kwsim:InvalidConfiguration');
end

function testRejectsLosslessCflForKelvinVoigt(testCase)
cfg = kwsim_benchmarks.attenuation_power_law_2d.config();
cfg.grid.cfl = 0.2;
verifyError(testCase, @() kwsim.two_d.validateConfig(cfg), ...
    'kwsim:InvalidConfiguration');
end

function testRejectsNegativeVolumetricViscosity(testCase)
cfg = kwsim_benchmarks.attenuation_power_law_2d.config();
cfg.attenuation.materials = kwsim.materials.makeAttenuationMaterial(1, ...
    ShearAlphaRefDbCm=1, CompressionAlphaRefDbCm=1e-5);
verifyError(testCase, @() kwsim.two_d.validateConfig(cfg), ...
    'kwsim:InvalidConfiguration');
end

function cfg = heterogeneousAttenuationConfig()
%HETEROGENEOUSATTENUATIONCONFIG Local fixture for attenuation unit tests.
%
% This fixture intentionally does not depend on a benchmark configuration.

cfg = kwsim.two_d.defaultConfig();
cfg.scenario = "heterogeneous_attenuation_unit_fixture";

% Odd Nz gives an exact axial symmetry plane.
cfg.grid.Nz = 95;

center_x_m = 0.5 * (cfg.grid.Nx - 1) * cfg.grid.dx_m;
center_z_m = 0.5 * (cfg.grid.Nz - 1) * cfg.grid.dz_m;

cfg.geometry.objects = kwsim.two_d.makeCircleObject( ...
    [center_x_m, center_z_m], ...
    8e-3, ...
    2, ...
    3.0, ...
    1020, ...
    "attenuation_test_inclusion");

end

