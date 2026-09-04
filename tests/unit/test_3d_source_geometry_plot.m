function tests = test_3d_source_geometry_plot
%TEST_3D_SOURCE_GEOMETRY_PLOT Smoke-test 3D source visualization.
tests = functiontests(localfunctions);
end

function setupOnce(~)
addpath(fullfile(findRepositoryRoot(), "src"));
end

function testDirectionalSourcePlot(testCase)
cfg = resolveConfiguration("homogeneous_directional_cli.json");
handles = kwsim.viz.plotSourceGeometry3D(cfg, FigureVisible="off", ShowContactNodes=true);
cleanup = onCleanup(@() closeIfValid(handles.figure));
verifyTrue(testCase, isgraphics(handles.figure, "figure"));
verifyEqual(testCase, numel(handles.axes), 4);
verifyEqual(testCase, handles.metrics.source_count, 1);
verifyEqual(testCase, nnz(handles.in_plane), 1);
clear cleanup
end

function testHighCountSourcePlot(testCase)
cfg = resolveConfiguration("homogeneous_generated_angular_n128_p8.json");
handles = kwsim.viz.plotSourceGeometry3D(cfg, FigureVisible="off", ShowContactNodes=false);
cleanup = onCleanup(@() closeIfValid(handles.figure));
verifyTrue(testCase, isgraphics(handles.figure, "figure"));
verifyEqual(testCase, numel(handles.axes), 4);
verifyEqual(testCase, handles.metrics.source_count, 128);
verifyEqual(testCase, nnz(handles.in_plane), 8);
verifyEqual(testCase, nnz(handles.out_of_plane), 120);
clear cleanup
end

function cfg = resolveConfiguration(fileName)
file = fullfile(findRepositoryRoot(), "configs", "kwsim", "three_d", fileName);
outcome = kwsim.cli.runConfig(file, DryRun=true);
cfg = outcome.config_resolved;
end

function closeIfValid(fig)
if isgraphics(fig, "figure")
    close(fig);
end
end

function root = findRepositoryRoot()
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
