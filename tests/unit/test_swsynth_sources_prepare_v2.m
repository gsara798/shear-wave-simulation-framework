function tests=test_swsynth_sources_prepare_v2
tests=functiontests(localfunctions);
end

function testTwoPlanarSourcesPointAperture(testCase)
r=planarFixture();
bundle=swsynth.sources.prepare(r);
verifyEqual(testCase,bundle.count,2);
verifyEqual(testCase,bundle.geometry,"planar2d");
verifyEqual(testCase,bundle.sources.source_id,[1;2]);
verifyEqual(testCase,bundle.sources.position_xyz_m, ...
    [.01 0 .02;.03 0 .04]);
verifyEqual(testCase,bundle.sources.force_direction_xyz, ...
    [1 0 0;0 0 1]);
verifyEqual(testCase,bundle.sources.relative_amplitude,[.6;1.4]);
verifyEqual(testCase,bundle.sources.phase_rad,[0;pi]);
verifyEqual(testCase,bundle.aperture.node_count,2);
verifyEqual(testCase,bundle.aperture.node_source_id,[1;2]);
verifyEqual(testCase,bundle.aperture.node_weight,[1;1]);
verifyEqual(testCase,bundle.aperture.node_xyz_m, ...
    bundle.sources.position_xyz_m);
end

function testOneParentWithThreeCoherentNodes(testCase)
r=struct();
r.geometry="2d";
r.count=1;
r.positions=struct("method","explicit", ...
    "position_xyz_m",[.02 0 .03]);
r.excitation=struct("force_direction_xz",[1 0], ...
    "relative_amplitude",1,"phase_rad",0);
r.aperture=struct("model","line_segment", ...
    "span_m",.002,"axis_xyz",[1 0 0], ...
    "node_spacing_m",.001);
bundle=swsynth.sources.prepare(r);
verifyEqual(testCase,bundle.aperture.node_count_per_source,3);
verifyEqual(testCase,bundle.aperture.node_source_id,ones(3,1));
verifySize(testCase,bundle.aperture.node_source_id,[3 1]);
verifyEqual(testCase,bundle.aperture.node_weight,ones(3,1)/3, ...
    "AbsTol",1e-14);
verifyEqual(testCase,bundle.aperture.node_xyz_m, ...
    [.019 0 .03;.020 0 .03;.021 0 .03], ...
    "AbsTol",1e-14);
end

function testCoherentLineApertureForEachSource(testCase)
r=planarFixture();
r.aperture=struct("model","line_segment","span_m",.002, ...
    "axis_xyz",[1 0 0],"node_spacing_m",.001);
bundle=swsynth.sources.prepare(r);
verifyEqual(testCase,bundle.aperture.node_count_per_source,[3;3]);
verifyEqual(testCase,bundle.aperture.node_source_id,[1;1;1;2;2;2]);
verifyEqual(testCase,bundle.aperture.node_weight,ones(6,1)/3, ...
    "AbsTol",1e-14);
verifyEqual(testCase,bundle.aperture.node_xyz_m(1:3,:), ...
    [.009 0 .02;.010 0 .02;.011 0 .02],"AbsTol",1e-14);
verifyEqual(testCase,bundle.aperture.node_xyz_m(4:6,:), ...
    [.029 0 .04;.030 0 .04;.031 0 .04],"AbsTol",1e-14);
% Amplitude and phase remain at SOURCE level, not independent per node.
verifyEqual(testCase,numel(bundle.sources.phase_rad),2);
verifyEqual(testCase,numel(bundle.sources.relative_amplitude),2);
end

function testDifferentAperturePerSource(testCase)
r=planarFixture();
point=struct("model","point","span_m",0, ...
    "axis_xyz",[1 0 0],"node_spacing_m",.001);
line=struct("model","line_segment","span_m",.002, ...
    "axis_xyz",[0 0 1],"node_spacing_m",.001);
r.aperture=[point,line];
bundle=swsynth.sources.prepare(r);
verifyEqual(testCase,bundle.aperture.node_count_per_source,[1;3]);
verifyEqual(testCase,bundle.aperture.node_source_id,[1;2;2;2]);
verifyEqual(testCase,bundle.aperture.node_weight,[1;1/3;1/3;1/3], ...
    "AbsTol",1e-14);
end

function testProjectedSourcesAllowOffPlaneAperture(testCase)
r=planarFixture();
r.geometry="projected3d";
r.positions.position_xyz_m=[.01 .01 .02;.03 -.02 .04];
r.excitation=struct("force_direction_xyz",[0 1 0], ...
    "phase_policy","fixed","phase_rad",[0;pi]);
r.aperture=struct("model","line_segment","span_m",.002, ...
    "axis_xyz",[0 1 0],"node_spacing_m",.001);
bundle=swsynth.sources.prepare(r);
verifyEqual(testCase,bundle.sources.force_direction_xyz, ...
    repmat([0 1 0],2,1));
verifyEqual(testCase,bundle.aperture.node_xyz_m(1:3,2), ...
    [.009;.010;.011],"AbsTol",1e-14);
end

function testPlanarRejectsOutOfPlaneAperture(testCase)
r=planarFixture();
r.aperture=struct("model","line_segment","span_m",.002, ...
    "axis_xyz",[0 1 0],"node_spacing_m",.001);
verifyError(testCase,@() swsynth.sources.prepare(r), ...
    "swsynth:PlanarSourceOutsidePlane");
end

function testIndependentPositionAndExcitationStreams(testCase)
r=randomFixture();
r.streams=struct("positions",RandStream("mt19937ar","Seed",11), ...
    "excitation",RandStream("mt19937ar","Seed",12));
stateBefore=rng;
a=swsynth.sources.prepare(r);
verifyEqual(testCase,rng,stateBefore);
r.streams=struct("positions",RandStream("mt19937ar","Seed",11), ...
    "excitation",RandStream("mt19937ar","Seed",12));
b=swsynth.sources.prepare(r);
verifyEqual(testCase,a,b);

% Changing the position method must not redraw random excitation.
r.positions.method="fibonacci";
r.streams=struct("positions",RandStream("mt19937ar","Seed",11), ...
    "excitation",RandStream("mt19937ar","Seed",12));
c=swsynth.sources.prepare(r);
verifyEqual(testCase,a.excitation,c.excitation);
verifyFalse(testCase,isequal(a.sources.position_xyz_m, ...
    c.sources.position_xyz_m));
end

function testRejectCountMismatch(testCase)
r=planarFixture();
r.excitation.count=3;
verifyError(testCase,@() swsynth.sources.prepare(r), ...
    "swsynth:SourceBundleCountMismatch");
end

function testRejectGeometryMismatch(testCase)
r=planarFixture();
r.positions.geometry="volumetric3d";
verifyError(testCase,@() swsynth.sources.prepare(r), ...
    "swsynth:SourceBundleGeometryMismatch");
end

function testRejectApertureCountMismatch(testCase)
r=planarFixture();
ap=struct("model","point","span_m",0, ...
    "axis_xyz",[0 0 1],"node_spacing_m",.001);
r.aperture=repmat(ap,1,3);
verifyError(testCase,@() swsynth.sources.prepare(r), ...
    "swsynth:ApertureCountMismatch");
end

function r=planarFixture()
r=struct();
r.geometry="2d";
r.count=2;
r.positions=struct("method","explicit", ...
    "position_xyz_m",[.01 0 .02;.03 0 .04]);
r.excitation=struct("force_policy","fixed", ...
    "force_direction_xz",[1 0;0 1], ...
    "relative_amplitude",[.6;1.4], ...
    "phase_rad",[0;pi]);
end

function r=randomFixture()
r=struct();
r.geometry="projected3d";
r.count=7;
r.positions=struct("method","random", ...
    "center_xyz_m",[0 0 0],"radius_range_m",[.02 .025]);
r.excitation=struct("force_policy","random_sphere", ...
    "amplitude_policy","random_normal", ...
    "phase_policy","random_uniform", ...
    "amplitude_jitter_fraction",.1);
end
