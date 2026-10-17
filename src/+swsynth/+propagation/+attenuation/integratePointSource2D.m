function optical=integratePointSource2D(T,alpha,x,z,source)
%INTEGRATEPOINTSOURCE2D Integral alpha ds along backtraced first arrivals.
% Source is internal, in x-z plane; direct geometric-ray approximation.
arguments
    T (:,:) double
    alpha (:,:) double
    x (1,:) double
    z (:,1) double
    source (1,3) double
end
if ~isequal(size(T),size(alpha),[numel(z),numel(x)]) || ...
        any(~isfinite(T(:))) || any(~isfinite(alpha(:))) || any(alpha(:)<0)
    error("swsynth:InvalidAttenuationMap","Invalid maps for point-source ray integration.");
end
dx=mean(diff(x));dz=mean(diff(z));
ds=.5*min(dx,dz);
[dTx,dTz]=gradient(T,dx,dz);
[Z,X]=ndgrid(z,x);
px=X;pz=Z;optical=zeros(size(T));
radius=1.5*hypot(dx,dz);
active=hypot(px-source(1),pz-source(3))>radius;
maxsteps=ceil(3*hypot(range(x),range(z))/ds);
for it=1:maxsteps
    if ~any(active(:)),break,end
    idx=find(active);
    xx=px(idx);zz=pz(idx);
    gx=interp2(x,z,dTx,xx,zz,"linear",0);
    gz=interp2(x,z,dTz,xx,zz,"linear",0);
    normGrad=hypot(gx,gz);
    valid=normGrad>1e-12;
    nx=zeros(size(gx));nz=zeros(size(gz));
    nx(valid)=gx(valid)./normGrad(valid);
    nz(valid)=gz(valid)./normGrad(valid);
    x1=xx-ds*nx;z1=zz-ds*nz;
    oldDist=hypot(xx-source(1),zz-source(3));
    newDist=hypot(x1-source(1),z1-source(3));
    % Stop at a finite radius around the source to avoid the singularity.
    % Last segment is an approximation to the unresolved source neighborhood.
    a0=interp2(x,z,alpha,xx,zz,"linear",0);
    a1=interp2(x,z,alpha,x1,z1,"linear",0);
    optical(idx)=optical(idx)+ds*.5.*(a0+a1);
    px(idx)=x1;pz(idx)=z1;
    inside=x1>=x(1) & x1<=x(end) & z1>=z(1) & z1<=z(end);
    active(idx)=valid & inside & newDist>radius & newDist<oldDist+ds*.1;
    if any(valid & ~inside & oldDist>radius)
        error("swsynth:PointSourceAttenuationRayExited", ...
            "A backtraced ray exited the domain before reaching the source.");
    end
end
if any(active(:))
    error("swsynth:AttenuationRayNotTerminated", ...
        "Point-source attenuation rays failed to converge to source.");
end
end
