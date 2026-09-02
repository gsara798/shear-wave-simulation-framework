function tests = test_simviz_theme
tests = functiontests(localfunctions);
end

function testDivergingMapUsesPaperBlueAndRed(testCase)
theme=simviz.paperTheme();
map=simviz.divergingColormap(257);
verifySize(testCase,map,[257 3]);
verifyEqual(testCase,map(1,:),theme.rgb.blue.main,AbsTol=1e-12);
verifyEqual(testCase,map(end,:),theme.rgb.red.main,AbsTol=1e-12);
verifyEqual(testCase,map(129,:),[1 1 1],AbsTol=1e-12);
end

function testSequentialMapUsesThemeColor(testCase)
theme=simviz.paperTheme();
map=simviz.sequentialColormap("teal",64);
verifyEqual(testCase,map(1,:),[1 1 1],AbsTol=1e-12);
verifyEqual(testCase,map(end,:),theme.rgb.teal.main,AbsTol=1e-12);
end
