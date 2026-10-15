function metrics = analyzeSpectrum2D(Uzx, xM, zM, frequencyHz, referenceCsMps)
%ANALYZESPECTRUM2D Radial/angular power spectrum of a 2D complex phasor.
% Uzx must be the observed scalar motion [Nz,Nx], not the xyz vector field.
% Coordinates must be uniform and increasing. No window, padding or radial
% smoothing is applied: peak estimates are quantized by the finite FOV.
arguments
    Uzx {mustBeNumeric}
    xM {mustBeNumeric,mustBeReal}
    zM {mustBeNumeric,mustBeReal}
    frequencyHz (1,1) double {mustBePositive,mustBeFinite}
    referenceCsMps (1,1) double {mustBePositive,mustBeFinite}
end
x=validateAxis(xM,"x_m");
z=validateAxis(zM,"z_m");
nz=numel(z);nx=numel(x);
if ~isequal(size(Uzx),[nz nx]) || ...
        any(~isfinite(Uzx(:)))
    error("swsynth:InvalidValidationField", ...
        "U_zx must be a finite numeric [Nz,Nx] phasor.");
end
dx=mean(diff(x));dz=mean(diff(z));
kx=2*pi*(-floor(nx/2):ceil(nx/2)-1)/(nx*dx);
kz=2*pi*(-floor(nz/2):ceil(nz/2)-1)/(nz*dz);
[KX,KZ]=meshgrid(kx,kz);
kr=hypot(KX,KZ);
angleK=atan2(KZ,KX);
P=abs(fftshift(fft2(double(Uzx)))).^2;
total=sum(P(:));
if total<=0
    error("swsynth:ZeroValidationSpectrum", ...
        "Spectral diagnostics require nonzero observed motion.");
end
kExpected=2*pi*frequencyHz/referenceCsMps;
% Exclude DC and select power on the expected shear-wave annulus.
ring=kr>=0.8*kExpected & kr<=1.2*kExpected;
if ~any(ring(:)) || sum(P(ring))<=0
    error("swsynth:EmptyValidationAnnulus", ...
        "No sampled spectrum in the expected wave-number annulus.");
end
annularP=P(ring);
annularTheta=angleK(ring);
angularResultant=abs(sum(annularP.*exp(1i*annularTheta))) / ...
    sum(annularP);
[~,localPeak]=max(annularP);
sampledKr=kr(ring);
peakK=sampledKr(localPeak);

% Energy in radial bins. This is BIN ENERGY, not spectral density: no
% division by annular area, a distinction that matters for REQ theory.
radialEdges=linspace(0,2.5*kExpected,81);
radialCenters=(radialEdges(1:end-1)+radialEdges(2:end))/2;
bin=discretize(kr(:),radialEdges);
valid=~isnan(bin);
radialEnergy=accumarray(bin(valid),P(valid), ...
    [numel(radialCenters),1],@sum,0);
radialEnergy=radialEnergy/sum(P(:));
metrics=struct();
metrics.frequency_hz=frequencyHz;
metrics.reference_cs_m_s=referenceCsMps;
metrics.expected_wavenumber_rad_m=kExpected;
metrics.expected_wavelength_m=referenceCsMps/frequencyHz;
metrics.peak_wavenumber_rad_m=peakK;
metrics.peak_relative_error=abs(peakK-kExpected)/kExpected;
metrics.sws_from_peak_m_s=2*pi*frequencyHz/peakK;
metrics.annular_energy_fraction=sum(annularP)/total;
metrics.angular_resultant=angularResultant;
metrics.axial_rms=sqrt(mean(abs(Uzx(:)).^2));
metrics.axial_peak_amplitude=max(abs(Uzx(:)));
metrics.kx_rad_m=kx;
metrics.kz_rad_m=kz;
metrics.power_spectrum=P/total;
metrics.radial_bin_centers_rad_m=radialCenters;
metrics.radial_energy_fraction=radialEnergy;
metrics.spatial_size=[nz nx];
metrics.notes="Complex spatial phasor spectrum, unwindowed. Radial values are bin energies, not density. Angular resultant depends on the measured component and FOV.";
end

function v=validateAxis(value,name)
if ~isvector(value) || numel(value)<2 || ...
        any(~isfinite(value(:))) || ~isreal(value)
    error("swsynth:InvalidValidationGrid", ...
        "%s must contain at least two finite real values.",name);
end
v=double(value(:).');
increments=diff(v);
if any(increments<=0)
    error("swsynth:InvalidValidationGrid", ...
        "%s must increase strictly.",name);
end
meanSpacing=mean(increments);
if any(abs(increments-meanSpacing)>1e-10*max(1,abs(meanSpacing)))
    error("swsynth:InvalidValidationGrid", ...
        "%s must be uniformly spaced.",name);
end
end
