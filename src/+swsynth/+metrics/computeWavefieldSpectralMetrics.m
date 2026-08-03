function metrics = computeWavefieldSpectralMetrics( ...
        fieldZX, dxM, dzM, options)
%COMPUTEWAVEFIELDSPECTRALMETRICS Compute global 2D spectral metrics.
%
% The analysis pipeline is fixed and reproducible:
%
%   complex mean removal
%   -> separable Hann window
%   -> centered 2D Fourier transform
%   -> angular and radial spectral entropy
%
% Public array orientation:
%
%   fieldZX(z,x)
%
% Usage:
%
%   metrics = swsynth.metrics.computeWavefieldSpectralMetrics( ...
%       U_zx, dx_m, dz_m);
%
% Options:
%
%   AngularBinCount   default 36
%   RadialBinCount    default 24
%   MinimumRadiusRadM default 0
%   MaximumRadiusRadM default Inf
%   HalfPlane         default "all"

arguments
    fieldZX (:,:) {mustBeNumeric, mustBeNonempty}
    dxM (1,1) double {mustBePositive, mustBeFinite}
    dzM (1,1) double {mustBePositive, mustBeFinite}
    options.AngularBinCount (1,1) double = 36
    options.RadialBinCount (1,1) double = 24
    options.MinimumRadiusRadM (1,1) double = 0
    options.MaximumRadiusRadM (1,1) double = Inf
    options.HalfPlane (1,1) string = "all"
end

if any(~isfinite(fieldZX), "all")
    error( ...
        "swsynth:InvalidWavefieldSpectralInput", ...
        "fieldZX must contain only finite values.");
end

if ~any(abs(fieldZX(:)) > 0)
    error( ...
        "swsynth:ZeroWavefieldSpectralInput", ...
        "fieldZX must contain nonzero wavefield energy.");
end

fieldZX = double(fieldZX);
fieldZX = fieldZX - mean(fieldZX(:));

[Nz, Nx] = size(fieldZX);

windowZ = localHann(Nz);
windowX = localHann(Nx);
windowZX = windowZ * windowX.';

windowedFieldZX = fieldZX .* windowZX;

spectrumZX = fftshift(fft2(windowedFieldZX));
powerSpectrumZX = abs(spectrumZX).^2;

kxRadM = centeredWavenumberAxis(Nx, dxM);
kzRadM = centeredWavenumberAxis(Nz, dzM);

entropyOptions = struct();
entropyOptions.AngularBinCount = options.AngularBinCount;
entropyOptions.RadialBinCount = options.RadialBinCount;
entropyOptions.MinimumRadiusRadM = options.MinimumRadiusRadM;
entropyOptions.MaximumRadiusRadM = options.MaximumRadiusRadM;
entropyOptions.HalfPlane = options.HalfPlane;

metrics = swsynth.metrics.computeSpectralEntropy( ...
    powerSpectrumZX, ...
    kxRadM, ...
    kzRadM, ...
    entropyOptions);

metrics.analysis = struct();
metrics.analysis.remove_mean = true;
metrics.analysis.window = "separable_hann";
metrics.analysis.fft = "fftshift_fft2";
metrics.analysis.power_definition = "abs(FFT).^2";
metrics.analysis.array_order = "zx";
metrics.analysis.dx_m = dxM;
metrics.analysis.dz_m = dzM;
metrics.analysis.Nx = Nx;
metrics.analysis.Nz = Nz;
metrics.analysis.angular_bin_count = options.AngularBinCount;
metrics.analysis.radial_bin_count = options.RadialBinCount;
metrics.analysis.minimum_radius_rad_m = options.MinimumRadiusRadM;
metrics.analysis.maximum_radius_rad_m = options.MaximumRadiusRadM;
metrics.analysis.half_plane = options.HalfPlane;

end


function window = localHann(sampleCount)

if sampleCount == 1
    window = 1;
    return
end

index = (0:sampleCount-1).';

window = ...
    0.5 - ...
    0.5*cos(2*pi*index/(sampleCount-1));

end


function axisRadM = centeredWavenumberAxis(sampleCount, spacingM)

indices = ...
    -floor(sampleCount/2):ceil(sampleCount/2)-1;

axisRadM = ...
    indices .* ...
    (2*pi/(sampleCount*spacingM));

end
