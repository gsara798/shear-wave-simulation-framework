function tests=test_swsynth_domain_build_grid_v2
tests=functiontests(localfunctions);
end

function testPlanarLengthSpacingMatchesLegacyAxes(testCase)
r=struct("geometry","2d","Lx_m",.02,"Lz_m",.03, ...
    "dx_m",.001,"dz_m",.002);
g=swsynth.domain.buildGrid(r);
verifyEqual(testCase,g.x_m,linspace(0,.02,21));
verifyEqual(testCase,g.z_m,linspace(0,.03,16));
verifyEqual(testCase,g.spatial_size,[16,21]);
verifyEqual(testCase,g.output_convention,"grid(z,x)");
verifyEqual(testCase,g.geometry,"2d");
verifyEqual(testCase,g.observation_y_m,0);
end

function testRoundingTracksRequestedAndActualSpacing(testCase)
r=struct("geometry","2d","Lx_m",.01,"Lz_m",.01, ...
    "dx_m",.003,"dz_m",.0025);
g=swsynth.domain.buildGrid(r);
verifyEqual(testCase,g.requested_dx_m,.003);
verifyEqual(testCase,g.dx_m,.01/3,"AbsTol",1e-14);
verifyEqual(testCase,g.x_m,linspace(0,.01,4));
verifyEqual(testCase,g.z_m,linspace(0,.01,5));
end

function testExplicitOffsetAxes(testCase)
r=struct("geometry","projected3d", ...
    "x_m",-.02:.01:0,"z_m",.005:.005:.02, ...
    "observation_y_m",.015);
g=swsynth.domain.buildGrid(r);
verifyEqual(testCase,g.x_m,r.x_m);
verifyEqual(testCase,g.z_m,r.z_m);
verifyEqual(testCase,g.observation_y_m,.015);
verifyEqual(testCase,g.spatial_size,[4 3]);
verifyEqual(testCase,g.geometry,"projected3d");
end

function testLengthSpacingTranslatedOrigin(testCase)
r=struct("geometry","2d","Lx_m",.01,"Lz_m",.02, ...
    "dx_m",.005,"dz_m",.01, ...
    "origin_xyz_m",[-.01 5 .02], ...
    "observation_y_m",.1);
g=swsynth.domain.buildGrid(r);
verifyEqual(testCase,g.x_m,[-.01 -.005 0],"AbsTol",1e-14);
verifyEqual(testCase,g.z_m,[.02 .03 .04],"AbsTol",1e-14);
verifyEqual(testCase,g.observation_y_m,.1);
end

function testProjected3DStillUsesTwoDimensionalGrid(testCase)
r=struct("geometry","projected3d","Lx_m",.02, ...
    "Lz_m",.02,"dx_m",.01,"dz_m",.01);
g=swsynth.domain.buildGrid(r);
verifyFalse(testCase,isfield(g,"y_m"));
verifyEqual(testCase,g.spatial_size,[3 3]);
end

function testVolumetricLegacyAxes(testCase)
r=struct("geometry","volumetric3d", ...
    "Lx_m",.005,"Ly_m",.003,"Lz_m",.004, ...
    "dx_m",.001,"dy_m",.001,"dz_m",.001);
g=swsynth.domain.buildGrid(r);
verifyEqual(testCase,g.x_m,linspace(0,.005,6));
verifyEqual(testCase,g.y_m,linspace(0,.003,4));
verifyEqual(testCase,g.z_m,linspace(0,.004,5));
verifyEqual(testCase,g.spatial_size,[5 4 6]);
verifyEqual(testCase,g.output_convention,"grid(z,y,x)");
end

function testExplicitVolumetricGrid(testCase)
r=struct("geometry","volumetric3d", ...
    "x_m",[0 .002 .004],"y_m",[.01 .02], ...
    "z_m",[-.003 0 .003]);
g=swsynth.domain.buildGrid(r);
verifyEqual(testCase,g.spatial_size,[3 2 3]);
verifyEqual(testCase,g.dy_m,.01,"AbsTol",1e-14);
end

function testRejectMixedCoordinateModes(testCase)
r=struct("geometry","2d","x_m",[0 1], ...
    "z_m",[0 1],"Lx_m",1,"dx_m",.1);
verifyError(testCase,@() swsynth.domain.buildGrid(r), ...
    "swsynth:AmbiguousDomainSpecification");
end

function testRejectNonuniformExplicitAxis(testCase)
r=struct("geometry","2d","x_m",[0 .001 .0025], ...
    "z_m",[0 .001]);
verifyError(testCase,@() swsynth.domain.buildGrid(r), ...
    "swsynth:NonuniformDomainGrid");
end

function testRejectNonmonotonicExplicitAxis(testCase)
r=struct("geometry","2d","x_m",[0 .001 0], ...
    "z_m",[0 .001]);
verifyError(testCase,@() swsynth.domain.buildGrid(r), ...
    "swsynth:InvalidDomainAxis");
end

function testRejectWrongDimensionY(testCase)
r=struct("geometry","2d","x_m",[0 .01], ...
    "y_m",[0 .01],"z_m",[0 .01]);
verifyError(testCase,@() swsynth.domain.buildGrid(r), ...
    "swsynth:InvalidDomainGeometry");
end

function testRejectBadDomainExtent(testCase)
r=struct("geometry","volumetric3d", ...
    "Lx_m",.01,"Ly_m",.01,"Lz_m",.01, ...
    "dx_m",.02,"dy_m",.002,"dz_m",.002);
verifyError(testCase,@() swsynth.domain.buildGrid(r), ...
    "swsynth:InvalidDomainExtent");
end

function testRejectAmbiguousOrigin(testCase)
r=struct("geometry","2d","x_m",[0 1], ...
    "z_m",[0 1],"origin_xyz_m",[1 0 0]);
verifyError(testCase,@() swsynth.domain.buildGrid(r), ...
    "swsynth:AmbiguousDomainSpecification");
end
