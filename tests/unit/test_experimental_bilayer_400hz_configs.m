function tests = test_experimental_bilayer_400hz_configs
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = string(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(fullfile(root, 'src'));
testCase.TestData.root = root;
end

function testAllThreeConfigsValidateAndShareNumerics(testCase)
files = config_files(testCase.TestData.root);
resolved = cell(3,1);
for index = 1:3
    requested = kwsim.io.loadConfigJson(files(index));
    [resolved{index}, preflight] = kwsim.two_d.validateConfig(requested);
    verifyTrue(testCase, preflight.valid);
end
reference = resolved{1};
for index = 2:3
    candidate = resolved{index};
    verifyEqual(testCase, candidate.grid, reference.grid);
    verifyEqual(testCase, candidate.source, reference.source);
    verifyEqual(testCase, candidate.time.analysis_cycles, ...
        reference.time.analysis_cycles);
    verifyEqual(testCase, candidate.time.settling_cycles, ...
        reference.time.settling_cycles);
    verifyEqual(testCase, candidate.time.end_time_s_resolved, ...
        reference.time.end_time_s_resolved);
    verifyEqual(testCase, candidate.sensor, reference.sensor);
    verifyEqual(testCase, candidate.solver, reference.solver);
    verifyEqual(testCase, candidate.medium.rho_kg_m3, 1000);
    verifyEqual(testCase, candidate.medium.cp_m_s, 9.15);
end
end

function testExactTruthAndInterface(testCase)
files = config_files(testCase.TestData.root);
expected = {[1.74], [3.05], [1.74 3.05]};
for index = 1:3
    requested = kwsim.io.loadConfigJson(files(index));
    resolved = kwsim.two_d.validateConfig(requested);
    [maps, metadata] = kwsim.two_d.buildGeometry(resolved);
    verifyEqual(testCase, unique(maps.cs_m_s_xz(:)).', expected{index});
    if index == 3
        z = (0:resolved.grid.Nz-1)*resolved.grid.dz_m;
        verifyEqual(testCase, unique(maps.cs_m_s_xz(:,z<0.019)), 1.74);
        verifyEqual(testCase, unique(maps.cs_m_s_xz(:,z>=0.019)), 3.05);
        verifyEqual(testCase, metadata.objects.realized_bounds_m_xz(3), ...
            0.019, AbsTol=1e-12);
    end
end
end

function files = config_files(root)
folder = fullfile(root, 'configs', 'kwsim', 'two_d', 'benchmarks', ...
    'experimental_bilayer_400hz');
files = fullfile(folder, ["homogeneous_soft_400hz.json"; ...
    "homogeneous_stiff_400hz.json"; "bilayer_soft_stiff_400hz.json"]);
end
