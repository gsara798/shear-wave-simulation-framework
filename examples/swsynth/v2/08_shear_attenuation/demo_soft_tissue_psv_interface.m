% SV incidence on an elastic, nearly incompressible soft-tissue bilayer.
% P speeds near 1540 m/s. This is a lossless P-SV boundary demonstration,
% NOT a full Kelvin-Voigt P/S model or a time-domain simulation.
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
p=struct("frequency_hz",500,"incidence_angle_rad",pi/9, ...
    "cp1_m_s",1540,"cs1_m_s",2,"rho1_kg_m3",1000, ...
    "cp2_m_s",1560,"cs2_m_s",3,"rho2_kg_m3",1050);
r=swsynth.propagation.interface.psvElasticCoefficients(p);
omega=2*pi*p.frequency_hz;
x=-.012:.0001:.012;z=(-.012:.0001:.012).';
[Z,X]=ndgrid(z,x);left=X<0;right=~left;
kt=r.tangential_wavenumber_rad_m;
kS1=omega/p.cs1_m_s;kP1=omega/p.cp1_m_s;
kS2=omega/p.cs2_m_s;kP2=omega/p.cp2_m_s;
q=[sqrt(complex(kS1^2-kt^2,0)), ...
    -sqrt(complex(kP1^2-kt^2,0)), ...
    -sqrt(complex(kS1^2-kt^2,0)), ...
    sqrt(complex(kP2^2-kt^2,0)), ...
    sqrt(complex(kS2^2-kt^2,0))];
assert(imag(q(2))<=0 && imag(q(4))>=0, ...
    "Outgoing evanescent P branches must decay away from interface.");
states=[r.incident_state,r.reflected_P_state,r.reflected_SV_state, ...
    r.transmitted_P_state,r.transmitted_SV_state];
amps=[1,r.reflection_P_displacement,r.reflection_SV_displacement, ...
    r.transmission_P_displacement,r.transmission_SV_displacement];
U=cell(1,5);
for j=1:5
    ph=exp(1i*(q(j)*X+kt*Z));
    if j<=3;ph(right)=0;else;ph(left)=0;end
    U{j}=complex(zeros([size(X),2]));
    U{j}(:,:,1)=amps(j)*states(1,j)*ph;
    U{j}(:,:,2)=amps(j)*states(2,j)*ph;
end
total=U{1}+U{2}+U{3}+U{4}+U{5};
figure("Name","Soft tissue P-SV: instantaneous vector displacement");
tiledlayout(2,3);
labels={"SV incident","P reflected (evanescent)","SV reflected", ...
    "P transmitted (evanescent)","SV transmitted","Total displacement"};
fields=[U,{total}];
for j=1:6
    nexttile;
    snapshot=sqrt(real(fields{j}(:,:,1)).^2+real(fields{j}(:,:,2)).^2);
    imagesc(x*1000,z*1000,snapshot);
    axis image;axis xy;colorbar;hold on;xline(0,"w--");
    xlabel("x (mm)");ylabel("z (mm)");title(labels{j});
end
% Phasor envelope of converted P fields: reveals their near-interface decay.
figure("Name","Soft tissue converted P evanescent envelopes");
tiledlayout(1,2);
for j=[2 4]
    nexttile;
    envelope=sqrt(abs(U{j}(:,:,1)).^2+abs(U{j}(:,:,2)).^2);
    imagesc(x*1000,z*1000,log10(max(envelope,1e-12)));
    axis image;axis xy;colorbar;hold on;xline(0,"w--");
    xlabel("x (mm)");ylabel("z (mm)");
    title("log10 |u|: "+labels{j});
end
decayReflection=-imag(q(2));
decayTransmission=imag(q(4));
fprintf("cP=[%.1f %.1f] m/s; cS=[%.1f %.1f] m/s\n", ...
    p.cp1_m_s,p.cp2_m_s,p.cs1_m_s,p.cs2_m_s);
fprintf("P wavelengths in bulk: %.3f and %.3f m\n", ...
    p.cp1_m_s/p.frequency_hz,p.cp2_m_s/p.frequency_hz);
fprintf("P evanescent 1/e depth: reflected %.3f mm; transmitted %.3f mm\n", ...
    1000/decayReflection,1000/decayTransmission);
fprintf("Boundary residual norm: %.3g\n",norm(r.boundary_residual));
fractions=[r.reflected_P_energy_fraction,r.reflected_SV_energy_fraction, ...
    r.transmitted_P_energy_fraction,r.transmitted_SV_energy_fraction];
fprintf("Normal energy fractions [R_P R_SV T_P T_SV] = %s; sum = %.12f\n", ...
    mat2str(fractions,6),sum(fractions));
