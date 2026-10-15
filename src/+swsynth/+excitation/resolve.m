function drive = resolve(request)
%RESOLVE One shared monochromatic harmonic drive for a coherent phasor.
% Source excitation owns relative amplitudes/phases/force, NOT frequency.
% Distinct frequencies require independent synthesis, not phasor addition.
arguments
    request (1,1) struct
end
allowed=["frequency_hz","type","quantity"];
unknown=setdiff(string(fieldnames(request)),allowed);
if ~isempty(unknown)
    error("swsynth:UnsupportedHarmonicDriveField", ...
        "Unsupported harmonic drive field %s.",unknown(1));
end
if ~isfield(request,"frequency_hz")
    error("swsynth:HarmonicDriveMissingFrequency", ...
        "excitation.frequency_hz is required.");
end
f=request.frequency_hz;
if ~isnumeric(f) || ~isscalar(f) || ~isreal(f) || ...
        ~isfinite(f) || f<=0
    error("swsynth:InvalidHarmonicFrequency", ...
        "frequency_hz must be a positive finite real scalar.");
end
type="harmonic";
if isfield(request,"type")
    type=string(request.type);
end
if ~isscalar(type) || type~="harmonic"
    error("swsynth:UnsupportedHarmonicDrive", ...
        "V2 supports a single harmonic frequency per complex phasor.");
end
quantity="relative_motion";
if isfield(request,"quantity")
    quantity=string(request.quantity);
end
if ~isscalar(quantity) || ...
        ~ismember(quantity,["relative_motion","displacement","velocity"])
    error("swsynth:InvalidHarmonicQuantity", ...
        "quantity must be relative_motion, displacement or velocity.");
end
drive=struct();
drive.type="harmonic";
drive.frequency_hz=double(f);
drive.omega_rad_s=2*pi*double(f);
drive.period_s=1/double(f);
drive.quantity=quantity;
drive.spatial_phase_sign=1;
drive.phasor_convention="spatial exp(+i*(omega*T+phi)); temporal synthesis not defined";
end
