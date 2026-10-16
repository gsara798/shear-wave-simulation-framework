function tests=test_example_swsynth_advanced_volumetric3d_v2
tests=functiontests(localfunctions);
end

function testAllConfigsDryRun(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
folder=fullfile(root,"examples","swsynth","v2","05_advanced_volumetric3d");
names=["two_coherent_point_sources.json", ...
    "eight_random_point_sources.json", ...
    "diffuse_plane_waves_3d.json", ...
    "sphere_multi_incidence_eikonal.json", ...
    "two_spheres_eikonal.json"];
for name=names
    cfg=jsondecode(fileread(fullfile(folder,name)));
    verifyEqual(tc,string(cfg.geometry),"volumetric3d");
    out=simrunner.runConfig(fullfile(folder,name),DryRun=true);
    verifyTrue(tc,logical(out.validation.valid),char(name));
end
end

function testSourceCountsAndParallelOptions(tc)
root=repoRoot();
folder=fullfile(root,"examples","swsynth","v2","05_advanced_volumetric3d");
a=jsondecode(fileread(fullfile(folder,"two_coherent_point_sources.json")));
b=jsondecode(fileread(fullfile(folder,"eight_random_point_sources.json")));
verifyEqual(tc,a.sources.count,2);
verifyEqual(tc,b.sources.count,8);
verifyTrue(tc,b.execution.parallel);
verifyEqual(tc,b.execution.num_workers,4);
verifyEqual(tc,size(b.sources.positions.position_xyz_m),[8,3]);
end

function testHeterogeneousMaps(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
file=fullfile(root,"examples","swsynth","v2", ...
    "05_advanced_volumetric3d","two_spheres_eikonal.json");
cfg=jsondecode(fileread(file));
[s,~]=swsynth.io.resolveConfigV2(cfg);
g=s.domain;
g.geometry=s.geometry;
grid=swsynth.domain.buildGrid(g);
maps=swsynth.medium.buildMaps(grid,s.medium);
values=maps.cs_map_zyx(:);
verifyTrue(tc,any(values>2));
verifyTrue(tc,any(values<2));
verifyTrue(tc,any(abs(values-2)<1e-12));
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
