function out=dispersion(spec,frequency)
%DISPERSION Homogeneous isotropic shear constitutive law.
% Spatial convention exp(+i*k*r); positive imag(k) attenuates.
arguments
    spec (1,1) struct
    frequency (1,1) double {mustBePositive}
end
allowed=["model","density_kg_m3","mu_pa","eta_pa_s"];
if ~isempty(setdiff(string(fieldnames(spec)),allowed))
    error("swsynth:InvalidConstitutiveModel","Unsupported constitutive parameter.");
end
if ~isfield(spec,"model") || ~isfield(spec,"density_kg_m3") || ...
        ~isfield(spec,"mu_pa")
    error("swsynth:InvalidConstitutiveModel", ...
        "model, density_kg_m3 and mu_pa are required.");
end
model=string(spec.model);
rho=double(spec.density_kg_m3);
mu=double(spec.mu_pa);
if ~isscalar(model)||~ismember(model,["elastic","kelvin_voigt"]) || ...
        ~isscalar(rho)||~isfinite(rho)||rho<=0 || ...
        ~isscalar(mu)||~isfinite(mu)||mu<=0
    error("swsynth:InvalidConstitutiveModel","Invalid model, density or elastic modulus.");
end
eta=0;
if model=="kelvin_voigt"
    if ~isfield(spec,"eta_pa_s")
        error("swsynth:InvalidConstitutiveModel","Kelvin-Voigt requires eta_pa_s.");
    end
    eta=double(spec.eta_pa_s);
elseif isfield(spec,"eta_pa_s")
    error("swsynth:InvalidConstitutiveModel","Elastic model cannot set viscosity.");
end
if ~isscalar(eta)||~isfinite(eta)||eta<0
    error("swsynth:InvalidConstitutiveModel","eta_pa_s must be nonnegative.");
end
omega=2*pi*frequency;
G=complex(mu,omega*eta);
% Conjugate physical k for the existing +i*k*r spatial convention.
k=conj(omega*sqrt(rho./G));
out=struct("model",model,"complex_modulus_pa",G, ...
    "wavenumber_rad_m",k,"phase_speed_m_s",omega/real(k), ...
    "attenuation_np_m",imag(k),"density_kg_m3",rho);
end
