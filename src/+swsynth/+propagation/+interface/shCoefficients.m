function out=shCoefficients(request)
%SHCOEFFICIENTS Plane SH displacement coefficients at a welded interface.
% Incident plane shear wave propagates from material 1 to material 2;
% angle is relative to interface normal, in [0,pi/2).
%
% Tangential displacement u is continuous and tangential shear traction
% mu*partial_n(u) is continuous (isotropic, elastic half-spaces).
% Temporal/spatial convention: exp(i*(k.r-omega*t)).
% R and T are displacement AMPLITUDES, not energy coefficients.
% The transmitted field can be evanescent at supercritical incidence.
%
% Required fields: frequency_hz, incidence_angle_rad,
% mu1_pa, rho1_kg_m3, mu2_pa, rho2_kg_m3.
arguments
    request (1,1) struct
end
required=["frequency_hz","incidence_angle_rad", ...
    "mu1_pa","rho1_kg_m3","mu2_pa","rho2_kg_m3"];
if ~all(isfield(request,cellstr(required)))
    error("swsynth:SHInterfaceMissingParameter", ...
        "SH interface requires frequency, angle, both shear moduli and densities.");
end
v=zeros(1,numel(required));
for j=1:numel(required)
    a=request.(required(j));
    if ~isnumeric(a) || ~isscalar(a) || ~isreal(a) || ~isfinite(a)
        error("swsynth:SHInterfaceInvalidParameter", ...
            "Each SH interface input must be a finite real scalar.");
    end
    v(j)=double(a);
end
f=v(1);angle=v(2);mu1=v(3);rho1=v(4);mu2=v(5);rho2=v(6);
if f<=0 || angle<0 || angle>=pi/2 || ...
        any([mu1 rho1 mu2 rho2]<=0)
    error("swsynth:SHInterfaceInvalidParameter", ...
        "Frequency and material properties must be positive; angle in [0,pi/2).");
end
omega=2*pi*f;
c1=sqrt(mu1/rho1); c2=sqrt(mu2/rho2);
k1=omega/c1; k2=omega/c2;
kt=k1*sin(angle);
kn1=k1*cos(angle);
kn2=sqrt(complex(k2*k2-kt*kt,0));
Z1=mu1*kn1; Z2=mu2*kn2;
R=(Z1-Z2)/(Z1+Z2);
T=2*Z1/(Z1+Z2);
fluxR=abs(R)^2;
fluxT=real(Z2)/Z1*abs(T)^2;
out=struct( ...
    "model","elastic_welded_plane_SH", ...
    "frequency_hz",f,"incidence_angle_rad",angle, ...
    "phase_speed_1_m_s",c1,"phase_speed_2_m_s",c2, ...
    "wavenumber_tangential_rad_m",kt, ...
    "wavenumber_normal_1_rad_m",kn1, ...
    "wavenumber_normal_2_rad_m",kn2, ...
    "reflection_displacement",R, ...
    "transmission_displacement",T, ...
    "reflection_energy_fraction",fluxR, ...
    "transmission_energy_fraction",fluxT, ...
    "is_evanescent",abs(imag(kn2))>0, ...
    "traction_continuity_residual",Z1*(1-R)-Z2*T, ...
    "displacement_continuity_residual",1+R-T);
end
