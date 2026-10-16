function tests=test_example_swsynth_plane_waves_v2
tests=functiontests(localfunctions);
end

function testFivePublicConfigsDryRun(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
folder=fullfile(root,"examples","swsynth","v2","01_plane_waves");
files=["single_directional_2d.json","counterpropagating_2d.json", ...
    "multidirectional_2d.json","oblique_projected3d.json", ...
    "volumetric3d_oblique.json"];
for name=files
    out=simrunner.runConfig(fullfile(folder,name),DryRun=true);
    verifyTrue(tc,out.validation.valid,char(name));
    verifyEqual(tc,string(out.validation.model),"plane_wave");
    verifyEqual(tc,double(out.validation.frequency_hz),500);
end
end

function testSingleWaveWavenumberAndProjectedGeometry(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
folder=fullfile(root,"examples","swsynth","v2","01_plane_waves");
single=jsondecode(fileread(fullfile(folder,"single_directional_2d.json")));
[scenario,~]=swsynth.io.resolveConfigV2(single);
r=swsynth.propagation.synthesize(scenario);
verifyEqual(tc,string(r.geometry),"2d");
verifyEqual(tc,r.excitation.frequency_hz,500);
verifyEqual(tc,double(r.domain.x_m(end)-r.domain.x_m(1)),.024,"AbsTol",1e-12);
projected=jsondecode(fileread(fullfile(folder,"oblique_projected3d.json")));
[p,~]=swsynth.io.resolveConfigV2(projected);
verifyEqual(tc,string(p.geometry),"projected3d");
verifyGreaterThan(tc,abs(p.incidence.direction_xyz(2)),0);
end

function testVolumetricShearIsTransverse(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
file=fullfile(root,"examples","swsynth","v2","01_plane_waves", ...
    "volumetric3d_oblique.json");
config=jsondecode(fileread(file));
[scenario,~]=swsynth.io.resolveConfigV2(config);
verifyEqual(tc,string(scenario.geometry),"volumetric3d");
direction=double(scenario.incidence.direction_xyz);
polarization=double(scenario.incidence.polarization.explicit_polarization_xyz);
verifyEqual(tc,dot(direction,polarization),0,"AbsTol",1e-12);
result=swsynth.propagation.synthesize(scenario);
verifyEqual(tc,string(result.geometry),"volumetric3d");
verifyEqual(tc,result.domain.spatial_size,[41 41 41]);
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
