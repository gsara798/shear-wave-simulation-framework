function tests=test_experimental_bilayer_source_polarization_configs
tests=functiontests(localfunctions);
end

function setupOnce(testCase)
root=string(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(fullfile(root,'src')); addpath(fullfile(root,'benchmarks'));
testCase.TestData.root=root;
end

function testSixConfigsShareNumericsAndFixedFov(testCase)
files=config_files(testCase.TestData.root); resolved=cell(6,1);
for index=1:6
    requested=kwsim.io.loadConfigJson(files(index));
    [resolved{index},preflight]=kwsim.two_d.validateConfig(requested);
    verifyTrue(testCase,preflight.valid);
end
reference=resolved{1};
for index=2:6
    candidate=resolved{index};
    verifyEqual(testCase,candidate.grid,reference.grid);
    verifyEqual(testCase,candidate.time.analysis_cycles,reference.time.analysis_cycles);
    verifyEqual(testCase,candidate.time.settling_cycles,reference.time.settling_cycles);
    verifyEqual(testCase,candidate.time.end_time_s_resolved, ...
        reference.time.end_time_s_resolved);
    verifyEqual(testCase,candidate.sensor,reference.sensor);
    verifyEqual(testCase,candidate.solver,reference.solver);
    verifyEqual(testCase,rmfield(candidate.source,'polarization_xz'), ...
        rmfield(reference.source,'polarization_xz'));
end
verifyEqual(testCase,reference.derived.realized_analysis_bounds_m_xz, ...
    [0.0114,0.0494,0,0.0358625],AbsTol=1e-12);
verifyEqual(testCase,reference.derived.source_contact_to_analysis_gap_m, ...
    0.0102125,AbsTol=1e-12);
verifyEqual(testCase,numel(reference.sensor.x_indices),161);
verifyEqual(testCase,numel(reference.sensor.z_indices),152);
end

function testPolarizationAndTruthCrossing(testCase)
files=config_files(testCase.TestData.root);
for index=1:6
    cfg=kwsim.two_d.validateConfig(kwsim.io.loadConfigJson(files(index)));
    scenario=string(cfg.scenario);
    if contains(scenario,'source_x_')
        verifyEqual(testCase,cfg.source.polarization_xz,[1,0]);
    else
        verifyEqual(testCase,cfg.source.polarization_xz,[0,1]);
    end
    maps=kwsim.two_d.buildGeometry(cfg);
    if contains(scenario,'_bilayer_soft_stiff_')
        z=(0:cfg.grid.Nz-1)*cfg.grid.dz_m;
        verifyEqual(testCase,unique(maps.cs_m_s_xz(:,z<0.019)),1.74);
        verifyEqual(testCase,unique(maps.cs_m_s_xz(:,z>=0.019)),3.05);
    elseif contains(scenario,'homogeneous_soft_')
        verifyEqual(testCase,unique(maps.cs_m_s_xz),1.74);
    else
        verifyEqual(testCase,unique(maps.cs_m_s_xz),3.05);
    end
end
end

function testGeometryAuditIsGeneratedWithoutSolver(testCase)
folder=tempname; cleanup=onCleanup(@() rmdir(folder,'s'));
audit=kwsim_benchmarks.experimental_bilayer_source_polarization_2d. ...
    auditGeometry(OutputDirectory=folder);
verifyTrue(testCase,isfile(audit.figure_file));
verifyTrue(testCase,isfile(audit.metadata_file));
verifyEqual(testCase,audit.realized_gap_m,0.0102125,AbsTol=1e-12);
verifyEqual(testCase,audit.analysis_bounds_m_xz, ...
    [0.0114,0.0494,0,0.0358625],AbsTol=1e-12);
clear cleanup
end

function files=config_files(root)
folder=fullfile(root,'configs','kwsim','two_d','benchmarks', ...
    'experimental_bilayer_400hz_source_polarization');
names=["source_z_homogeneous_soft_400hz.json"; ...
    "source_z_homogeneous_stiff_400hz.json"; ...
    "source_z_bilayer_soft_stiff_400hz.json"; ...
    "source_x_homogeneous_soft_400hz.json"; ...
    "source_x_homogeneous_stiff_400hz.json"; ...
    "source_x_bilayer_soft_stiff_400hz.json"];
files=fullfile(folder,names);
end
