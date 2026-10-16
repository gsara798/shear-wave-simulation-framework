function tests=test_example_swsynth_point_sources_v2
tests=functiontests(localfunctions);
end

function testAllConfigsPassDryRun(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
folder=fullfile(root,"examples","swsynth","v2","02_point_sources");
files=["single_point_projected3d.json", ...
    "single_point_projected3d_force_x.json", ...
    "two_coherent_points_projected3d.json", ...
    "two_out_of_phase_points_projected3d.json", ...
    "two_force_orientations_projected3d.json", ...
    "random_excitation_points_projected3d.json", ...
    "coherent_line_aperture_projected3d.json", ...
    "single_point_volumetric3d.json"];
for file=files
    out=simrunner.runConfig(fullfile(folder,file),DryRun=true);
    verifyTrue(tc,logical(out.validation.valid),char(file));
    verifyEqual(tc,string(out.validation.model),"spherical_wave");
end
end

function testCoherentVsOutOfPhaseDrive(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
folder=fullfile(root,"examples","swsynth","v2","02_point_sources");
a=jsondecode(fileread(fullfile(folder,"two_coherent_points_projected3d.json")));
b=jsondecode(fileread(fullfile(folder,"two_out_of_phase_points_projected3d.json")));
verifyEqual(tc,double(a.sources.positions.position_xyz_m), ...
    double(b.sources.positions.position_xyz_m));
verifyEqual(tc,double(a.sources.excitation.phase_rad(:)),[0;0]);
verifyEqual(tc,double(b.sources.excitation.phase_rad(:)),[0;pi],"AbsTol",1e-12);
end

function testCoherentLineApertureNodes(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
file=fullfile(root,"examples","swsynth","v2","02_point_sources", ...
    "coherent_line_aperture_projected3d.json");
config=jsondecode(fileread(file));
[scenario,~]=swsynth.io.resolveConfigV2(config);
request=scenario.sources;
request.geometry=scenario.geometry;
request.observation_y_m=0;
bundle=swsynth.sources.prepare(request);
verifyEqual(tc,bundle.count,1);
verifyEqual(tc,bundle.aperture.node_count,7);
verifyEqual(tc,sum(bundle.aperture.node_weight),1,"AbsTol",1e-12);
end

function testSingleSourceXForceAndZObservation(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
folder=fullfile(root,"examples","swsynth","v2","02_point_sources");
original=jsondecode(fileread(fullfile(folder,"single_point_projected3d.json")));
variant=jsondecode(fileread(fullfile(folder,"single_point_projected3d_force_x.json")));
verifyEqual(tc,double(variant.sources.excitation.force_direction_xyz(:)),[1;0;0]);
verifyEqual(tc,double(variant.measurement.axis_xyz(:)),[0;0;1]);
verifyEqual(tc,double(variant.measurement.axis_xyz(:)), ...
    double(original.measurement.axis_xyz(:)));
verifyEqual(tc,double(variant.sources.positions.position_xyz_m(:)), ...
    double(original.sources.positions.position_xyz_m(:)));
verifyEqual(tc,string(variant.geometry),"projected3d");
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
