function tests=test_example_swsynth_wavefield_regimes_v2
tests=functiontests(localfunctions);
end

function testRegimeConfigsDryRun(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
folder=fullfile(root,"examples","swsynth","v2","03_wavefield_regimes");
names=["directional_2d.json","counterpropagating_2d.json", ...
    "limited_aperture_2d.json","diffuse_2d.json", ...
    "limited_aperture_projected3d.json","diffuse_projected3d.json", ...
    "diffuse_volumetric3d.json"];
for name=names
    file=fullfile(folder,name);
    out=simrunner.runConfig(file,DryRun=true);
    verifyTrue(tc,out.validation.valid,char(name));
    cfg=jsondecode(fileread(file));
    [scenario,~]=swsynth.io.resolveConfigV2(cfg);
    D=double(scenario.incidence.direction_xyz);
    verifyEqual(tc,size(D,1),double(cfg.incidence.sampling.count));
    verifyEqual(tc,vecnorm(D,2,2),ones(size(D,1),1),"AbsTol",1e-10);
    verifyEqual(tc,sum(abs(D(:,2))<1e-12), ...
        double(cfg.incidence.sampling.count_in_plane));
end
end

function testFibonacciIsReproducible(tc)
a=struct("count",64,"count_in_plane",8, ...
    "method","fibonacci","support","full_sphere");
D1=swsynth.incidence.sampleDirections(a,"projected3d");
D2=swsynth.incidence.sampleDirections(a,"projected3d");
verifyEqual(tc,D1,D2);
verifyEqual(tc,sum(abs(D1(:,2))<1e-12),8);
end

function testInvalidPlanarQuotaRejected(tc)
s=struct("count",8,"count_in_plane",9, ...
    "method","fibonacci","support","full_sphere");
verifyError(tc,@()swsynth.incidence.sampleDirections(s,"projected3d"), ...
    "swsynth:InvalidDirectionSampling");
end

function testRandomPhasesReproducibleAndRngUntouched(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
file=fullfile(root,"examples","swsynth","v2", ...
    "03_wavefield_regimes","diffuse_projected3d.json");
cfg=jsondecode(fileread(file));
prior=rng;
[a,~]=swsynth.io.resolveConfigV2(cfg);
verifyEqual(tc,rng,prior);
[b,~]=swsynth.io.resolveConfigV2(cfg);
verifyEqual(tc,a.incidence.phase_rad,b.incidence.phase_rad);
verifyEqual(tc,numel(a.incidence.phase_rad),cfg.incidence.sampling.count);
verifyGreaterThan(tc,numel(unique(a.incidence.phase_rad)),1);
cfg.seed=cfg.seed+1;
[c,~]=swsynth.io.resolveConfigV2(cfg);
verifyNotEqual(tc,a.incidence.phase_rad,c.incidence.phase_rad);
cfg=rmfield(cfg,"seed");
verifyError(tc,@()swsynth.io.resolveConfigV2(cfg),"swsynth:V2SeedRequired");
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
