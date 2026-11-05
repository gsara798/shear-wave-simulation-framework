function tests=test_swsynth_eikonal_cache_integration_v2
tests=functiontests(localfunctions);
end

function setupOnce(tc)
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
tc.TestData.root=root;
end

function testIntegrationAndFrequencyReuse(tc)
file=fullfile(tc.TestData.root,"examples","swsynth","v2", ...
    "04_heterogeneous_media", ...
    "single_source_elastic_inclusion_x_projected3d.json");
config=jsondecode(fileread(file));
[scenario,~]=swsynth.io.resolveConfigV2(config);
scenario.execution=struct("parallel",false);
% Same canonical observation dx: cached and direct must agree numerically.
direct=swsynth.propagation.synthesize(scenario);
dir=string(tempname);clean=onCleanup(@()removeFolder(dir));
scenario.propagation.solver_options.CacheDirectory=dir;
scenario.propagation.solver_options.CacheReferenceSpacingM=.0002;
cached=swsynth.propagation.synthesize(scenario);
verifyTrue(tc,isfile(fullfile(dir,"source_001.mat")));
verifyEqual(tc,cached.U_xyz,direct.U_xyz,"AbsTol",1e-9);
% Next frequency and coarser observation sampling reuse the source map.
scenario.harmonic.frequency_hz=400;
scenario.domain.dx_m=.0004;
scenario.domain.dz_m=.0004;
second=swsynth.propagation.synthesize(scenario);
repeat=swsynth.propagation.synthesize(scenario);
verifyEqual(tc,second.U_xyz,repeat.U_xyz,"AbsTol",0);
verifyEqual(tc,size(second.U_xyz,1),61);
verifyEqual(tc,size(second.U_xyz,2),61);
end

function removeFolder(dir)
if isfolder(dir),rmdir(dir,"s");end
end
