function tests = test_plot_harmonic_volume_slices
%TEST_PLOT_HARMONIC_VOLUME_SLICES Verify generic 3D slice visualization.

tests = functiontests(localfunctions);

end


function setupOnce(~)

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(root, 'src'));

end


function teardown(~)

close all force;

end


function testCreatesSixSliceAxes(testCase)

[x_m, y_m, z_m, volume_zyx] = syntheticVolume();

handles = kwsim.viz.plotHarmonicVolumeSlices( ...
    volume_zyx, ...
    x_m, y_m, z_m, ...
    FigureVisible="off");

verifyTrue(testCase, isgraphics(handles.figure));
verifySize(testCase, handles.axes, [2, 3]);
verifyTrue(testCase, all(isgraphics(handles.axes), "all"));
verifyTrue(testCase, all(isgraphics(handles.images), "all"));

verifyEqual(testCase, handles.indices.x, 4);
verifyEqual(testCase, handles.indices.y, 3);
verifyEqual(testCase, handles.indices.z, 5);

end


function testUsesRequestedIndices(testCase)

[x_m, y_m, z_m, volume_zyx] = syntheticVolume();

handles = kwsim.viz.plotHarmonicVolumeSlices( ...
    volume_zyx, ...
    x_m, y_m, z_m, ...
    XIndex=2, ...
    YIndex=4, ...
    ZIndex=7, ...
    FigureVisible="off");

verifyEqual(testCase, handles.indices.x, 2);
verifyEqual(testCase, handles.indices.y, 4);
verifyEqual(testCase, handles.indices.z, 7);

verifyEqual(testCase, ...
    handles.coordinates_m.x, ...
    x_m(2));

verifyEqual(testCase, ...
    handles.coordinates_m.y, ...
    y_m(4));

verifyEqual(testCase, ...
    handles.coordinates_m.z, ...
    z_m(7));

end


function testSupportsNormalizedAmplitude(testCase)

[x_m, y_m, z_m, volume_zyx] = syntheticVolume();

handles = kwsim.viz.plotHarmonicVolumeSlices( ...
    volume_zyx, ...
    x_m, y_m, z_m, ...
    AmplitudeScale="normalized", ...
    FigureVisible="off");

verifyEqual(testCase, ...
    handles.amplitude_scale, ...
    "normalized");

verifyEqual(testCase, ...
    handles.axes(1,1).CLim, ...
    [0, 1]);

end


function testSupportsDbAmplitude(testCase)

[x_m, y_m, z_m, volume_zyx] = syntheticVolume();

handles = kwsim.viz.plotHarmonicVolumeSlices( ...
    volume_zyx, ...
    x_m, y_m, z_m, ...
    AmplitudeScale="db", ...
    MinimumDb=-35, ...
    FigureVisible="off");

verifyEqual(testCase, ...
    handles.axes(1,1).CLim, ...
    [-35, 0]);

end


function testRejectsAxisSizeMismatch(testCase)

[x_m, y_m, z_m, volume_zyx] = syntheticVolume();

verifyError(testCase, ...
    @() kwsim.viz.plotHarmonicVolumeSlices( ...
        volume_zyx, ...
        x_m(1:end-1), ...
        y_m, ...
        z_m, ...
        FigureVisible="off"), ...
    "kwsim:InvalidHarmonicVolume");

end


function testRejectsInvalidSliceIndex(testCase)

[x_m, y_m, z_m, volume_zyx] = syntheticVolume();

verifyError(testCase, ...
    @() kwsim.viz.plotHarmonicVolumeSlices( ...
        volume_zyx, ...
        x_m, y_m, z_m, ...
        XIndex=100, ...
        FigureVisible="off"), ...
    "kwsim:InvalidSliceIndex");

end


function [x_m, y_m, z_m, volume_zyx] = syntheticVolume()

nx = 7;
ny = 5;
nz = 9;

x_m = (0:(nx - 1)) * 0.5e-3;
y_m = (0:(ny - 1)) * 0.6e-3;
z_m = (0:(nz - 1)) * 0.4e-3;

[z_grid, y_grid, x_grid] = ndgrid(z_m, y_m, x_m);

amplitude = ...
    1 + ...
    0.2*x_grid/max(x_m) + ...
    0.1*y_grid/max(y_m);

phase = ...
    2*pi*x_grid/(4e-3) + ...
    0.3*z_grid/max(z_m);

volume_zyx = amplitude .* exp(1i*phase);

end
