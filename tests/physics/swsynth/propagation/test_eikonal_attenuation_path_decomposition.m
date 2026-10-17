function tests=test_eikonal_attenuation_path_decomposition
% Compare exact piecewise optical depth, straight quadrature, and Eikonal rays.
tests=functiontests(localfunctions);
end

function testStraightVersusEikonal(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
x=0:.001:.012; z=(0:.001:.012).';
src=[-.004 0 .006]; xi=.006;
c=2; a1=8; a2=35;
speed=c*ones(numel(z),numel(x));
alpha=a1*ones(size(speed));alpha(:,x>=xi)=a2;
[Z,X]=ndgrid(z,x);
dist=hypot(X-src(1),Z-src(3));
fraction=(xi-src(1))./(X-src(1));
fraction=min(1,max(0,fraction));
exact=dist.*(a1*fraction+a2*(1-fraction));
% Interpolated numerical straight-ray quadrature evaluates the same
% gridded coefficient with the same linear interpolation as the current
% Eikonal integrator; it is NOT exact for discontinuous alpha.
fprintf("\nPiecewise optical-depth comparison\n");
for h=[.002 .0015 .001]
    opts=struct("GridSpacingM",h,"SpatialOrder",2, ...
        "MaxGridCells",300000,"MaximumIterations",200,"ToleranceS",1e-9);
    [~,aEik,d]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
        speed,alpha,x,z,src,0,opts);
    % Model the extended solver's constant-edge extrapolation exactly:
    % build its numerical grid from the same public-domain assumptions.
    xx=extendedAxis(min(x(1),src(1))-2*h,max(x(end),src(1))+2*h,h);
    zz=extendedAxis(min(z(1),src(3))-2*h,max(z(end),src(3))+2*h,h);
    yy=extendedAxis(min(0,src(2))-2*h,max(0,src(2))+2*h,h);
    [ZZ,YY,XX]=ndgrid(zz,yy,xx);
    ax=min(max(XX,x(1)),x(end)); az=min(max(ZZ,z(1)),z(end));
    alphaExtended=interp2(x,z,alpha,ax,az,"nearest");
    straight=zeros(size(exact));
    ds=.5*min([mean(diff(xx)),mean(diff(yy)),mean(diff(zz))]);
    for index=1:numel(X)
        r=dist(index);
        n=max(1,ceil(r/ds));
        t=linspace(0,1,n+1);
        qx=src(1)+t*(X(index)-src(1));
        qz=src(3)+t*(Z(index)-src(3));
        qy=zeros(size(qx));
        values=interpn(zz,yy,xx,alphaExtended,qz,qy,qx,"linear");
        verifyTrue(tc,all(isfinite(values)));
        straight(index)=r*trapz(t,values);
    end
    errStraight=relativeError(straight,exact);
    errEik=relativeError(aEik,exact);
    difference=relativeError(aEik,straight);
    fprintf("h=%.4g straight_vs_exact=%.6g eikonal_vs_exact=%.6g eikonal_vs_straight=%.6g\n", ...
        h,errStraight,errEik,difference);
    verifyTrue(tc,d.solver.converged);
    verifyTrue(tc,all(isfinite(aEik(:))));
    verifyGreaterThanOrEqual(tc,min(aEik(:)),-1e-12);
end
end

function e=relativeError(a,b)
e=norm(a(:)-b(:))/norm(b(:));
end
function a=extendedAxis(lo,hi,h)
n=max(3,ceil((hi-lo)/h)+1);
a=linspace(lo,hi,n);
end
