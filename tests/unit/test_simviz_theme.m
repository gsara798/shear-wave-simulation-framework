function tests = test_simviz_theme
tests = functiontests(localfunctions);
end

function testDivergingMapUsesPaperBlueAndRed(testCase)
addSourcePath();

theme = simviz.paperTheme();
map = simviz.divergingColormap(257);

verifyEqual(testCase, size(map), [257, 3]);
verifyEqual(testCase, map(1, :), theme.rgb.blue.main, "AbsTol", 1e-12);
verifyEqual(testCase, map(end, :), theme.rgb.red.main, "AbsTol", 1e-12);
verifyEqual(testCase, map(129, :), [1, 1, 1], "AbsTol", 1e-12);
end

function testSequentialMapUsesThemeColor(testCase)
addSourcePath();

theme = simviz.paperTheme();
map = simviz.sequentialColormap("teal", 64);

verifyEqual(testCase, map(1, :), [1, 1, 1], "AbsTol", 1e-12);
verifyEqual(testCase, map(end, :), theme.rgb.teal.main, "AbsTol", 1e-12);
end

function testPurpleYellowMapsUseMainPaletteColors(testCase)
addSourcePath();

theme = simviz.paperTheme();
sequential = simviz.sequentialColormap("blue", 64, EndRole="yellow");
diverging = simviz.divergingColormap(257, ...
    NegativeRole="blue", PositiveRole="yellow");

verifyEqual(testCase, sequential(1, :), theme.rgb.blue.main, "AbsTol", 1e-12);
verifyEqual(testCase, sequential(end, :), theme.rgb.yellow.main, "AbsTol", 1e-12);
verifyEqual(testCase, diverging(1, :), theme.rgb.blue.main, "AbsTol", 1e-12);
verifyEqual(testCase, diverging(129, :), [1, 1, 1], "AbsTol", 1e-12);
verifyEqual(testCase, diverging(end, :), theme.rgb.yellow.main, "AbsTol", 1e-12);
end

function addSourcePath()
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root, "src"));
end
