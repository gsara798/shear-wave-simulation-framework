function tests=test_run_simulation_parallel_options_v2
tests=functiontests(localfunctions);
end

function testOverrideDryRun(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
file=fullfile(root,"examples","swsynth","v2", ...
    "02_point_sources","random_excitation_points_projected3d.json");
out=simrunner.runConfig(file,DryRun=true,Parallel=true,NumWorkers=2);
verifyTrue(tc,out.config_resolved.execution.parallel);
verifyEqual(tc,out.config_resolved.execution.num_workers,2);
original=jsondecode(fileread(file));
verifyFalse(tc,isfield(original,"execution"));
end

function testInvalidWorkerCount(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
file=fullfile(root,"examples","swsynth","v2", ...
    "02_point_sources","random_excitation_points_projected3d.json");
verifyError(tc,@()simrunner.runConfig(file,DryRun=true, ...
    Parallel=true,NumWorkers=0),"simrunner:InvalidWorkerCount");
end

function testExplicitSerialOverride(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
file=fullfile(root,"examples","swsynth","v2", ...
    "05_advanced_volumetric3d","eight_random_point_sources.json");
out=simrunner.runConfig(file,DryRun=true,Parallel=false);
verifyFalse(tc,out.config_resolved.execution.parallel);
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
