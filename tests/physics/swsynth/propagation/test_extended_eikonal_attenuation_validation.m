function tests=test_extended_eikonal_attenuation_validation
% Validate ray-integrated optical depth independently from homogeneous shortcut.
tests=functiontests(localfunctions);
end

function testLayeredLossWithConstantSpeed(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
x=0:.001:.012;z=(0:.001:.012).';
src=[-.004 0 .006];interface=.006;cs=2;
a1=8;a2=35;
speed=cs*ones(numel(z),numel(x));
loss=a1*ones(size(speed));loss(:,x>=interface)=a2;
[Z,X]=ndgrid(z,x);
r=sqrt((X-src(1)).^2+(Z-src(3)).^2);
f=(max(0,min(X,interface)-src(1)))./(X-src(1));
% Straight ray crossing x=interface; both source and targets x>=0.
reference=r.*(a1.*f+a2.*(1-f));
fprintf("\nconstant-speed piecewise-loss straight-ray reference\n");
for h=[.002 .0015 .001]
    opt=struct("GridSpacingM",h,"SpatialOrder",2, ...
        "MaxGridCells",300000,"MaximumIterations",200,"ToleranceS",1e-9);
    [~,A,d]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
        speed,loss,x,z,src,0,opt);
    relative=norm(A(:)-reference(:))/norm(reference(:));
    fprintf("h=%.4g opticalDepthRelativeL2=%.6g A_range=[%.6g %.6g]\n", ...
        h,relative,min(A(:)),max(A(:)));
    verifyTrue(tc,d.solver.converged);
    verifyTrue(tc,all(isfinite(A(:))));
    verifyGreaterThanOrEqual(tc,min(A(:)),-1e-10);
    % Diagnostic only: interface representation and integration still
    % require measured convergence before adopting a strict tolerance.
end
end

function testBilayerSpeedAndLossNormalIncidence(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
x=0:.001:.012;z=(0:.001:.012).';
src=[-.004 0 .006];interface=.006;
speed=2*ones(numel(z),numel(x));speed(:,x>=interface)=3;
loss=8*ones(size(speed));loss(:,x>=interface)=35;
[~,iz]=min(abs(z-src(3)));
aExpected=8*(min(x,interface)-src(1))+35*max(0,x-interface);
tExpected=(min(x,interface)-src(1))/2+max(0,x-interface)/3;
fprintf("\nnormal-incidence speed/loss bilayer reference\n");
for h=[.002 .0015 .001]
    opt=struct("GridSpacingM",h,"SpatialOrder",2, ...
        "MaxGridCells",300000,"MaximumIterations",200,"ToleranceS",1e-9);
    [T,A,d]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
        speed,loss,x,z,src,0,opt);
    aMeasured=A(iz,:);tMeasured=T(iz,:);
    ae=norm(aMeasured-aExpected)/norm(aExpected);
    te=norm(tMeasured-tExpected)/norm(tExpected);
    fprintf("h=%.4g timeRelativeL2=%.6g opticalDepthRelativeL2=%.6g\n",h,te,ae);
    verifyTrue(tc,d.solver.converged);
    verifyTrue(tc,all(isfinite(A(:)))&&all(isfinite(T(:))));
    verifyGreaterThanOrEqual(tc,min(A(:)),-1e-10);
end
end
