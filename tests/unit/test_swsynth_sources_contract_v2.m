function tests=test_swsynth_sources_contract_v2
tests=functiontests(localfunctions);
end

function testPlanarExplicitPositions(testCase)
r=struct("geometry","planar2d","count",2, ...
    "observation_y_m",.002, ...
    "position_xyz_m",[.01 .002 .02;.02 .002 .03]);
p=swsynth.sources.positions.generate(r);
verifyEqual(testCase,p,r.position_xyz_m);
end

function testPlanarRejectsOutOfPlane(testCase)
r=struct("geometry","planar2d","count",1, ...
    "position_xyz_m",[.01 .002 .02]);
verifyError(testCase,@() swsynth.sources.positions.generate(r), ...
    "swsynth:PlanarSourceOutsidePlane");
end

function testProjectedAllowsOutOfPlane(testCase)
r=struct("geometry","projected3d","count",1, ...
    "position_xyz_m",[.01 .002 .02]);
verifyEqual(testCase,swsynth.sources.positions.generate(r), ...
    r.position_xyz_m);
end

function testSeededPositionsIndependentOfGlobalRng(testCase)
r=struct("geometry","volumetric3d","count",2, ...
    "center_xyz_m",[0 0 0],"radius_range_m",[.02 .03], ...
    "direction_xyz",[1 0 0;0 1 0]);
r.stream=RandStream("mt19937ar","Seed",101);
a=swsynth.sources.positions.generate(r);
rng(75);
r.stream=RandStream("mt19937ar","Seed",101);
b=swsynth.sources.positions.generate(r);
verifyEqual(testCase,a,b);
verifyEqual(testCase,vecnorm(a,2,2)>=.02,true(2,1));
end

function testMultipleComponentsOneSource(testCase)
bundle=struct();
bundle.sources=struct("position_xyz_m",[.01 .002 .02]);
bundle.components=struct("direction_xyz",[1 0 0;0 0 1], ...
    "source_id",[1;1]);
actual=swsynth.sources.validate(bundle,"projected3d");
verifyEqual(testCase,actual.components.source_id,[1;1]);
end

function testMappingRequiresPhysicalSource(testCase)
bundle=struct();
bundle.sources=struct("position_xyz_m",[]);
bundle.components=struct("direction_xyz",[1 0 0], ...
    "source_id",1);
verifyError(testCase,@() swsynth.sources.validate(bundle,"projected3d"), ...
    "swsynth:InvalidSourceMapping");
end
