function tests=test_swsynth_spherical_point_source_contribution_v2
tests=functiontests(localfunctions);
end

function testAnalyticalPointForcePlanarRadiation(testCase)
bundle=makeBundle("2d", [0 0 0], [1 0 0], 1, 0, []);
r=makeRequest(bundle,[1 2],[1 2]);
r.frequency_hz=250;
r.phase.reference_cs_m_s=2;
out=swsynth.propagation.spherical.point_source.computeContribution(r);
[X,Z]=meshgrid(r.x_m,r.z_m);
distance=hypot(X,Z);
nX=X./distance;
nZ=Z./distance;
PX=1-nX.^2;
PZ=-nX.*nZ;
theta=2*pi*250*distance/2;
verifySize(testCase,out.U_xyz,[2 2 3]);
verifyEqual(testCase,out.U_xyz(:,:,1),PX.*exp(1i*theta), ...
    "AbsTol",1e-13);
verifyEqual(testCase,out.U_xyz(:,:,3),PZ.*exp(1i*theta), ...
    "AbsTol",1e-13);
verifyEqual(testCase,out.U_xyz(:,:,2),zeros(2,2), ...
    "AbsTol",1e-14);
verifyEqual(testCase,out.phase_solver,"homogeneous_spherical_distance");
verifyEqual(testCase,out.phase_sign,1);
end

function testProjectedOffPlaneSourceMatchesLegacyProjection(testCase)
src=[0 .04 0];
force=[0 1 0];
bundle=makeBundle("projected3d",src,force,1,0,[]);
r=makeRequest(bundle,[.01 .02],[.01 .02]);
r.frequency_hz=200;
out=swsynth.propagation.spherical.point_source.computeContribution(r);
[Z,X]=ndgrid(r.z_m,r.x_m);
obs=[X(:),zeros(numel(X),1),Z(:)];
[expected,~,~,distance]= ...
    swsynth.propagation.spherical.point_source.shear_far_field. ...
    computeShearProjection(src,obs,force,[0 0 1]);
expected=reshape(expected.* ...
    exp(1i*2*pi*r.frequency_hz*distance/2),size(X));
verifyEqual(testCase,out.U_xyz(:,:,3),expected,"AbsTol",1e-14);
verifySize(testCase,out.U_xyz,[2 2 3]);
end

function testVolumetricShapeAndSensorProjection(testCase)
bundle=makeBundle("volumetric3d",[0 .03 0],[0 0 1],1.1,pi/3,[]);
r=makeRequest(bundle,[.01 .02],[.01 .02]);
r.y_m=[0 .01];
out=swsynth.propagation.spherical.point_source.computeContribution(r);
verifySize(testCase,out.U_xyz,[2 2 2 3]);
verifyEqual(testCase,out.output_convention, ...
    "U(z,y,x,component_xyz)");
observed=swsynth.observation.projectComponent(out.U_xyz,[0 0 1]);
verifyEqual(testCase,observed,out.U_xyz(:,:,:,3));
verifyEqual(testCase,out.source_xyz_m,[0 .03 0]);
end

function testZeroSourceAmplitudeProducesComplexZero(testCase)
bundle=makeBundle("2d",[0 0 0],[1 0 0],0,0,[]);
r=makeRequest(bundle,[1 2],[1 2]);
out=swsynth.propagation.spherical.point_source.computeContribution(r);
verifyEqual(testCase,out.U_xyz,complex(zeros(2,2,3)));
verifyFalse(testCase,isreal(out.U_xyz));
end

function testParentSourcePhaseAppliesToAllApertureElements(testCase)
ap=struct("model","line_segment","span_m",.002, ...
    "axis_xyz",[1 0 0],"node_spacing_m",.001);
bundle=makeBundle("2d",[0 0 0],[0 0 1],1,0,ap);
r=makeRequest(bundle,[.01 .02],[.02 .03]);
a=swsynth.propagation.spherical.point_source.computeContribution(r);
r.source_bundle.sources.phase_rad=pi;
r.source_bundle.excitation.phase_rad=pi;
b=swsynth.propagation.spherical.point_source.computeContribution(r);
verifyEqual(testCase,b.U_xyz,-a.U_xyz,"AbsTol",1e-13);
verifyEqual(testCase,a.aperture_node_count,3);
end

function testCoherentLineApertureMatchesManualNodeSum(testCase)
ap=struct("model","line_segment","span_m",.002, ...
    "axis_xyz",[1 0 0],"node_spacing_m",.001);
bundle=makeBundle("projected3d",[0 .02 0],[0 0 1],1.3,pi/5,ap);
r=makeRequest(bundle,[.01 .02],[.01 .02]);
r.geometric_decay_exponent=1;
out=swsynth.propagation.spherical.point_source.computeContribution(r);
[Z,X]=ndgrid(r.z_m,r.x_m);
obs=[X(:),zeros(numel(X),1),Z(:)];
nodeList=bundle.aperture.per_source(1).node_xyz_m;
nodeW=bundle.aperture.per_source(1).node_weights;
manual=complex(zeros(numel(X),3));
for k=1:size(nodeList,1)
    [~,pol,~,distance]= ...
        swsynth.propagation.spherical.point_source.shear_far_field. ...
        computeShearProjection(nodeList(k,:),obs,[0 0 1],[0 0 1]);
    signal=(1.3*nodeW(k)).*exp(1i*(2*pi*r.frequency_hz*distance/2+pi/5))./distance;
    manual=manual+signal.*pol;
end
verifyEqual(testCase,out.U_xyz,reshape(manual,[2 2 3]), ...
    "AbsTol",1e-12);
end

function testMultiSourceBundleRequiresExplicitSourceSelection(testCase)
sourceReq=struct();
sourceReq.geometry="2d";
sourceReq.count=2;
sourceReq.positions=struct("method","explicit", ...
    "position_xyz_m",[0 0 0;.03 0 0]);
sourceReq.excitation=struct("force_direction_xz",[1 0;0 1], ...
    "relative_amplitude",[1;2],"phase_rad",[0;pi]);
bundle=swsynth.sources.prepare(sourceReq);
r=makeRequest(bundle,[.01 .02],[.01 .02]);
verifyError(testCase, ...
    @() swsynth.propagation.spherical.point_source.computeContribution(r), ...
    "swsynth:SphericalContributionMissingSourceID");
r.source_id=1;
a=swsynth.propagation.spherical.point_source.computeContribution(r);
r.source_id=2;
b=swsynth.propagation.spherical.point_source.computeContribution(r);
verifyEqual(testCase,b.source_id,2);
sumField=swsynth.propagation.accumulate({a,b});
verifyEqual(testCase,sumField.U_xyz,a.U_xyz+b.U_xyz, ...
    "AbsTol",1e-14);
verifyEqual(testCase,sumField.component_count,2);
end

function testCoherentMixedPointAndPlaneWaves(testCase)
bundle=makeBundle("2d",[0 0 0],[0 0 1],1,0,[]);
r=makeRequest(bundle,[.01 .02],[.01 .02]);
spherical=swsynth.propagation.spherical.point_source.computeContribution(r);
planeReq=struct("geometry","2d","direction_xyz",[1 0 0], ...
    "frequency_hz",r.frequency_hz, ...
    "phase",struct("method","analytical", ...
    "reference_cs_m_s",2,"x_m",r.x_m,"z_m",r.z_m), ...
    "polarization",struct("policy","in_plane_sv"));
plane=swsynth.propagation.plane_wave.computeContribution(planeReq);
total=swsynth.propagation.accumulate({spherical,plane});
verifyEqual(testCase,total.U_xyz,spherical.U_xyz+plane.U_xyz, ...
    "AbsTol",1e-14);
end

function testSqrtCountNormalizesSourcesNotApertureNodes(testCase)
ap=struct("model","line_segment","span_m",.002, ...
    "axis_xyz",[1 0 0],"node_spacing_m",.001);
r=struct("geometry","projected3d","count",2);
r.positions=struct("method","explicit", ...
    "position_xyz_m",[0 .03 0;.03 -.03 0]);
r.excitation=struct("force_direction_xyz",[0 0 1;0 0 1], ...
    "relative_amplitude",[1;1],"phase_rad",[0;pi/2]);
r.aperture=ap;
bundle=swsynth.sources.prepare(r);
req=makeRequest(bundle,[.01 .02],[.01 .02]);
req.source_id=1;
a=swsynth.propagation.spherical.point_source.computeContribution(req);
req.source_id=2;
b=swsynth.propagation.spherical.point_source.computeContribution(req);
out=swsynth.propagation.accumulate({a,b}, ...
    struct("normalization","sqrt_count"));
verifyEqual(testCase,a.aperture_node_count,3);
verifyEqual(testCase,b.aperture_node_count,3);
verifyEqual(testCase,out.normalization_factor,1/sqrt(2));
verifyEqual(testCase,out.U_xyz,(a.U_xyz+b.U_xyz)/sqrt(2), ...
    "AbsTol",1e-14);
end

function testSphericalContributionDoesNotConsumeRng(testCase)
bundle=makeBundle("projected3d",[0 .03 0],[0 0 1],1,0,[]);
r=makeRequest(bundle,[.01 .02],[.01 .02]);
rngBefore=rng;
swsynth.propagation.spherical.point_source.computeContribution(r);
verifyEqual(testCase,rng,rngBefore);
end

function testRejectDifferentObservationPlanesInAccumulator(testCase)
bundle=makeBundle("projected3d",[0 .03 0],[0 0 1],1,0,[]);
r=makeRequest(bundle,[.01 .02],[.01 .02]);
a=swsynth.propagation.spherical.point_source.computeContribution(r);
r.observation_y_m=.005;
b=swsynth.propagation.spherical.point_source.computeContribution(r);
verifyError(testCase,@() swsynth.propagation.accumulate({a,b}), ...
    "swsynth:WaveContributionGridMismatch");
end

function testRejectObservationAtPointForce(testCase)
bundle=makeBundle("2d",[0 0 0],[0 0 1],1,0,[]);
r=makeRequest(bundle,[0 .01],[0 .01]);
verifyError(testCase, ...
    @() swsynth.propagation.spherical.point_source.computeContribution(r), ...
    "swsynth:ObservationAtPointForce");
end

function testRejectUnsupportedPhaseModel(testCase)
bundle=makeBundle("2d",[0 0 0],[0 0 1],1,0,[]);
r=makeRequest(bundle,[.01 .02],[.01 .02]);
r.phase.method="eikonal";
verifyError(testCase, ...
    @() swsynth.propagation.spherical.point_source.computeContribution(r), ...
    "swsynth:UnsupportedSphericalPhaseMethod");
end

function testRejectInvalidDecayExponent(testCase)
bundle=makeBundle("2d",[0 0 0],[0 0 1],1,0,[]);
r=makeRequest(bundle,[.01 .02],[.01 .02]);
r.geometric_decay_exponent=-1;
verifyError(testCase, ...
    @() swsynth.propagation.spherical.point_source.computeContribution(r), ...
    "swsynth:InvalidGeometricDecayExponent");
end

function testPlanarRejectsDifferentObservationY(testCase)
bundle=makeBundle("2d",[0 0 0],[1 0 0],1,0,[]);
r=makeRequest(bundle,[.01 .02],[.01 .02]);
r.observation_y_m=.003;
verifyError(testCase, ...
    @() swsynth.propagation.spherical.point_source.computeContribution(r), ...
    "swsynth:SphericalContributionGeometryMismatch");
end

function testSphericalPhaseDirectContract(testCase)
req=struct("model","spherical_wave","method","analytical", ...
    "geometry","projected3d", ...
    "source_xyz_m",[0 0 0], ...
    "target_xyz_m",[0 0 .02;0 .03 0], ...
    "reference_cs_m_s",2);
out=swsynth.phase.compute(req);
verifyEqual(testCase,out.travel_time_s,[.01;.015],"AbsTol",1e-14);
verifyEqual(testCase,out.solver,"homogeneous_spherical_distance");
end

function bundle=makeBundle(geometry,xyz,force,amp,phase,ap)
r=struct("geometry",geometry,"count",1);
r.positions=struct("method","explicit","position_xyz_m",xyz);
r.excitation=struct("force_direction_xyz",force, ...
    "relative_amplitude",amp,"phase_rad",phase);
if ~isempty(ap)
    r.aperture=ap;
end
bundle=swsynth.sources.prepare(r);
end

function r=makeRequest(bundle,x,z)
r=struct();
r.source_bundle=bundle;
r.frequency_hz=500;
r.phase=struct("method","analytical","reference_cs_m_s",2);
r.x_m=x;
r.z_m=z;
end
