function tests=test_swsynth_synthesis_physics_v2
tests=functiontests(localfunctions);
end

function setupOnce(testCase)
repo=fileparts(fileparts(fileparts(mfilename("fullpath"))));
folder=fullfile(repo,"tests","helpers");
addpath(folder);
testCase.addTeardown(@() rmpath(folder));
end

function testDirectionalSpectrumHasCorrectPhysicalWavenumber(testCase)
report=runAudit();
m=report.cases{1}.metrics;
expectedK=2*pi*500/2;
verifyEqual(testCase,report.expected_wavelength_m,.004, ...
    "AbsTol",1e-15);
verifyEqual(testCase,m.expected_wavenumber_rad_m,expectedK, ...
    "AbsTol",1e-12);
% Spatial grid: 120 points separated by 0.2 mm, so a 4-mm
% plane wave falls exactly on a Fourier bin (six cycles).
verifyLessThan(testCase,m.peak_relative_error,1e-12);
verifyGreaterThan(testCase,m.annular_energy_fraction,.999);
verifyGreaterThan(testCase,m.angular_resultant,.999);
verifyEqual(testCase,m.sws_from_peak_m_s,2, ...
    "AbsTol",1e-12);
end

function testPlaneWaveVectorAndPhaseGradient(testCase)
report=runAudit();
a=report.cases{1};
U=a.result.U_xyz;
x=a.result.domain.x_m;
k=2*pi*500/2;
expected=-exp(1i*k*x);
verifyEqual(testCase,a.Uz,repmat(expected,numel(x),1), ...
    "AbsTol",1e-13);
verifyEqual(testCase,U(:,:,1),zeros(numel(x)), ...
    "AbsTol",1e-13);
% Neighboring phasor ratios recover the expected spatial phase gradient.
dtheta=angle(a.Uz(:,2:end).*conj(a.Uz(:,1:end-1)));
verifyEqual(testCase,dtheta,k*diff(x).*ones(numel(x),1), ...
    "AbsTol",1e-12);
end

function testTwoPointForcesInterfereDestructivelyAtSymmetryPoint(testCase)
report=runAudit();
a=report.cases{2};
m=a.metrics;
verifyEqual(testCase,a.result.field.component_count,2);
verifyEqual(testCase,a.result.geometry,"projected3d");
verifyLessThan(testCase, ...
    report.two_source_center_cancellation_amplitude,1e-12);
verifyLessThan(testCase, ...
    report.two_source_center_cancellation_relative_rms,1e-12);
verifyGreaterThan(testCase,m.axial_rms,0.01);
end

function testAngularEnsembleBroadensMeasuredSpectrum(testCase)
report=runAudit();
plane=report.cases{1}.metrics;
partial=report.cases{3}.metrics;
verifyEqual(testCase,report.random_phase_seed,53053);
verifyEqual(testCase,report.partial_incidence_count,30);
verifyEqual(testCase,report.partial_incidence_half_angle_deg,80);
verifyGreaterThan(testCase,partial.annular_energy_fraction,.65);
verifyGreaterThan(testCase,partial.axial_rms,.05);
verifyLessThan(testCase,partial.angular_resultant, ...
    plane.angular_resultant-0.05);
verifyGreaterThan(testCase,partial.angular_resultant,.3);
end

function testDiagnosticsPreserveSpectralEnergy(testCase)
report=runAudit();
for i=1:numel(report.cases)
    m=report.cases{i}.metrics;
    verifyEqual(testCase,sum(m.power_spectrum(:)),1, ...
        "AbsTol",1e-12);
    verifyLessThanOrEqual(testCase,sum(m.radial_energy_fraction), ...
        1+1e-12);
    verifyGreaterThanOrEqual(testCase,m.angular_resultant,0);
    verifyLessThanOrEqual(testCase,m.angular_resultant,1+1e-12);
end
end

function testLocalSeedLeavesGlobalRngUntouched(testCase)
before=rng;
report1=runAudit();
verifyEqual(testCase,rng,before);
report2=runAudit();
verifyEqual(testCase,rng,before);
verifyEqual(testCase,report1.cases{3}.Uz, ...
    report2.cases{3}.Uz);
verifyEqual(testCase,report1.cases{2}.Uz, ...
    report2.cases{2}.Uz);
end

function testRejectMismatchedFieldShape(testCase)
verifyError(testCase,@() swsynth.diagnostics.analyzeSpectrum2D( ...
    ones(3,4),[0 .001 .002],[0 .001 .002],500,2), ...
    "swsynth:InvalidValidationField");
end

function testRejectInvalidSpectralGrid(testCase)
verifyError(testCase,@() swsynth.diagnostics.analyzeSpectrum2D( ...
    ones(2,3),[0 .001 .0015],[0 .001],500,2), ...
    "swsynth:InvalidValidationGrid");
end

function testRejectZeroMeasuredSpectrum(testCase)
verifyError(testCase,@() swsynth.diagnostics.analyzeSpectrum2D( ...
    complex(zeros(6,6)),(0:5)*.0002,(0:5)*.0002,500,2), ...
    "swsynth:ZeroValidationSpectrum");
end

function report=runAudit()
report=validate_wavefields_v2( ...
    struct("MakeFigures",false,"SaveResults",false));
end
