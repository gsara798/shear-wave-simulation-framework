% Analytic elastic P-SV plane-wave mode-conversion demo (SV incident).
% Interface x=0; exp(i*(kx*x+kz*z-omega*t)), z is tangent.
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
p=struct("frequency_hz",500,"incidence_angle_rad",pi/9, ...
 "cp1_m_s",5,"cs1_m_s",2,"rho1_kg_m3",1000, ...
 "cp2_m_s",7,"cs2_m_s",3,"rho2_kg_m3",1100);
r=swsynth.propagation.interface.psvElasticCoefficients(p);
omega=2*pi*p.frequency_hz;
x=-.012:.0001:.012;z=(-.012:.0001:.012).';
[Z,X]=ndgrid(z,x);
left=X<0;right=~left;
kt=r.tangential_wavenumber_rad_m;
% For each solution column, state(1:2) is unit displacement polarization.
% Mode normal wavenumbers are selected as outgoing waves.
kS1=omega/p.cs1_m_s;kP1=omega/p.cp1_m_s;
kS2=omega/p.cs2_m_s;kP2=omega/p.cp2_m_s;
qSI=sqrt(complex(kS1^2-kt^2,0));
qPR=-sqrt(complex(kP1^2-kt^2,0));
qSR=-qSI;
qPT=sqrt(complex(kP2^2-kt^2,0));
qST=sqrt(complex(kS2^2-kt^2,0));
% For x<0, outgoing evanescent reflected modes must decay toward -x.
% Their branch is -sqrt(...), so imaginary part is negative.
mode=[qSI,qPR,qSR,qPT,qST];
state=[r.incident_state,r.reflected_P_state,r.reflected_SV_state, ...
       r.transmitted_P_state,r.transmitted_SV_state];
amp=[1,r.reflection_P_displacement,r.reflection_SV_displacement, ...
       r.transmission_P_displacement,r.transmission_SV_displacement];
U=cell(1,5);
for j=1:5
    ph=exp(1i*(mode(j)*X+kt*Z));
    if j<=3;ph(right)=0;else;ph(left)=0;end
    U{j}=complex(zeros([size(X),2]));
    U{j}(:,:,1)=amp(j)*state(1,j)*ph;
    U{j}(:,:,2)=amp(j)*state(2,j)*ph;
end
total=U{1}+U{2}+U{3}+U{4}+U{5};
figure("Name","Elastic SV incidence with P/SV mode conversion");
tiledlayout(2,3);
titles={"SV incident","P reflected","SV reflected", ...
    "P transmitted","SV transmitted","Total displacement"};
fields=[U,{total}];
for j=1:6
    nexttile;
    % Vector magnitude of instantaneous displacement at t=0.
    displayField=sqrt(real(fields{j}(:,:,1)).^2+real(fields{j}(:,:,2)).^2);
    imagesc(x*1000,z*1000,displayField);
    axis image;axis xy;colorbar;hold on;xline(0,"w--");
    title(titles{j});xlabel("x (mm)");ylabel("z (mm)");
end
fprintf("Boundary continuity residual norm: %.3g\n",norm(r.boundary_residual));
fprintf("Elastic energy fractions: R_P %.4f, R_SV %.4f, T_P %.4f, T_SV %.4f (sum %.6f)\n", ...
    r.reflected_P_energy_fraction,r.reflected_SV_energy_fraction, ...
    r.transmitted_P_energy_fraction,r.transmitted_SV_energy_fraction, ...
    r.reflected_P_energy_fraction+r.reflected_SV_energy_fraction+ ...
    r.transmitted_P_energy_fraction+r.transmitted_SV_energy_fraction);
