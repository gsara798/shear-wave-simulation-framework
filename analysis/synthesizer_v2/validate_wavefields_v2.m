function report = validate_wavefields_v2(options)
%VALIDATE_WAVEFIELDS_V2 Visual and quantitative audit of modular synthesis.
% Run from repository root:
%   addpath(fullfile(pwd,"src"),fullfile(pwd,"analysis","synthesizer_v2"));
%   report=validate_wavefields_v2();
%
% To run without graphics and files:
%   report=validate_wavefields_v2(struct("MakeFigures",false,"SaveResults",false));
%
% Three fixed scenarios: one plane wave; two coherent point forces with a
% destructive-symmetry point; 30 plane waves in a +/-80-degree angular cone
% with reproducible random source phases. The last case is PARTIALLY
% directionally distributed, not fully isotropic/diffuse.
arguments
    options (1,1) struct = struct()
end
makeFigures=true;
if isfield(options,"MakeFigures")
    makeFigures=logical(options.MakeFigures);
end
saveResults=true;
if isfield(options,"SaveResults")
    saveResults=logical(options.SaveResults);
end
outputDir=fullfile(pwd,"results","synthesizer_v2_validation");
if isfield(options,"OutputDir")
    outputDir=char(options.OutputDir);
end
if ~isscalar(makeFigures) || ~isscalar(saveResults)
    error("swsynth:InvalidValidationOptions", ...
        "MakeFigures and SaveResults must be scalars.");
end
if makeFigures || saveResults
    if ~exist(outputDir,"dir")
        mkdir(outputDir);
    end
end

base=baseScenario();
single=base;
single.propagation=struct("model","plane_wave", ...
    "phase_method","analytical","normalization","none");
single.incidence=struct("direction_xyz",[1 0 0], ...
    "relative_amplitude",1,"phase_rad",0, ...
    "polarization",struct("policy","in_plane_sv"));

two=base;
two.geometry="projected3d";
two.propagation=struct("model","spherical_wave", ...
    "phase_method","analytical", ...
    "normalization","none", ...
    "geometric_decay_exponent",0);
two.sources=struct("count",2);
% Symmetric around x=12 mm at z=12 mm; equal opposite initial phases.
% Force is axial and transverse to both radial directions at that point,
% so the two axial phasors cancel (within floating-point accuracy).
two.sources.positions=struct("method","explicit", ...
    "position_xyz_m",[-.012 0 .012;.036 0 .012]);
two.sources.excitation=struct( ...
    "force_direction_xyz",[0 0 1;0 0 1], ...
    "relative_amplitude",[1;1],"phase_rad",[0;pi]);

partial=single;
n=30;
theta=deg2rad(linspace(-80,80,n)).';
phaseStream=RandStream("mt19937ar","Seed",53053);
randomPhases=2*pi*rand(phaseStream,n,1);
partial.incidence.direction_xyz=[cos(theta),zeros(n,1),sin(theta)];
partial.incidence.relative_amplitude=ones(n,1);
partial.incidence.phase_rad=randomPhases;
partial.propagation.normalization="sqrt_count";

scenarios={single,two,partial};
names=["directional_plane","two_coherent_point_forces", ...
    "partial_angular_ensemble"];
cases=cell(3,1);
for i=1:3
    r=swsynth.propagation.synthesize(scenarios{i});
    axial=swsynth.observation.projectComponent(r.U_xyz,[0 0 1]);
    m=swsynth.diagnostics.analyzeSpectrum2D( ...
        axial,r.domain.x_m,r.domain.z_m, ...
        r.excitation.frequency_hz,r.medium.background_cs_m_s);
    cases{i}=struct("name",names(i),"scenario",scenarios{i}, ...
        "result",r,"Uz",axial,"metrics",m);
    if makeFigures
        drawCase(cases{i},outputDir);
    end
end

% The two-source center is at x=z=12 mm; symmetry gives cancellation.
ix=find(abs(two.domain.x_m-.012)<1e-12,1);
iz=find(abs(two.domain.z_m-.012)<1e-12,1);
if isempty(ix) || isempty(iz)
    error("swsynth:ValidationMissingSymmetryPoint", ...
        "The diagnostic grid must contain (x,z)=(12,12) mm.");
end
cancellationAbs=abs(cases{2}.Uz(iz,ix));
cancellationRelative=cancellationAbs / cases{2}.metrics.axial_rms;
report=struct();
report.schema_version="1.0";
report.description="Harmonic V2 synthesizer: one directional, two coherent physical sources, partially angular ensemble";
report.shared_frequency_hz=base.excitation.frequency_hz;
report.reference_cs_m_s=base.medium.cs_m_s;
report.expected_wavelength_m=base.medium.cs_m_s/base.excitation.frequency_hz;
report.phase_sign=1;
report.random_phase_seed=53053;
report.cases=cases;
report.two_source_center_cancellation_amplitude=cancellationAbs;
report.two_source_center_cancellation_relative_rms=cancellationRelative;
report.directional_peak_relative_error=cases{1}.metrics.peak_relative_error;
report.directional_angular_resultant=cases{1}.metrics.angular_resultant;
report.partial_angular_resultant=cases{3}.metrics.angular_resultant;
report.partial_incidence_half_angle_deg=80;
report.partial_incidence_count=n;
report.summary=table(names(:), ...
    cellfun(@(c)c.metrics.peak_wavenumber_rad_m,cases), ...
    cellfun(@(c)c.metrics.peak_relative_error,cases), ...
    cellfun(@(c)c.metrics.annular_energy_fraction,cases), ...
    cellfun(@(c)c.metrics.angular_resultant,cases), ...
    cellfun(@(c)c.metrics.axial_rms,cases), ...
    'VariableNames',{'Scenario','PeakK_rad_m','PeakRelativeError', ...
    'AnnularEnergyFraction','AngularResultant','AxialRMS'});
disp(report.summary);
fprintf("Expected: cs=%.3f m/s, f=%.1f Hz, lambda=%.3f mm, k=%.2f rad/m\n", ...
    report.reference_cs_m_s,report.shared_frequency_hz, ...
    1000*report.expected_wavelength_m, ...
    cases{1}.metrics.expected_wavenumber_rad_m);
fprintf("Two-source cancellation at 12 mm: |Uz|=%.4g (relative to RMS %.4g)\n", ...
    cancellationAbs,cancellationRelative);

if saveResults
    save(fullfile(outputDir,"validation_report.mat"),"report","-v7.3");
    writetable(report.summary,fullfile(outputDir,"metrics_summary.csv"));
end
end

function scenario=baseScenario()
scenario=struct();
scenario.geometry="2d";
scenario.domain=struct("x_m",(0:119)*.0002, ...
    "z_m",(0:119)*.0002,"observation_y_m",0);
scenario.medium=struct("cs_m_s",2);
scenario.excitation=struct("frequency_hz",500, ...
    "quantity","relative_motion");
end

function drawCase(testCase,outputDir)
m=testCase.metrics;
r=testCase.result;
zMM=r.domain.z_m*1000;
xMM=r.domain.x_m*1000;
fig=figure("Visible","off","Color","w", ...
    "Position",[80 80 1200 830]);
try
    tiledlayout(fig,2,2,"Padding","compact","TileSpacing","compact");
    nexttile;
    imagesc(xMM,zMM,real(testCase.Uz));
    axis image xy;
    xlabel("x [mm]");ylabel("z [mm]");
    title("Re{U_z} — spatial phasor");
    colorbar;

    nexttile;
    imagesc(xMM,zMM,abs(testCase.Uz));
    axis image xy;
    xlabel("x [mm]");ylabel("z [mm]");
    title("|U_z|");
    colorbar;

    nexttile;
    imagesc(m.kx_rad_m/1000,m.kz_rad_m/1000, ...
        10*log10(m.power_spectrum/max(m.power_spectrum(:))+eps));
    axis image xy;
    kmax=2.5*m.expected_wavenumber_rad_m/1000;
    xlim([-kmax kmax]);ylim([-kmax kmax]);
    xlabel("k_x [rad/mm]");ylabel("k_z [rad/mm]");
    title("Complex 2D FFT power [dB from peak]");
    colorbar;
    hold on;
    phi=linspace(0,2*pi,361);
    plot(m.expected_wavenumber_rad_m/1000*cos(phi), ...
         m.expected_wavenumber_rad_m/1000*sin(phi), ...
         "w--","LineWidth",.8);
    hold off;

    nexttile;
    plot(m.radial_bin_centers_rad_m/1000, ...
        m.radial_energy_fraction,"LineWidth",1.8);
    hold on;
    xline(m.expected_wavenumber_rad_m/1000,"--");
    hold off;
    xlabel("k_r [rad/mm]");
    ylabel("Fraction of total spectral energy per bin");
    title(sprintf("Annulus=%.3f | Angular resultant=%.3f", ...
        m.annular_energy_fraction,m.angular_resultant));
    grid on;

    sgtitle(strrep(char(testCase.name),"_"," "),"Interpreter","none");
    exportgraphics(fig,fullfile(outputDir,string(testCase.name)+".png"), ...
        "Resolution",200);
catch err
    close(fig);
    rethrow(err);
end
close(fig);
end
