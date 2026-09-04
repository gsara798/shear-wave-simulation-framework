%% Quick diagnostic: circular inclusion, directional vs diffuse projected-3D
clear;
close all;

repoRoot = "/Users/sara/local/shear-wave-simulation-framework";
addpath(fullfile(repoRoot, "src"));

outputDirectory = fullfile( ...
    repoRoot, ...
    "outputs", ...
    "diagnostics", ...
    "projected3d_inclusion_directional_vs_diffuse");

if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

%% Shared physical setup

backgroundCsMps = 2.0;
inclusionCsMps = 3.5;
frequencyHz = 250;

cfgDirectional = buildConfig(1, 1, 5101);
cfgDiffuse     = buildConfig(128, 8, 5102);

resultDirectional = swsynth.run(cfgDirectional);
resultDiffuse     = swsynth.run(cfgDiffuse);

xM = 0:cfgDirectional.domain.dx_m:cfgDirectional.domain.Lx_m;
zM = (0:cfgDirectional.domain.dz_m:cfgDirectional.domain.Lz_m).';

[X, Z] = meshgrid(xM, zM);

csMapZX = backgroundCsMps * ones(size(X));
distanceFromCenterM = hypot(X - 0.025, Z - 0.025);
csMapZX(distanceFromCenterM <= 0.010) = inclusionCsMps;

Udir = resultDirectional.wavefield.U_zx;
Udiff = resultDiffuse.wavefield.U_zx;

%% Patch away from the inclusion, in the left background
patchSize = 64;
patchCenterXM = 0.010;
patchCenterZM = 0.025;

[patchDir, patchRect] = extractPatch( ...
    Udir, xM, zM, patchCenterXM, patchCenterZM, patchSize, patchSize);

[patchDiff, ~] = extractPatch( ...
    Udiff, xM, zM, patchCenterXM, patchCenterZM, patchSize, patchSize);

k0RadM = 2*pi*frequencyHz/backgroundCsMps;

[kxDirNorm, kzDirNorm, Pdir] = computeSpectrum( ...
    patchDir, cfgDirectional.domain.dx_m, cfgDirectional.domain.dz_m, k0RadM);

[kxDiffNorm, kzDiffNorm, Pdiff] = computeSpectrum( ...
    patchDiff, cfgDiffuse.domain.dx_m, cfgDiffuse.domain.dz_m, k0RadM);

[kxFullNorm, kzFullNorm, PfullDiff] = computeSpectrum( ...
    Udiff, cfgDiffuse.domain.dx_m, cfgDiffuse.domain.dz_m, k0RadM);

%% Figure

figureHandle = figure( ...
    "Color", "w", ...
    "Position", [80 80 1500 850]);

tiledlayout(2,3, "Padding", "compact", "TileSpacing", "compact");

% 1) cs map
nexttile;
imagesc(xM*1e3, zM*1e3, csMapZX);
axis image;
set(gca, "YDir", "normal");
xlabel("x (mm)");
ylabel("z (mm)");
title("Shear-wave speed c_s (m/s)");
colorbar;

% 2) directional field
nexttile;
imagesc(xM*1e3, zM*1e3, real(Udir));
axis image;
set(gca, "YDir", "normal");
xlabel("x (mm)");
ylabel("z (mm)");
title("Directional field: Real(U_z), N=1");
hold on;
rectangle( ...
    "Position", patchRect*1e3, ...
    "EdgeColor", "w", ...
    "LineWidth", 1.5, ...
    "LineStyle", "-");
plot(25,25,"wo","MarkerSize",6,"LineWidth",1.2);
hold off;
colorbar;

% 3) directional patch spectrum
nexttile;
imagesc(kxDirNorm, kzDirNorm, Pdir);
axis image;
set(gca, "YDir", "normal");
xlabel("k_x / k_0");
ylabel("k_z / k_0");
title("Directional patch spectrum");
hold on;
plot(cos(linspace(0,2*pi,400)), sin(linspace(0,2*pi,400)), "w--", "LineWidth", 1.5);
hold off;
colorbar;

% 4) diffuse field
nexttile;
imagesc(xM*1e3, zM*1e3, real(Udiff));
axis image;
set(gca, "YDir", "normal");
xlabel("x (mm)");
ylabel("z (mm)");
title("Diffuse field: Real(U_z), N=128");
hold on;
rectangle( ...
    "Position", patchRect*1e3, ...
    "EdgeColor", "w", ...
    "LineWidth", 1.5, ...
    "LineStyle", "-");
plot(25,25,"wo","MarkerSize",6,"LineWidth",1.2);
hold off;
colorbar;

% 5) diffuse patch spectrum
nexttile;
imagesc(kxDiffNorm, kzDiffNorm, Pdiff);
axis image;
set(gca, "YDir", "normal");
xlabel("k_x / k_0");
ylabel("k_z / k_0");
title("Diffuse patch spectrum");
hold on;
plot(cos(linspace(0,2*pi,400)), sin(linspace(0,2*pi,400)), "w--", "LineWidth", 1.5);
hold off;
colorbar;

% 6) diffuse full-field spectrum
nexttile;
imagesc(kxFullNorm, kzFullNorm, PfullDiff);
axis image;
set(gca, "YDir", "normal");
xlabel("k_x / k_0");
ylabel("k_z / k_0");
title("Diffuse full-field spectrum");
hold on;
plot(cos(linspace(0,2*pi,400)), sin(linspace(0,2*pi,400)), "w--", "LineWidth", 1.5);
hold off;
colorbar;

sgtitle(sprintf( ...
    "Projected-3D circular inclusion | directional vs diffuse | f=%d Hz | c_b=%.1f m/s | c_i=%.1f m/s", ...
    frequencyHz, backgroundCsMps, inclusionCsMps), ...
    "FontWeight", "bold");

figurePath = fullfile( ...
    outputDirectory, ...
    "projected3d_inclusion_directional_vs_diffuse.png");

exportgraphics(figureHandle, figurePath, "Resolution", 180);
close(figureHandle);

fprintf("Saved figure: %s\n", figurePath);

%% ---------------- local functions ----------------

function cfg = buildConfig(directionCount, inPlaneCount, seedValue)

cfg = swsynth.defaultConfig();

cfg.scenario = sprintf( ...
    "projected3d_inclusion_n%d", ...
    directionCount);

cfg.seed = seedValue;

cfg.domain.Lx_m = 0.05;
cfg.domain.Lz_m = 0.05;
cfg.domain.dx_m = 0.00025;
cfg.domain.dz_m = 0.00025;
cfg.domain.observation_y_m = 0.0;

cfg.medium.background_cs_m_s = 2.0;
cfg.medium.combine_mode = "overlay";
cfg.medium.objects = { ...
    struct( ...
        "type", "circle", ...
        "cs_m_s", 3.5, ...
        "center_xz_m", [0.025, 0.025], ...
        "radius_m", 0.010, ...
        "edge_sigma_m", 0.0) ...
};

cfg.wavefield.frequency_hz = 250;
cfg.wavefield.observed_component = "axial";

cfg.propagation.model = "projected3d_eikonal";
cfg.propagation.nonpropagating_policy = "filter";

cfg.directions.count = directionCount;
cfg.directions.space = "three_dimensional";
cfg.directions.sampling_method = "fibonacci";
cfg.directions.require_in_plane = false;
cfg.directions.in_plane_count = inPlaneCount;

cfg.directions.support.type = "solid_angle_cap";
cfg.directions.support.axis_xyz = [1, 0, 0];
cfg.directions.support.solid_angle_sr = 4*pi;

cfg.sources.radius_range_m = [];
cfg.sources.phase_policy = "random_uniform";
cfg.sources.amplitude_jitter_fraction = 0.05;

cfg.polarization.model = "transverse_random";

cfg.amplitude.geometric_decay_exponent = 0.0;

cfg.noise.snr_db = 1000;

cfg.execution.use_parallel = true;

end

function [patch, rectXMm] = extractPatch(U, xM, zM, centerXM, centerZM, nx, nz)

[~, ixCenter] = min(abs(xM - centerXM));
[~, izCenter] = min(abs(zM - centerZM));

ix1 = ixCenter - floor(nx/2);
ix2 = ix1 + nx - 1;

iz1 = izCenter - floor(nz/2);
iz2 = iz1 + nz - 1;

ix1 = max(ix1,1);
iz1 = max(iz1,1);
ix2 = min(ix2,numel(xM));
iz2 = min(iz2,numel(zM));

patch = U(iz1:iz2, ix1:ix2);

rectXMm = [ ...
    xM(ix1), ...
    zM(iz1), ...
    xM(ix2)-xM(ix1), ...
    zM(iz2)-zM(iz1)];

end

function [kxNorm, kzNorm, Pnorm] = computeSpectrum(U, dxM, dzM, k0RadM)

U = U - mean(U(:));

[nz, nx] = size(U);

wx = hann(nx).';
wz = hann(nz);
window2D = wz * wx;

padFactor = 4;
nxPad = padFactor * nx;
nzPad = padFactor * nz;

F = fftshift(fft2(U .* window2D, nzPad, nxPad));
P = abs(F).^2;
Pnorm = P ./ max(P(:) + eps);

kx = 2*pi * ((-floor(nxPad/2)):(ceil(nxPad/2)-1)) / (nxPad*dxM);
kz = 2*pi * ((-floor(nzPad/2)):(ceil(nzPad/2)-1)) / (nzPad*dzM);

kxNorm = kx / k0RadM;
kzNorm = kz / k0RadM;

end
