function tests=test_eikonal_spatial_order_comparison
% Diagnostic A/B benchmark; prints errors, does not assert superiority.
tests=functiontests(localfunctions);
end

function testHomogeneousExternalAndOffplane(testCase)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
x=0:.002:.012;z=(0:.002:.012).';
cs=2;
velocity=cs*ones(numel(z),numel(x));
loss=zeros(size(velocity));
sources=[-.004 0 .006;-.004 .006 .006];
hs=[.003 .002 .0015];
[Z,X]=ndgrid(z,x);
for is=1:size(sources,1)
    source=sources(is,:);
    reference=sqrt((X-source(1)).^2+source(2)^2+ ...
        (Z-source(3)).^2)/cs;
    fprintf("\nsource=%s\n",mat2str(source));
    for i=1:numel(hs)
        errors=zeros(1,2);
        for order=1:2
            options=struct("GridSpacingM",hs(i), ...
                "MaxGridCells",200000,"MaximumIterations",200, ...
                "ToleranceS",1e-9,"SpatialOrder",order);
            tic
            [T,~,D]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
                velocity,loss,x,z,source,0,options);
            elapsed=toc;
            errors(order)=norm(T(:)-reference(:))/norm(reference(:));
            verifyTrue(testCase,D.solver.converged);
            verifyTrue(testCase,all(isfinite(T(:))));
            fprintf(" h=%.4g order=%d relativeL2=%.8g elapsed_s=%.3f\n", ...
                hs(i),order,errors(order),elapsed);
        end
        fprintf(" h=%.4g improvement_percent=%.3f\n", ...
            hs(i),100*(errors(1)-errors(2))/errors(1));
    end
end
end
