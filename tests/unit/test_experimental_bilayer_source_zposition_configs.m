function tests=test_experimental_bilayer_source_zposition_configs
tests=functiontests(localfunctions);
end

function setupOnce(~)
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(fullfile(root,'src'));
end

function testOnlyRequestedSourceZAndIdentityFieldsDiffer(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
base=kwsim.io.loadConfigJson(fullfile(root,'configs','kwsim','two_d','benchmarks', ...
    'experimental_bilayer_400hz_source_polarization','source_x_bilayer_soft_stiff_400hz.json'));
folder=fullfile(root,'configs','kwsim','two_d','benchmarks', ...
    'experimental_bilayer_400hz_source_zposition');
names=["source_x_bilayer_source_in_soft_400hz.json", ...
    "source_x_bilayer_source_in_stiff_400hz.json"];
for i=1:2
    candidate=kwsim.io.loadConfigJson(fullfile(folder,names(i)));
    verifyEqual(testCase,candidate.grid,base.grid);
    verifyEqual(testCase,candidate.medium,base.medium);
    verifyEqual(testCase,candidate.geometry,base.geometry);
    verifyEqual(testCase,candidate.time,base.time);
    verifyEqual(testCase,candidate.sensor,base.sensor);
    verifyEqual(testCase,candidate.solver,base.solver);
    verifyEqual(testCase,candidate.attenuation,base.attenuation);
    fixed={'layout','side','f0_hz','velocity_amplitude_m_s','contact_radius_m', ...
        'contact_model','contact_sampling','contact_profile', ...
        'contact_node_spacing_points','ramp_cycles','phase_rad','mode','polarization_xz'};
    for f=fixed, verifyEqual(testCase,candidate.source.(f{1}),base.source.(f{1})); end
    [resolved,preflight]=kwsim.two_d.validateConfig(candidate);
    verifyTrue(testCase,preflight.valid);
    verifyEqual(testCase,numel(resolved.source.contact_z_indices),2);
    verifyEqual(testCase,diff(resolved.source.contact_z_indices),7);
end
end

function testContactsAreWhollyInRequestedMaterials(testCase)
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
folder=fullfile(root,'configs','kwsim','two_d','benchmarks', ...
    'experimental_bilayer_400hz_source_zposition');
files=["source_x_bilayer_source_in_soft_400hz.json", ...
    "source_x_bilayer_source_in_stiff_400hz.json"];
expected=[1 2]; realized=[.01151875 .02648125];
for i=1:2
    cfg=kwsim.io.loadConfigJson(fullfile(folder,files(i)));
    [cfg,~]=kwsim.two_d.validateConfig(cfg);
    [maps,~]=kwsim.two_d.buildGeometry(cfg);
    ids=maps.material_id_xz( ...
        cfg.source.center_index_xz(1),cfg.source.contact_z_indices);
    verifyEqual(testCase,unique(ids),uint16(expected(i)));
    verifyEqual(testCase,cfg.source.center_m_xz(2),realized(i),AbsTol=1e-12);
end
end
