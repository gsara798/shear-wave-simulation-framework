function out=psvElasticCoefficients(request)
%PSVELASTICCOEFFICIENTS Welded isotropic elastic P-SV interface.
% An SV wave arrives from x<0 toward +x, interface normal +x.
% Plane of incidence x-z, exp(i*(k_x*x+k_z*z-omega*t)).
% Displacement and normal/tangential traction continuous at x=0.
% Output amplitudes multiply unit displacement polarizations (not energy).
arguments
    request (1,1) struct
end
names=["frequency_hz","incidence_angle_rad", ...
    "cp1_m_s","cs1_m_s","rho1_kg_m3", ...
    "cp2_m_s","cs2_m_s","rho2_kg_m3"];
if ~all(isfield(request,cellstr(names)))
    error("swsynth:PSVMissingField","Provide frequency, SV incidence angle, P/S speeds and densities.");
end
v=zeros(1,numel(names));
for j=1:numel(names)
    a=request.(names(j));
    if ~isnumeric(a)||~isscalar(a)||~isreal(a)||~isfinite(a)
        error("swsynth:PSVInvalidParameter","Parameters must be finite real scalars.");
    end
    v(j)=double(a);
end
f=v(1);theta=v(2);cp1=v(3);cs1=v(4);rho1=v(5);
cp2=v(6);cs2=v(7);rho2=v(8);
if f<=0||theta<0||theta>=pi/2|| ...
        any([cp1 cs1 rho1 cp2 cs2 rho2]<=0)|| ...
        cp1^2<=4*cs1^2/3||cp2^2<=4*cs2^2/3
    error("swsynth:PSVInvalidParameter", ...
        "Require positive properties, stable isotropic Lamé parameters, angle [0,pi/2).");
end
omega=2*pi*f;
mu=[rho1*cs1^2,rho2*cs2^2];
lambda=[rho1*(cp1^2-2*cs1^2),rho2*(cp2^2-2*cs2^2)];
kt=omega/cs1*sin(theta);
kP=[omega/cp1,omega/cp2];kS=[omega/cs1,omega/cs2];
% Choose outgoing branches: transmitted +x and reflected -x.
nP=sqrt(complex(kP.^2-kt^2,0));
nS=sqrt(complex(kS.^2-kt^2,0));
inc=modeColumn("SV",nS(1),kt,kS(1),lambda(1),mu(1));
rP=modeColumn("P",-nP(1),kt,kP(1),lambda(1),mu(1));
rSV=modeColumn("SV",-nS(1),kt,kS(1),lambda(1),mu(1));
tP=modeColumn("P",nP(2),kt,kP(2),lambda(2),mu(2));
tSV=modeColumn("SV",nS(2),kt,kS(2),lambda(2),mu(2));
% Reflected + incident = transmitted (displacement and traction).
M=[rP,rSV,-tP,-tSV];
a=M\(-inc);
res=inc+M*a;
% Flux factors: real(traction/i dot conj(displacement)).
% Reflected propagating modes carry negative signed x-flux.
fluxIn=fluxFactor(inc);
refP=fluxFactor(rP)*abs(a(1))^2;
refSV=fluxFactor(rSV)*abs(a(2))^2;
transP=fluxFactor(tP)*abs(a(3))^2;
transSV=fluxFactor(tSV)*abs(a(4))^2;
out=struct("model","elastic_welded_plane_PSV_SV_incident", ...
    "frequency_hz",f,"incidence_angle_rad",theta, ...
    "tangential_wavenumber_rad_m",kt, ...
    "reflection_P_displacement",a(1), ...
    "reflection_SV_displacement",a(2), ...
    "transmission_P_displacement",a(3), ...
    "transmission_SV_displacement",a(4), ...
    "incident_state",inc,"reflected_P_state",rP, ...
    "reflected_SV_state",rSV,"transmitted_P_state",tP, ...
    "transmitted_SV_state",tSV, ...
    "boundary_residual",res, ...
    "incident_normal_flux_factor",fluxIn, ...
    "reflected_P_energy_fraction",-refP/fluxIn, ...
    "reflected_SV_energy_fraction",-refSV/fluxIn, ...
    "transmitted_P_energy_fraction",transP/fluxIn, ...
    "transmitted_SV_energy_fraction",transSV/fluxIn);
end

function v=modeColumn(kind,kx,kz,k,lambda,mu)
if kind=="P"
    ux=kx/k;uz=kz/k;
else
    ux=-kz/k;uz=kx/k;
end
% Tractions divided by i (the common harmonic stress factor).
sxx=(lambda+2*mu)*kx*ux+lambda*kz*uz;
sxz=mu*(kz*ux+kx*uz);
v=[ux;uz;sxx;sxz];
end

function f=fluxFactor(v)
f=real(v(3)*conj(v(1))+v(4)*conj(v(2)));
end
