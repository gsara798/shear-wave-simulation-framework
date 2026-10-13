function tests=test_opposed_normal_disks_config
tests=functiontests(localfunctions);
end
function testResolveContactPair(tc)
cfg=kwsim.three_d.defaultConfig();
cfg.grid.Nx=96;cfg.grid.Ny=48;cfg.grid.Nz=88;
cfg.source.layout="vibrator_bank";
cfg.source.side="multiface";
cfg.source.bank_name="opposed_normal_disks";
cfg.source.vibrator_count=2;
cfg.source.contact_radius_m=0.003;
cfg.source.contact_node_spacing_points=3;
cfg.sensor.save_full_volume=false;
[c,~]=kwsim.three_d.validateConfig(cfg);
v=c.source.vibrators;
verifyEqual(tc,numel(v),2);
verifyEqual(tc,string({v.face}),["x_min","x_max"]);
verifyEqual(tc,v(1).phase_rad,v(2).phase_rad);
verifyEqual(tc,v(1).polarization_xyz,[1 0 0]);
verifyEqual(tc,v(2).polarization_xyz,[1 0 0]);
verifyEqual(tc,v(1).nominal_propagation_xyz,[1 0 0]);
verifyEqual(tc,v(2).nominal_propagation_xyz,[-1 0 0]);
verifyGreaterThan(tc,v(1).contact_node_count,2);
verifyEqual(tc,c.sensor.y_indices,c.sensor.acquisition_y_index_full);
end
