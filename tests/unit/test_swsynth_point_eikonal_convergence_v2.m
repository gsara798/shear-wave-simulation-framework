function tests=test_swsynth_point_eikonal_convergence_v2
tests=functiontests(localfunctions);
end

function setupOnce(tc)
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
folder=fullfile(root,"examples","swsynth","v2", ...
    "04_heterogeneous_media");
addpath(folder);
end

function testReadOnlyPreflight(tc)
out=string(tempname);
R=comparePointEikonalConvergence(OutputDirectory=out);
verifyFalse(tc,R.executed);
verifyEqual(tc,size(R.grid_points),[2 3]);
verifyTrue(tc,all(R.grid_points(:)>0));
verifyTrue(tc,all(R.grid_points(:)<=300000));
verifyFalse(tc,isfolder(out));
end

function testRejectsExistingOutputWithoutOverwriting(tc)
out=string(tempname);
mkdir(out);
clean=onCleanup(@()rmdir(out,"s"));
verifyError(tc,@()comparePointEikonalConvergence( ...
    OutputDirectory=out),"swsynth:ConvergenceImmutable");
end

function testRejectsUnexpectedSweep(tc)
verifyError(tc,@()comparePointEikonalConvergence( ...
    GridSpacingsM=[.001 .0005 .00025]), ...
    "swsynth:ConvergenceSweep");
end
