function out=shViscoelasticCoefficients(request)
%SHVISCOELASTICCOEFFICIENTS Welded planar SH Kelvin-Voigt interface.
% Convention exp(i*(k.r-omega*t)); G*=mu+i*omega*eta and Im(k)>=0.
% A complex tangential wavenumber kt=k1*sin(theta) is conserved: theta is
% the real launch angle of a homogeneous complex incident plane wave.
% Boundary equations are 1+R=T and G1*kn1*(1-R)=G2*kn2*T.
% Incident and transmitted wave amplitudes are referenced at the plane.
% No energy conservation fractions are exposed for absorbing half-spaces.
arguments
    request (1,1) struct
end
required=["frequency_hz","incidence_angle_rad","mu1_pa","eta1_pa_s", ...
    "rho1_kg_m3","mu2_pa","eta2_pa_s","rho2_kg_m3"];
if ~all(isfield(request,cellstr(required)))
    error("swsynth:SHViscoelasticMissingParameter", ...
        "Provide frequency, angle, mu, eta and density for both media.");
end
v=zeros(1,numel(required));
for j=1:numel(required)
    a=request.(required(j));
    if ~isnumeric(a)||~isscalar(a)||~isreal(a)||~isfinite(a)
        error("swsynth:SHViscoelasticInvalidParameter", ...
            "Inputs must be finite real scalars.");
    end
    v(j)=double(a);
end
f=v(1);theta=v(2);mu1=v(3);eta1=v(4);rho1=v(5);
mu2=v(6);eta2=v(7);rho2=v(8);
if f<=0||theta<0||theta>=pi/2||any([mu1 rho1 mu2 rho2]<=0)|| ...
        any([eta1 eta2]<0)
    error("swsynth:SHViscoelasticInvalidParameter", ...
        "Positive frequency, stiffness, density; nonnegative viscosity; angle in [0,pi/2).");
end
omega=2*pi*f;
G1=complex(mu1,omega*eta1);
G2=complex(mu2,omega*eta2);
% Select attenuating forward wave branch for the stated harmonic convention.
k1=conj(omega*sqrt(rho1/G1));
k2=conj(omega*sqrt(rho2/G2));
kt=k1*sin(theta);
kn1=k1*cos(theta);
kn2=sqrt(k2^2-kt^2);
if imag(kn2)<0 || (abs(imag(kn2))<1e-13 && real(kn2)<0)
    kn2=-kn2;
end
Z1=G1*kn1;
Z2=G2*kn2;
if abs(Z1+Z2)<eps*max(1,abs(Z1)+abs(Z2))
    error("swsynth:SHViscoelasticSingularInterface", ...
        "Interface impedance sum is numerically singular.");
end
R=(Z1-Z2)/(Z1+Z2);
T=2*Z1/(Z1+Z2);
out=struct( ...
    "model","kelvin_voigt_welded_plane_SH", ...
    "frequency_hz",f,"incidence_angle_rad",theta, ...
    "complex_modulus_1_pa",G1,"complex_modulus_2_pa",G2, ...
    "wavenumber_1_rad_m",k1,"wavenumber_2_rad_m",k2, ...
    "wavenumber_tangential_rad_m",kt, ...
    "wavenumber_normal_1_rad_m",kn1, ...
    "wavenumber_normal_2_rad_m",kn2, ...
    "reflection_displacement",R,"transmission_displacement",T, ...
    "displacement_continuity_residual",1+R-T, ...
    "traction_continuity_residual",Z1*(1-R)-Z2*T, ...
    "transmitted_normal_decay_np_m",imag(kn2));
end
