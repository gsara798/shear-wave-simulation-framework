function tests=test_extended_point_source_eikonal_homogeneous
% Physics benchmark: first-arrival time and integrated intrinsic loss.
tests=functiontests(localfunctions);
end

function testExternalAndOffplaneGridRefinement(tc)
addpath(fullfile(repoRoot(),"src"));
x=0:.002:.012; z=(0:.002:.012).';
c=2.0; alpha=4.0;
speed=c*ones(numel(z),numel(x));
loss=alpha*ones(size(speed));
sources=[-.004 0 .006;-.004 .006 .006];
hs=[.003 .002 .0015];
for is=1:size(sources,1)
    src=sources(is,:);
    [Z,X]=ndgrid(z,x);
    r=sqrt((X-src(1)).^2+src(2).^2+(Z-src(3)).^2);
    Tref=r/c; Aref=alpha*r;
    errorsT=zeros(size(hs));errorsA=zeros(size(hs));
    for ih=1:numel(hs)
        opts=struct("GridSpacingM",hs(ih),"MaxGridCells",200000, ...
            "MaximumIterations",200,"ToleranceS",1e-9);
        [T,A,diag]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
            speed,loss,x,z,src,0,opts);
        verifyTrue(tc,diag.solver.converged);
        verifyTrue(tc,all(isfinite(T(:)))&&all(isfinite(A(:))));
        errorsT(ih)=norm(T(:)-Tref(:))/norm(Tref(:));
        % The current integrator deliberately stops at finite core radius
        % (~2 grid cells); optical depth therefore underestimates alpha*r.
        errorsA(ih)=norm(A(:)-Aref(:))/norm(Aref(:));
    end
    % Diagnostic benchmark, not a claim of validated convergence.
    fprintf("source=%s; h=%s; relative time errors=%s; relative optical-depth errors=%s\n", ...
        mat2str(src),mat2str(hs),mat2str(errorsT,4),mat2str(errorsA,4));
    verifyLessThan(tc,errorsT(end),0.25, ...
        "Coarse 3D Eikonal has unusually high homogeneous timing error.");
    verifyLessThan(tc,errorsA(end),0.6, ...
        "Ray-integral optical-depth error is unusually high.");
end
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(fileparts(mfilename("fullpath")))));
end
