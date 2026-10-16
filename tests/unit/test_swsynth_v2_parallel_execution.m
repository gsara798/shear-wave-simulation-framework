function tests=test_swsynth_v2_parallel_execution
tests=functiontests(localfunctions);
end

function testSerialDefaultAndExplicitSerialAgree(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
p=fullfile(root,"examples","swsynth","v2", ...
    "03_wavefield_regimes","diffuse_projected3d.json");
cfg=jsondecode(fileread(p));
[s,~]=swsynth.io.resolveConfigV2(cfg);
original=rng;
cleanup=onCleanup(@()rng(original)); %#ok<NASGU>
rng(cfg.seed,"twister");
a=swsynth.propagation.synthesize(s);
s.execution=struct("parallel",false,"num_workers",2);
rng(cfg.seed,"twister");
b=swsynth.propagation.synthesize(s);
verifyEqual(tc,a.U_xyz,b.U_xyz);
end

function testInvalidWorkerCount(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
p=fullfile(root,"examples","swsynth","v2", ...
    "03_wavefield_regimes","directional_2d.json");
cfg=jsondecode(fileread(p));
[s,~]=swsynth.io.resolveConfigV2(cfg);
s.execution=struct("parallel",true,"num_workers",0);
verifyError(tc,@()swsynth.propagation.synthesize(s),"swsynth:InvalidExecution");
end

function testParallelEqualsSerialWhenToolboxAvailable(tc)
if exist("parpool","file")~=2
    return
end
root=repoRoot();
addpath(fullfile(root,"src"));
p=fullfile(root,"examples","swsynth","v2", ...
    "03_wavefield_regimes","limited_aperture_2d.json");
cfg=jsondecode(fileread(p));
[s,~]=swsynth.io.resolveConfigV2(cfg);
s.execution=struct("parallel",false,"num_workers",2);
serial=swsynth.propagation.synthesize(s);
s.execution.parallel=true;
parallel=swsynth.propagation.synthesize(s);
verifyEqual(tc,parallel.U_xyz,serial.U_xyz,"AbsTol",1e-12);
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
