function tests=test_swsynth_heterogeneous_attenuation_v2
tests=functiontests(localfunctions);
end

function testMapsAndDryRuns(tc)
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
folder=fullfile(root,"examples","swsynth","v2","08_shear_attenuation");
for name=["bilayer_kelvin_voigt_projected3d.json", ...
        "inclusion_kelvin_voigt_projected3d.json"]
    cfg=jsondecode(fileread(fullfile(folder,name)));
    [scenario,meta]=swsynth.io.resolveConfigV2(cfg);
    verifyTrue(tc,meta.valid);
    gridRequest=scenario.domain;
    gridRequest.geometry=scenario.geometry;
    grid=swsynth.domain.buildGrid(gridRequest);
    material=swsynth.medium.buildMaps(grid,scenario.medium);
    maps=swsynth.medium.viscoelastic.buildMaps( ...
        swsynth.medium.validate(scenario.medium,scenario.geometry), ...
        material,scenario.harmonic.frequency_hz);
    verifySize(tc,maps.phase_speed,size(material.cs_map_zx));
    verifyGreaterThan(tc,min(maps.attenuation_np_m(:)),0);
    verifyGreaterThan(tc,numel(unique(maps.phase_speed)),1);
end
end

function testConstantAlphaStraightRay(tc)
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
x=0:.001:.02;
z=(0:.001:.01).';
[~,X]=ndgrid(z,x);
T=X/2;
alpha=5*ones(size(T));
opt=swsynth.propagation.attenuation.integrateEikonal2D(T,alpha,x,z);
verifyLessThan(tc,max(abs(opt(:,end)-.1)),.012);
verifyLessThan(tc,max(abs(opt(:,1))),.003);
end

function testHeterogeneousSynthesis(tc)
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
p=fullfile(root,"examples","swsynth","v2","08_shear_attenuation", ...
    "bilayer_kelvin_voigt_projected3d.json");
cfg=jsondecode(fileread(p));
[scenario,~]=swsynth.io.resolveConfigV2(cfg);
out=swsynth.propagation.synthesize(scenario);
verifyTrue(tc,all(isfinite(out.U_xyz(:))));
verifyGreaterThan(tc,max(abs(out.U_xyz(:))),0);
end
