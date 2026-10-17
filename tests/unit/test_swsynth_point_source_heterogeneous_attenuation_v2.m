function tests=test_swsynth_point_source_heterogeneous_attenuation_v2
tests=functiontests(localfunctions);
end

function testSourceEikonalHomogeneousTravelTimes(tc)
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
x=0:.0003:.024;z=(0:.0003:.024).';
cs=2*ones(numel(z),numel(x));
src=[.006,0,.012];
[T,info]=swsynth.phase.eikonal.projected3d.computePointSourceTravelTime( ...
    cs,x,z,src);
verifyTrue(tc,info.converged);
verifyLessThan(tc,abs(T(41,61)-hypot(x(61)-src(1),z(41)-src(3))/2),.0006);
end

function testPointSourceBilayerEndToEnd(tc)
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
p=fullfile(root,"examples","swsynth","v2","08_shear_attenuation", ...
    "point_source_bilayer_kelvin_voigt_projected3d.json");
cfg=jsondecode(fileread(p));
[scenario,meta]=swsynth.io.resolveConfigV2(cfg);
verifyTrue(tc,meta.valid);
out=swsynth.propagation.synthesize(scenario);
verifyTrue(tc,all(isfinite(out.U_xyz(:))));
verifyGreaterThan(tc,max(abs(out.U_xyz(:))),0);
end
