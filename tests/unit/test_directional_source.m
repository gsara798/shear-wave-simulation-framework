function tests = test_directional_source
%TEST_DIRECTIONAL_SOURCE Verify ramp, polarization, and contact sampling.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));
kwsim.io.locateKWave();
end

function testSourceIsAxialRampedAndNonAdjacent(testCase)
cfg = kwsim.two_d.defaultConfig();
[cfg, ~] = kwsim.two_d.validateConfig(cfg);
[kgrid, cfg] = kwsim.two_d.buildGrid(cfg);
[source, metadata] = kwsim.two_d.buildSingleContactSource(cfg, kgrid);

verifyEqual(testCase, string(source.u_mode), "dirichlet");
verifyEqual(testCase, source.uy(1), single(0));
verifyEqual(testCase, metadata.polarization_xz, [0, 1]);
verifyGreaterThanOrEqual(testCase, ...
    metadata.contact_minimum_node_spacing_points, 2);

[~, z_index] = find(source.u_mask);
verifyGreaterThanOrEqual(testCase, min(diff(sort(z_index))), 2);
verifyFalse(testCase, any(contains(string(fieldnames(source)), "square")));
verifyFalse(testCase, isfield(source, 'ux'));
verifyEqual(testCase, fieldnames(source), {'u_mask';'uy';'u_mode'});
end

function testSourceXDiffersOnlyByPolarization(testCase)
requestedZ = kwsim.two_d.defaultConfig();
[cfgZ, ~] = kwsim.two_d.validateConfig(requestedZ);
[kgridZ, cfgZ] = kwsim.two_d.buildGrid(cfgZ);
[sourceZ, metadataZ] = kwsim.two_d.buildSingleContactSource(cfgZ, kgridZ);

requestedX = requestedZ;
requestedX.source.polarization_xz = [1, 0];
[cfgX, ~] = kwsim.two_d.validateConfig(requestedX);
[kgridX, cfgX] = kwsim.two_d.buildGrid(cfgX);
[sourceX, metadataX] = kwsim.two_d.buildSingleContactSource(cfgX, kgridX);
[sourceXRepeat, metadataXRepeat] = ...
    kwsim.two_d.buildSingleContactSource(cfgX, kgridX);

verifyEqual(testCase, sourceX.u_mask, sourceZ.u_mask);
verifyEqual(testCase, sourceX.ux, sourceZ.uy);
verifyFalse(testCase, isfield(sourceX, 'uy'));
verifyEqual(testCase, metadataX.waveform_m_s, metadataZ.waveform_m_s);
verifyEqual(testCase, metadataX.polarization_xz, [1, 0]);
verifyEqual(testCase, metadataZ.polarization_xz, [0, 1]);
verifyEqual(testCase, sourceXRepeat, sourceX);
verifyEqual(testCase, metadataXRepeat, metadataX);
end

function testExplicitAnalysisFovIsPhysicalAndOutsideSource(testCase)
cfg = kwsim.two_d.defaultConfig();
cfg.grid.Nx = 213; cfg.grid.Nz = 152;
cfg.grid.dx_m = 0.0002375; cfg.grid.dz_m = 0.0002375;
cfg.source.f0_hz = 400; cfg.source.contact_radius_m = 0.00095;
cfg.source.contact_node_spacing_points = 4;
cfg.grid.cfl = 0.30;
cfg.medium.cp_mode = "physical"; cfg.medium.physical_cp_m_s = 9.15;
cfg.sensor.source_buffer_m = 0.010;
cfg.sensor.analysis_bounds_m_xz = [0.0114,0.0494,0,0.0358625];
cfg.geometry.minimum_boundary_clearance_m = 0;
cfg.time.end_time_s = [];
[resolved, preflight] = kwsim.two_d.validateConfig(cfg);

verifyTrue(testCase, preflight.valid);
verifyEqual(testCase, numel(resolved.sensor.x_indices), 161);
verifyEqual(testCase, numel(resolved.sensor.z_indices), 152);
verifyEqual(testCase, resolved.derived.realized_analysis_bounds_m_xz, ...
    [0.0114,0.0494,0,0.0358625], AbsTol=1e-12);
verifyEqual(testCase, resolved.derived.source_contact_to_analysis_gap_m, ...
    0.0102125, AbsTol=1e-12);
verifyGreaterThanOrEqual(testCase, ...
    resolved.derived.source_contact_to_analysis_gap_m, ...
    resolved.sensor.source_buffer_m);
end

function testRequestedSourceZPreservesFiniteContactSampling(testCase)
baseline = kwsim.two_d.defaultConfig();
baseline.grid.Nx = 152; baseline.grid.Nz = 152;
baseline.grid.dx_m = 0.0002375; baseline.grid.dz_m = 0.0002375;
baseline.source.f0_hz = 400; baseline.source.contact_radius_m = 0.00095;
baseline.source.contact_node_spacing_points = 4;
baseline.diagnostics.maximum_sensor_memory_bytes = inf;
[centered, ~] = kwsim.two_d.validateConfig(baseline);

requested = baseline; requested.source.center_z_m = 0.0115;
[soft, ~] = kwsim.two_d.validateConfig(requested);
verifyEqual(testCase, soft.source.center_m_xz(2),0.01151875,AbsTol=1e-12);
verifyEqual(testCase,diff(soft.source.contact_z_indices), ...
    diff(centered.source.contact_z_indices));
verifyEqual(testCase,numel(soft.source.contact_z_indices), ...
    numel(centered.source.contact_z_indices));
verifyEqual(testCase,soft.source.contact_z_indices-soft.source.center_index_xz(2), ...
    centered.source.contact_z_indices-centered.source.center_index_xz(2));
end

function testSourceCanRequireStiffMaterial(testCase)
cfg = kwsim.two_d.defaultConfig();
cfg.grid.Nx=213; cfg.grid.Nz=152;
cfg.grid.dx_m=.0002375; cfg.grid.dz_m=.0002375;
cfg.source.f0_hz=400; cfg.source.contact_radius_m=.00095;
cfg.source.contact_node_spacing_points=4; cfg.source.center_z_m=.0265;
cfg.source.expected_material_id=2;
cfg.medium.cp_mode="physical"; cfg.medium.physical_cp_m_s=9.15;
cfg.grid.cfl=.3; cfg.geometry.minimum_boundary_clearance_m=0;
cfg.geometry.require_objects_inside_sensor_roi=false;
object=cfg.geometry.objects;
object(1)=struct('type',"rectangle",'name',"stiff", ...
    'center_m_xz',[NaN NaN],'radius_m',NaN, ...
    'bounds_m_xz',[0,.05035,.019,.0358625], ...
    'material_id',uint16(2),'cs_m_s',3.05,'rho_kg_m3',1000);
cfg.geometry.objects=object;
[resolved,preflight]=kwsim.two_d.validateConfig(cfg);
verifyTrue(testCase,preflight.valid);
verifyEqual(testCase,resolved.source.center_m_xz(2),.02648125,AbsTol=1e-12);
[maps,~]=kwsim.two_d.buildGeometry(resolved);
ids=maps.material_id_xz( ...
    resolved.source.center_index_xz(1),resolved.source.contact_z_indices);
verifyEqual(testCase,unique(ids),uint16(2));
end
