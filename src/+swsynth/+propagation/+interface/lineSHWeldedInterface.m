function out=lineSHWeldedInterface(request)
%LINESHWELDEDINTERFACE 2D antiplane SH line source at welded elastic interface.
% Interface x=0 (or interface_x_m), source in x<interface. Time exp(-iwt).
% Weyl integral of the outgoing 2D Green field (i/4)H0^(1)(kr).
% The source normalization is for unit Helmholtz forcing; traction mu*du/dx.
arguments
    request (1,1) struct
end
fields=["x_m","z_m","source_xz_m","interface_x_m", ...
    "frequency_hz","cs1_m_s","cs2_m_s","rho1_kg_m3","rho2_kg_m3"];
if ~all(isfield(request,cellstr(fields)))
    error("swsynth:SHLineInterfaceMissingField","Missing line interface parameter.");
end
x=double(request.x_m(:).');z=double(request.z_m(:));
src=double(request.source_xz_m(:).');xi=double(request.interface_x_m);
f=double(request.frequency_hz);c1=double(request.cs1_m_s);
c2=double(request.cs2_m_s);rho1=double(request.rho1_kg_m3);
rho2=double(request.rho2_kg_m3);
if numel(x)<2||numel(z)<2||any(diff(x)<=0)||any(diff(z)<=0)|| ...
        any(~isfinite([x(:);z(:)]))||~isequal(size(src),[1 2])|| ...
        any(~isfinite(src))||~isscalar(xi)||~isfinite(xi)||src(1)>=xi|| ...
        any([f c1 c2 rho1 rho2]<=0)||any(~isfinite([f c1 c2 rho1 rho2]))
    error("swsynth:SHLineInterfaceInvalidParameter","Invalid line-interface parameters.");
end
K=6000;dk=2;
if isfield(request,"spectral_count");K=double(request.spectral_count);end
if isfield(request,"spectral_step_rad_m");dk=double(request.spectral_step_rad_m);end
if ~isscalar(K)||K<100||K~=floor(K)|| ...
        ~isscalar(dk)||dk<=0||~isfinite(dk)
    error("swsynth:SHLineInterfaceInvalidSpectrum","Invalid spectrum count or step.");
end
enabled=true;
if isfield(request,"interface_enabled")
    enabled=request.interface_enabled;
    if ~islogical(enabled)||~isscalar(enabled)
        error("swsynth:SHLineInterfaceInvalidSwitch","interface_enabled must be logical scalar.");
    end
end
k1=2*pi*f/c1;k2=2*pi*f/c2;
mu1=rho1*c1^2;mu2=rho2*c2^2;
kt=(-K:K)*dk;
q1=sqrt(complex(k1^2-kt.^2,0));
q2=sqrt(complex(k2^2-kt.^2,0));
R=(mu1*q1-mu2*q2)./(mu1*q1+mu2*q2);
T=1+R;
% 2D outgoing Green Weyl representation: (i/4pi) integral
% exp(i*kz*(z-zs)+i*q1*abs(x-xs))/q1 dkz.
% Only scattered fields use quadrature; exact Hankel for incident field.
[Z,X]=ndgrid(z,x);
dist=hypot(X-src(1),Z-src(2));
if any(dist(:)<1e-12)
    error("swsynth:SHLineInterfaceSingularSource","Source lies on observation grid.");
end
incident=1i/4*besselh(0,1,k1*dist);
reflected=complex(zeros(size(X)));
transmitted=complex(zeros(size(X)));
if enabled
    idxLeft=find(x<xi);idxRight=find(x>=xi);
    % Integrate in blocks to avoid allocating [Nz,Nx,Nspectral].
    chunk=128;
    for j=1:chunk:numel(kt)
        ids=j:min(j+chunk-1,numel(kt));
        kz=kt(ids);qa=q1(ids);qb=q2(ids);
        base=(1i/(4*pi))*dk*exp(-1i*kz*src(2))./qa;
        phaseZ=exp(1i*z*kz);
        if ~isempty(idxLeft)
            phaseX=exp(1i*(2*xi-src(1)-x(idxLeft).')*qa);
            reflected(:,idxLeft)=reflected(:,idxLeft)+ ...
                (phaseZ.*(base.*R(ids)))*phaseX.';
        end
        if ~isempty(idxRight)
            phaseX=exp(1i*((xi-src(1))*qa+ ...
                (x(idxRight).'-xi).*qb));
            transmitted(:,idxRight)=transmitted(:,idxRight)+ ...
                (phaseZ.*(base.*T(ids)))*phaseX.';
        end
    end
end
total=incident;
if enabled
    total(:,x<xi)=incident(:,x<xi)+reflected(:,x<xi);
    total(:,x>=xi)=transmitted(:,x>=xi);
end
out=struct("model","elastic_antiplane_SH_welded_line_source", ...
    "interface_enabled",enabled,"x_m",x,"z_m",z, ...
    "source_xz_m",src,"interface_x_m",xi, ...
    "incident_uy_zx",incident,"reflected_uy_zx",reflected, ...
    "transmitted_uy_zx",transmitted,"total_uy_zx",total, ...
    "spectral_step_rad_m",dk,"spectral_max_rad_m",K*dk);
end
