function tests=test_eikonal_second_order_source_alignment
tests=functiontests(localfunctions);
end
function testAlignmentConvergence(tc)
root=fileparts(fileparts(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
addpath(fullfile(root,"src"));
x=0:.002:.012; z=(0:.002:.012).';
cs=2; speed=cs*ones(numel(z),numel(x)); loss=zeros(size(speed));
% Both source locations external to FOV. Alignment is relative to the
% extended computational grid; actual offset is reported by diagnostics.
sources=[-.004 0 .006;-.00437 .00563 .00641];
hs=[.003 .002 .0015 .001];
[Z,X]=ndgrid(z,x);
for k=1:size(sources,1)
    src=sources(k,:);
    tref=sqrt((X-src(1)).^2+src(2)^2+(Z-src(3)).^2)/cs;
    fprintf("\nsource=%s\n",mat2str(src));
    for order=1:2
        e=zeros(size(hs));
        for j=1:numel(hs)
            opts=struct("SpatialOrder",order,"GridSpacingM",hs(j), ...
                "MaxGridCells",500000,"MaximumIterations",200, ...
                "ToleranceS",1e-9,"ReturnVolumeDiagnostics",true);
            [t,~,d]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
                speed,loss,x,z,src,0,opts);
            e(j)=norm(t(:)-tref(:))/norm(tref(:));
            v=d.volume;
            offsets=[min(abs(v.x_m-src(1))),min(abs(v.y_m-src(2))), ...
                min(abs(v.z_m-src(3)))];
            fprintf("order=%d h=%.4g error=%.7g sourceOffset_m=%s\n", ...
                order,hs(j),e(j),mat2str(offsets,3));
            verifyTrue(tc,isfinite(e(j)));
            verifyTrue(tc,d.solver.converged);
        end
        fprintf("order=%d errors=%s\n",order,mat2str(e,5));
    end
end
end
