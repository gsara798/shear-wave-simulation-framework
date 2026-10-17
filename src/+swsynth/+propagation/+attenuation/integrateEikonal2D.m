function opticalDepth=integrateEikonal2D(T,alpha,x,z)
%INTEGRATEEIKONAL2D Backtrace phase-gradient rays, integrate alpha ds.
% Intended for projected3d incidence strictly in x-z (direction_y=0).
% Travel-time gradients are followed backwards until leaving the FOV.
arguments
    T (:,:) double
    alpha (:,:) double
    x (1,:) double
    z (:,1) double
end
if ~isequal(size(T),size(alpha),[numel(z),numel(x)]) || ...
        any(~isfinite(T(:))) || any(~isfinite(alpha(:))) || ...
        any(alpha(:)<0)
    error("swsynth:InvalidAttenuationMap","Invalid travel time or attenuation map.");
end
dx=mean(diff(x));dz=mean(diff(z));ds=0.5*min(dx,dz);
[dtX,dtZ]=gradient(T,dx,dz);
[Z,X]=ndgrid(z,x);
px=X;pz=Z;
opticalDepth=zeros(size(T));
active=true(size(T));
nsteps=ceil(3*hypot(range(x),range(z))/ds);
for step=1:nsteps
    if ~any(active(:)),break,end
    ix=find(active);
    xx=px(ix);zz=pz(ix);
    gx=interp2(x,z,dtX,xx,zz,"linear",0);
    gz=interp2(x,z,dtZ,xx,zz,"linear",0);
    mag=hypot(gx,gz);
    valid=mag>1e-12;
    nx=zeros(size(gx));nz=zeros(size(gz));
    nx(valid)=gx(valid)./mag(valid);
    nz(valid)=gz(valid)./mag(valid);
    newx=xx-ds*nx;newz=zz-ds*nz;
    inside=newx>=x(1) & newx<=x(end) & newz>=z(1) & newz<=z(end);
    aa=interp2(x,z,alpha,xx,zz,"linear",0);
    aa1=interp2(x,z,alpha,newx,newz,"linear",0);
    opticalDepth(ix)=opticalDepth(ix)+0.5*ds*(aa+aa1);
    px(ix)=newx;pz(ix)=newz;
    active(ix)=valid & inside;
end
if any(active(:))
    error("swsynth:AttenuationRayNotTerminated", ...
        "Eikonal rays did not leave the computational domain.");
end
end
