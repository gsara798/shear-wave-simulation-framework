% Mixed-polarization incident shear wave on an elastic soft-tissue bilayer.
% Local interface frame: x normal, z incidence tangent, y SH.
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
theta=pi/9;
sh=[0 1 0];sv=[-sin(theta) 0 cos(theta)];
p=struct("frequency_hz",500,"incidence_angle_rad",theta, ...
    "cp1_m_s",1540,"cs1_m_s",2,"rho1_kg_m3",1000, ...
    "cp2_m_s",1560,"cs2_m_s",3,"rho2_kg_m3",1050, ...
    "shear_polarization_xyz",(sh+sv)/sqrt(2));
r=swsynth.propagation.interface.elasticMixedShearCoefficients(p);
x=-.012:.0001:.012;z=(-.012:.0001:.012).';
[Z,X]=ndgrid(z,x);left=X<0;right=~left;
omega=2*pi*p.frequency_hz;kt=r.PSV.tangential_wavenumber_rad_m;
kS1=omega/p.cs1_m_s;kP1=omega/p.cp1_m_s;
kS2=omega/p.cs2_m_s;kP2=omega/p.cp2_m_s;
qS1=sqrt(complex(kS1^2-kt^2,0));
qS2=sqrt(complex(kS2^2-kt^2,0));
qP1=sqrt(complex(kP1^2-kt^2,0));
qP2=sqrt(complex(kP2^2-kt^2,0));
U=complex(zeros([size(X),3]));
% SH: y component only; SV and P: x,z components.
shInc=r.incident_SH_amplitude*exp(1i*(qS1*X+kt*Z));
shRef=r.reflected_SH_amplitude*exp(1i*(-qS1*X+kt*Z));
shTr=r.transmitted_SH_amplitude*exp(1i*(qS2*X+kt*Z));
shInc(right)=0;shRef(right)=0;shTr(left)=0;
U(:,:,2)=shInc+shRef+shTr;
modes=[qS1,-qP1,-qS1,qP2,qS2];
states=[r.PSV.incident_state,r.PSV.reflected_P_state, ...
 r.PSV.reflected_SV_state,r.PSV.transmitted_P_state,r.PSV.transmitted_SV_state];
amp=[r.incident_SV_amplitude,r.reflected_P_amplitude, ...
 r.reflected_SV_amplitude,r.transmitted_P_amplitude, ...
 r.transmitted_SV_amplitude];
convertedP=complex(zeros([size(X),3]));
for j=1:5
    field=amp(j)*exp(1i*(modes(j)*X+kt*Z));
    if j<=3;field(right)=0;else;field(left)=0;end
    U(:,:,1)=U(:,:,1)+states(1,j)*field;
    U(:,:,3)=U(:,:,3)+states(2,j)*field;
    if j==2 || j==4
        convertedP(:,:,1)=convertedP(:,:,1)+states(1,j)*field;
        convertedP(:,:,3)=convertedP(:,:,3)+states(2,j)*field;
    end
end
figure("Name","Elastic mixed SH+SV incident shear wave");
tiledlayout(2,2);
panel={real(U(:,:,2)),real(U(:,:,1)),real(U(:,:,3)), ...
    sqrt(sum(real(U).^2,3))};
titles={"SH displacement Uy","In-plane displacement Ux", ...
    "In-plane displacement Uz","Total instantaneous |u|"};
for j=1:4
    nexttile;imagesc(x*1000,z*1000,panel{j});axis image;axis xy;
    colorbar;xline(0,"w--");title(titles{j});
    xlabel("x (mm)");ylabel("z (mm)");
end
figure("Name","Mixed shear: converted P near interface");
pEnvelope=sqrt(sum(abs(convertedP).^2,3));
imagesc(x*1000,z*1000,log10(max(pEnvelope,1e-12)));
axis image;axis xy;colorbar;xline(0,"w--");
xlabel("x (mm)");ylabel("z (mm)");title("Converted P envelope (log10)");
fprintf("Incident SH=%.4f SV=%.4f; P conversion comes only from SV.\n", ...
    r.incident_SH_amplitude,r.incident_SV_amplitude);
