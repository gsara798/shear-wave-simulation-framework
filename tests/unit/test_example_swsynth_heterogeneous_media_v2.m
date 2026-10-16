function tests=test_example_swsynth_heterogeneous_media_v2
tests=functiontests(localfunctions);
end

function testAllHeterogeneousConfigurations(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
folder=fullfile(root,"examples","swsynth","v2","04_heterogeneous_media");
names=["circle_inclusion_projected3d.json", ...
    "bilayer_projected3d.json", ...
    "multiple_inclusions_projected3d.json", ...
    "s_curve_projected3d.json", ...
    "sphere_volumetric3d.json"];
for name=names
    path=fullfile(folder,name);
    output=simrunner.runConfig(path,DryRun=true);
    verifyTrue(tc,logical(output.validation.valid),char(name));
    cfg=jsondecode(fileread(path));
    verifyEqual(tc,string(cfg.propagation.phase_method),"eikonal");
    [scenario,~]=swsynth.io.resolveConfigV2(cfg);
    req=scenario.domain;
    req.geometry=scenario.geometry;
    grid=swsynth.domain.buildGrid(req);
    maps=swsynth.medium.buildMaps(grid,scenario.medium);
    if string(scenario.geometry)=="volumetric3d"
        cs=maps.cs_map_zyx;
    else
        cs=maps.cs_map_zx;
    end
    verifyGreaterThan(tc,max(cs(:)),2,char(name));
    verifyTrue(tc,any(abs(cs(:)-2)<1e-12),char(name));
end
end

function testBilayerOrientation(tc)
root=repoRoot();
cfg=jsondecode(fileread(fullfile(root,"examples","swsynth", ...
    "v2","04_heterogeneous_media","bilayer_projected3d.json")));
[scenario,~]=swsynth.io.resolveConfigV2(cfg);
req=scenario.domain;
req.geometry=scenario.geometry;
grid=swsynth.domain.buildGrid(req);
maps=swsynth.medium.buildMaps(grid,scenario.medium);
verifyEqual(tc,maps.cs_map_zx(:,1),2*ones(size(maps.cs_map_zx,1),1));
verifyEqual(tc,maps.cs_map_zx(:,end),3*ones(size(maps.cs_map_zx,1),1));
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
