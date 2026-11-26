function tests = test_3d_face_normal_excitation
tests = functiontests(localfunctions);
end

function testGeometryDriveAndPhaseAreInvariant(testCase)
[cfg,specs] = fixture();
axial = kwsim.three_d.resolveVibratorBankFromFaceSpecs(cfg,specs);
cfg.source.polarization_policy = "face_normal";
normal = kwsim.three_d.resolveVibratorBankFromFaceSpecs(cfg,specs);
verifyEqual(testCase,normal.union_mask_xyz,axial.union_mask_xyz);
verifyEqual(testCase,rmfield(normal.vibrators,"polarization_xyz"), ...
    rmfield(axial.vibrators,"polarization_xyz"));
verifyEqual(testCase,normal.nominal_total_drive_rms_squared_m2_s2, ...
    axial.nominal_total_drive_rms_squared_m2_s2);
for j=1:numel(specs)
    v=normal.vibrators(j);
    verifyEqual(testCase,v.polarization_xyz,-v.face_normal_xyz);
    verifyGreaterThan(testCase,dot(v.polarization_xyz,v.nominal_propagation_xyz),0);
    a=axial.vibrators(j);
    verifyEqual(testCase,dot(a.polarization_xyz,a.nominal_propagation_xyz),0,"AbsTol",1e-12);
end
cfg.source.phase_policy="all_zero";
zero=kwsim.three_d.resolveVibratorBankFromFaceSpecs(cfg,specs);
verifyEqual(testCase,[zero.vibrators.phase_rad],zeros(1,numel(specs)));
verifyEqual(testCase,rmfield(zero.vibrators,"phase_rad"),rmfield(normal.vibrators,"phase_rad"));
end

function testPrescribedVelocityAndStrictValidation(testCase)
[cfg,specs]=fixture();
cfg.source.polarization_policy="face_normal";
bank=kwsim.three_d.resolveVibratorBankFromFaceSpecs(cfg,specs);
cfg.source.vibrators=bank.vibrators;
% No k-Wave dependency: source builder only needs this time-array contract.
t=(0:12)/cfg.source.f0_hz/4;
kgrid=struct("t_array",t);
[source,meta]=kwsim.three_d.buildVibratorBankSource(cfg,kgrid);
verifyEqual(testCase,source.u_mask,bank.union_mask_xyz);
verifyEqual(testCase,meta.polarization_policy,"face_normal");
verifyEqual(testCase,meta.nominal_total_drive_rms_squared_m2_s2, ...
    bank.nominal_total_drive_rms_squared_m2_s2,"RelTol",1e-12);
for j=1:numel(specs)
    v=bank.vibrators(j);
    rows=meta.owner_vibrator_index_by_source_row==j;
    signal=v.velocity_amplitude_m_s*meta.envelope.*sin(2*pi*cfg.source.f0_hz*t+v.phase_rad);
    components={source.ux,source.uy,source.uz};
    for c=1:3
        expected=repmat(single(v.polarization_xyz(c)*signal),nnz(rows),1);
        verifyEqual(testCase,components{c}(rows,:),expected,"AbsTol",single(1e-9));
    end
end
bad=cfg; bad.source.vibrators(1).polarization_xyz=bank.vibrators(1).face_normal_xyz;
verifyError(testCase,@() kwsim.three_d.buildVibratorBankSource(bad,kgrid),"kwsim:InvalidFaceNormalDrive");
bad=cfg; bad.source.polarization_policy="project_axial_transverse";
verifyError(testCase,@() kwsim.three_d.buildVibratorBankSource(bad,kgrid),"kwsim:NonTransverseVibrator");
bad=cfg; bad.source.polarization_policy="unknown";
verifyError(testCase,@() kwsim.three_d.resolveVibratorBankFromFaceSpecs(bad,specs),"kwsim:Invalid3DSourceBank");
verifyError(testCase,@() kwsim.three_d.buildVibratorBankSource(bad,kgrid),"kwsim:Invalid3DSourceBank");
end

function [cfg,specs]=fixture()
cfg=kwsim.three_d.defaultConfig();
cfg.grid.Nx=52; cfg.grid.Ny=46; cfg.grid.Nz=50;
cfg.grid.dx_m=.4e-3; cfg.grid.dy_m=.5e-3; cfg.grid.dz_m=.6e-3;
cfg.source.boundary_margin_m=4e-3;
cfg.source.contact_radius_m=1.2e-3;
cfg.source.contact_node_spacing_points=2;
faces=["x_min","x_max","y_min","y_max","z_min","z_max"];
specs=repmat(struct("face","","center_fraction_tangent",[.3 .6]),numel(faces),1);
for j=1:numel(faces), specs(j).face=faces(j); end
cfg.source.vibrator_count=numel(specs);
cfg.source.phase_policy="random_uniform";
cfg.source.amplitude_policy="equal_total_rms";
cfg.source.polarization_policy="project_axial_transverse";
end
