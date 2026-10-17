function tests=test_swsynth_external_offplane_source_v2
tests=functiontests(localfunctions);
end

function testExternalAndOffplaneHomogeneous(tc)
addpath(fullfile(repoRoot(),"src"));
x=0:.002:.012;z=(0:.002:.012).';
speed=2*ones(numel(z),numel(x));
loss=4*ones(size(speed));
opts=struct("GridSpacingM",.002,"MaxGridCells",100000);
for source=[-.004 0 .006;-.004 .006 .006].'
    src=source.';
    [T,depth,D]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
        speed,loss,x,z,src,0,opts);
    verifySize(tc,T,size(speed));
    verifyTrue(tc,all(isfinite(T(:))));
    verifyTrue(tc,all(depth(:)>=0));
    verifyTrue(tc,D.solver.converged);
    [Z,X]=ndgrid(z,x);
    exact=hypot(hypot(X-src(1),src(2)),Z-src(3))/2;
    verifyLessThan(tc,median(abs(T(:)-exact(:))),.0015);
end
end

function testOffplaneExampleConfiguration(tc)
addpath(fullfile(repoRoot(),"src"));
p=fullfile(repoRoot(),"examples","swsynth","v2", ...
    "08_shear_attenuation", ...
    "point_source_offplane_bilayer_kelvin_voigt_projected3d.json");
c=jsondecode(fileread(p));
[~,meta]=swsynth.io.resolveConfigV2(c);
verifyTrue(tc,meta.valid);
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
