function tests = test_3d_medium
%TEST_3D_MEDIUM Unit tests for the homogeneous 3D medium builder.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
end

function testHomogeneousMediumUsesResolvedProperties(testCase)
cfg = resolvedDefaultConfig();
[medium, truth] = kwsim.three_d.buildMedium(cfg);

verifyEqual(testCase, ...
    medium.sound_speed_compression, cfg.medium.cp_m_s);

verifyEqual(testCase, ...
    medium.sound_speed_shear, cfg.medium.cs_m_s);

verifyEqual(testCase, ...
    medium.density, cfg.medium.rho_kg_m3);

verifyGreaterThan(testCase, ...
    medium.sound_speed_compression, ...
    medium.sound_speed_shear);

verifyTrue(testCase, truth.homogeneous);
end

function testTruthMapsUseInternalOrientation(testCase)
cfg = resolvedDefaultConfig();
[~, truth] = kwsim.three_d.buildMedium(cfg);

expected_size = [
    cfg.grid.Nx, ...
    cfg.grid.Ny, ...
    cfg.grid.Nz
];

verifySize(testCase, truth.cp_m_s_xyz, expected_size);
verifySize(testCase, truth.cs_m_s_xyz, expected_size);
verifySize(testCase, truth.rho_kg_m3_xyz, expected_size);
verifySize(testCase, truth.material_id_xyz, expected_size);

verifyEqual(testCase, truth.orientation, "[Nx,Ny,Nz]");
verifyEqual(testCase, unique(truth.cs_m_s_xyz), ...
    single(cfg.medium.cs_m_s));
verifyEqual(testCase, unique(truth.material_id_xyz), uint16(1));
end

function testAttenuationFailsExplicitly(testCase)
cfg = resolvedDefaultConfig();
cfg.attenuation.enabled = true;

verifyError(testCase, ...
    @() kwsim.three_d.buildMedium(cfg), ...
    "kwsim:ThreeDAttenuationNotImplemented");
end

function cfg = resolvedDefaultConfig()
cfg = kwsim.three_d.defaultConfig();
[cfg, ~] = kwsim.three_d.validateConfig(cfg);
end
