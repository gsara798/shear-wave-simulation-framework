function [Tobs,Aobs,diag]=solveExtended(speedZX,lossZX,x,z,source,obsY,options)
%SOLVEEXTENDED 3D first-arrival Eikonal for projected3d measurements.
% Outside-FOV medium is explicitly assumed edge-constant in x and z,
% and y-invariant. The computation domain includes source and observation.
arguments
    speedZX (:,:) double
    lossZX (:,:) double
    x (1,:) double
    z (:,1) double
    source (1,3) double
    obsY (1,1) double
    options (1,1) struct = struct()
end
if ~isequal(size(speedZX),size(lossZX),[numel(z),numel(x)]) || ...
        any(speedZX(:)<=0 | ~isfinite(speedZX(:))) || ...
        any(lossZX(:)<0 | ~isfinite(lossZX(:)))
    error("swsynth:InvalidExtendedMedium","Invalid mechanical maps.");
end
dx=mean(diff(x));dz=mean(diff(z));
h=max([dx dz]);
if isfield(options,"GridSpacingM");h=double(options.GridSpacingM);end
if ~isscalar(h)||~isfinite(h)||h<=0
    error("swsynth:InvalidExtendedGrid","GridSpacingM must be positive.");
end
margin=2*h;
xx=axisWithPoint(min([x(1),source(1)])-margin,max([x(end),source(1)])+margin,h);
zz=axisWithPoint(min([z(1),source(3)])-margin,max([z(end),source(3)])+margin,h);
yy=axisWithPoint(min([obsY,source(2)])-margin,max([obsY,source(2)])+margin,h);
count=numel(xx)*numel(yy)*numel(zz);
maxCells=200000;
if isfield(options,"MaxGridCells");maxCells=double(options.MaxGridCells);end
if count>maxCells
    error("swsynth:ExtendedGridTooLarge", ...
        "Extended Eikonal requires %d cells (limit %d); increase GridSpacingM or MaxGridCells.",count,maxCells);
end
[ZZ,YY,XX]=ndgrid(zz,yy,xx);
% Edge extrapolation encodes an explicit homogeneous continuation of the
% nearest observed material, not a measured or user-defined exterior map.
cx=min(max(XX,x(1)),x(end));
cz=min(max(ZZ,z(1)),z(end));
c=interp2(x,z,speedZX,cx,cz,"nearest");
alpha=interp2(x,z,lossZX,cx,cz,"nearest");
[~,ix]=min(abs(xx-source(1)));
[~,iy]=min(abs(yy-source(2)));
[~,iz]=min(abs(zz-source(3)));
initial=inf(size(c));
fixed=false(size(c));
fixed(iz,iy,ix)=true;
initial(iz,iy,ix)=norm([xx(ix),yy(iy),zz(iz)]-source)/c(iz,iy,ix);
solverOpts=struct();
if isfield(options,"MaximumIterations");solverOpts.MaximumIterations=options.MaximumIterations;end
if isfield(options,"ToleranceS");solverOpts.ToleranceS=options.ToleranceS;end
if isfield(options,"Verbose");solverOpts.Verbose=options.Verbose;end
[T,d]=swsynth.numerics.eikonal.solveFastSweeping3D( ...
    1./c,mean(diff(xx)),mean(diff(yy)),mean(diff(zz)),initial,fixed,solverOpts);
if ~d.converged,error("swsynth:PointSource3DEikonalDidNotConverge","Extended Eikonal failed to converge.");end
% Accumulate loss along first-arrival rays by backward characteristics.
[dTy,dTz,dTx]=gradient(T,mean(diff(yy)),mean(diff(zz)),mean(diff(xx)));
[Zo,Xo]=ndgrid(z,x);
xo=Xo(:);yo=obsY*ones(numel(Xo),1);zo=Zo(:);
amp=zeros(numel(xo),1);
near=1.5*hypot(h,h);
active=vecnorm([xo-source(1),yo-source(2),zo-source(3)],2,2)>near;
step=.5*h;
maxSteps=ceil(5*norm([range(xx),range(yy),range(zz)])/step);
for iter=1:maxSteps
    if ~any(active),break,end
    idx=find(active);
    qx=xo(idx);qy=yo(idx);qz=zo(idx);
    gx=interpn(zz,yy,xx,dTx,qz,qy,qx,"linear",0);
    gy=interpn(zz,yy,xx,dTy,qz,qy,qx,"linear",0);
    gz=interpn(zz,yy,xx,dTz,qz,qy,qx,"linear",0);
    g=hypot(hypot(gx,gy),gz);
    if any(g<=1e-14)
        error("swsynth:ExtendedRayStalled","Ray gradient vanished away from source.");
    end
    nx=qx-step*gx./g;ny=qy-step*gy./g;nz=qz-step*gz./g;
    a0=interpn(zz,yy,xx,alpha,qz,qy,qx,"linear");
    a1=interpn(zz,yy,xx,alpha,nz,ny,nx,"linear",NaN);
    if any(~isfinite(a1))
        error("swsynth:ExtendedRayExited","Ray left the extended propagation domain.");
    end
    amp(idx)=amp(idx)+step*.5.*(a0+a1);
    xo(idx)=nx;yo(idx)=ny;zo(idx)=nz;
    active(idx)=vecnorm([nx-source(1),ny-source(2),nz-source(3)],2,2)>near;
end
if any(active),error("swsynth:ExtendedRayNotTerminated","Backtracing did not reach source.");end
Tobs=reshape(interpn(zz,yy,xx,T,Zo,obsY*ones(size(Zo)),Xo,"linear"),size(Zo));
Aobs=reshape(amp,size(Zo));
diag=struct("model","extended_3d_first_arrival", ...
    "outside_fov_medium","nearest_edge_constant_y_invariant", ...
    "grid_size_zyx",size(c),"grid_spacing_m",h, ...
    "solver",d,"source_xyz_m",source);
end

function a=axisWithPoint(lo,hi,h)
n=max(3,ceil((hi-lo)/h)+1);
a=linspace(lo,hi,n);
end
