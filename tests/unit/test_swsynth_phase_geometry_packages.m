function tests = test_swsynth_phase_geometry_packages
%TEST_SWSYNTH_PHASE_GEOMETRY_PACKAGES Geometry-specific phase modules.
tests=functiontests(localfunctions);
end

function testAnalyticalGeometryModules(testCase)
x=0:.001:.004; z=0:.001:.003; y=0:.001:.002;
d=[1 0 0]; cs=2;
verifyEqual(testCase, ...
    swsynth.phase.analytical.planar2d.computeTravelTime(x,z,d,cs), ...
    swsynth.phase.analytical.projected3d.computeTravelTime(x,z,d,cs));
r=struct("model","plane_wave","method","analytical", ...
    "geometry","volumetric3d","direction_xyz",d, ...
    "reference_cs_m_s",cs,"x_m",x,"z_m",z,"y_m",y, ...
    "cs_map_zyx",2*ones(numel(z),numel(y),numel(x)));
out=swsynth.phase.compute(r);
verifyEqual(testCase,out.travel_time_s, ...
    swsynth.phase.analytical.volumetric3d.computeTravelTime(x,y,z,d,cs));
end

function testStraightRayRelocation(testCase)
cfg=swsynth.defaultConfig();
cfg.propagation.model="spherical_wave";
cfg.propagation.phase_model="straight_ray_numerical";
cfg.execution.use_parallel=false;
source=[0 0 0]; targets=[.001 0 .002;.003 0 .004];
[expected,expectedDiag]=swsynth.integrateStraightRayTravelTime( ...
    cfg,source,targets);
r=struct("model","spherical_wave","method","straight_ray_numerical", ...
    "geometry","2d","cfg",cfg, ...
    "source_xyz_m",source,"target_xyz_m",targets);
out=swsynth.phase.compute(r);
verifyEqual(testCase,out.travel_time_s,expected);
verifyEqual(testCase,out.diagnostics,expectedDiag);
r.geometry="projected3d";
projected=swsynth.phase.compute(r);
verifyEqual(testCase,projected.travel_time_s,expected);
end
