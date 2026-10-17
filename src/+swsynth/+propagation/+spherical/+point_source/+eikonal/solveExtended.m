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
% Seed a local neighborhood with exact homogeneous-source travel times.
% This limits the point-source staircasing error of a single fixed node.
[~,ix]=min(abs(xx-source(1)));
[~,iy]=min(abs(yy-source(2)));
[~,iz]=min(abs(zz-source(3)));
initial=inf(size(c));
fixed=false(size(c));
[ZZs,YYs,XXs]=ndgrid(zz,yy,xx);
sourceDistance=sqrt((XXs-source(1)).^2+(YYs-source(2)).^2+ ...
    (ZZs-source(3)).^2);
seedRadius=2*max([mean(diff(xx)),mean(diff(yy)),mean(diff(zz))]);
fixed=sourceDistance<=seedRadius;
if ~any(fixed(:));fixed(iz,iy,ix)=true;end
% The local source-cell speed gives a first-order near-source solution.
% Do not seed across an interface: use only the source material.
sourceSpeed=c(iz,iy,ix);
fixed=fixed & abs(c-sourceSpeed)<=1e-8*max(1,sourceSpeed);
fixed(iz,iy,ix)=true;
initial(fixed)=sourceDistance(fixed)/sourceSpeed;
solverOpts=struct();
if isfield(options,"MaximumIterations");solverOpts.MaximumIterations=options.MaximumIterations;end
if isfield(options,"ToleranceS");solverOpts.ToleranceS=options.ToleranceS;end
if isfield(options,"Verbose");solverOpts.Verbose=options.Verbose;end
if isfield(options,"SpatialOrder");solverOpts.SpatialOrder=options.SpatialOrder;end
[T,d]=swsynth.numerics.eikonal.solveFastSweeping3D( ...
    1./c,mean(diff(xx)),mean(diff(yy)),mean(diff(zz)),initial,fixed,solverOpts);
if ~d.converged,error("swsynth:PointSource3DEikonalDidNotConverge","Extended Eikonal failed to converge.");end
% Trace first-arrival characteristics backward. In homogeneous media,
% use the exact straight-ray integral as a stable reference (also avoids
% spurious gradient errors near the discretized source).
[Zo,Xo]=ndgrid(z,x);
uniformC=max(abs(c(:)-c(1)))<=1e-10*max(1,c(1));
uniformAlpha=max(abs(alpha(:)-alpha(1)))<=1e-10*max(1,alpha(1));
hasPlane=isfield(options,"AttenuationPlane") && ~isempty(options.AttenuationPlane);
if uniformC && (uniformAlpha || hasPlane)
    rr=sqrt((Xo-source(1)).^2+(obsY-source(2)).^2+ ...
        (Zo-source(3)).^2);
    if hasPlane
        sourcePoints=repmat(source,numel(Xo),1);
        targets=[Xo(:),obsY*ones(numel(Xo),1),Zo(:)];
        Aobs=reshape(swsynth.propagation.attenuation.integratePlanarSegment( ...
            sourcePoints,targets,options.AttenuationPlane),size(Zo));
    else
        Aobs=alpha(1)*rr;
    end
else
    [dTy,dTz,dTx]=gradient(T,mean(diff(yy)),mean(diff(zz)),mean(diff(xx)));
    xo=Xo(:);yo=obsY*ones(numel(Xo),1);zo=Zo(:);
    amp=zeros(numel(xo),1);
    near=1.5*max([mean(diff(xx)),mean(diff(yy)),mean(diff(zz))]);
    active=vecnorm([xo-source(1),yo-source(2),zo-source(3)],2,2)>near;
    step=.5*min([mean(diff(xx)),mean(diff(yy)),mean(diff(zz))]);
    maxSteps=ceil(5*norm([range(xx),range(yy),range(zz)])/step);
    for iter=1:maxSteps
        if ~any(active),break,end
        idx=find(active);
        qx=xo(idx);qy=yo(idx);qz=zo(idx);
        gx=interpn(zz,yy,xx,dTx,qz,qy,qx,"linear",0);
        gy=interpn(zz,yy,xx,dTy,qz,qy,qx,"linear",0);
        gz=interpn(zz,yy,xx,dTz,qz,qy,qx,"linear",0);
        g=sqrt(gx.^2+gy.^2+gz.^2);
        if any(g<=1e-14)
            error("swsynth:ExtendedRayStalled","Ray gradient vanished away from source.");
        end
        nx=qx-step*gx./g;ny=qy-step*gy./g;nz=qz-step*gz./g;
        a0=interpn(zz,yy,xx,alpha,qz,qy,qx,"linear");
        a1=interpn(zz,yy,xx,alpha,nz,ny,nx,"linear",NaN);
        if any(~isfinite(a1))
            error("swsynth:ExtendedRayExited","Ray left the extended propagation domain.");
        end
        if hasPlane
            ray0=[qx,qy,qz];ray1=[nx,ny,nz];
            amp(idx)=amp(idx)+ ...
                swsynth.propagation.attenuation.integratePlanarSegment( ...
                ray0,ray1,options.AttenuationPlane);
        else
            amp(idx)=amp(idx)+step*.5.*(a0+a1);
        end
        xo(idx)=nx;yo(idx)=ny;zo(idx)=nz;
        active(idx)=vecnorm([nx-source(1),ny-source(2),nz-source(3)],2,2)>near;
    end
    if any(active)
        error("swsynth:ExtendedRayNotTerminated","Backtracing did not reach source.");
    end
    % Recover missing source-core contribution using local source loss.
    remaining=sqrt((xo-source(1)).^2+(yo-source(2)).^2+ ...
        (zo-source(3)).^2);
    sourceLoss=alpha(iz,iy,ix);
    if hasPlane
        amp=amp+swsynth.propagation.attenuation.integratePlanarSegment( ...
            [xo,yo,zo],repmat(source,numel(xo),1),options.AttenuationPlane);
    else
        amp=amp+sourceLoss*remaining;
    end
    Aobs=reshape(amp,size(Zo));
end
Tobs=reshape(interpn(zz,yy,xx,T,Zo,obsY*ones(size(Zo)),Xo,"linear"),size(Zo));
% Optional diagnostics are only retained when explicitly requested.
if isfield(options,"ReturnVolumeDiagnostics") && ...
        logical(options.ReturnVolumeDiagnostics)
    diagVolume=struct("x_m",xx,"y_m",yy,"z_m",zz, ...
        "travel_time_zyx",T,"source_xyz_m",source, ...
        "observation_y_m",obsY);
end
diag=struct("model","extended_3d_first_arrival", ...
    "outside_fov_medium","nearest_edge_constant_y_invariant", ...
    "grid_size_zyx",size(c),"grid_spacing_m",h, ...
    "solver",d,"source_xyz_m",source);
if exist("diagVolume","var")
    diag.volume=diagVolume;
end
end

function a=axisWithPoint(lo,hi,h)
n=max(3,ceil((hi-lo)/h)+1);
a=linspace(lo,hi,n);
end
