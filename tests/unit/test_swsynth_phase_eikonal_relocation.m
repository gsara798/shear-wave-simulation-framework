function tests = test_swsynth_phase_eikonal_relocation
%TEST_SWSYNTH_PHASE_EIKONAL_RELOCATION Verify relocated solvers and wrappers.
tests = functiontests(localfunctions);
end

function testProjectedTravelTime(testCase)
x = 0:.001:.005; z = 0:.001:.005; cs = 2*ones(6,6);
d = [1 0 0]; referenceCs = 2;
[newT,newDiag] = swsynth.phase.eikonal.projected3d.computeTravelTime( ...
    cs,x,z,d,referenceCs,struct());
[oldT,oldDiag] = swsynth.propagation.projected3d.computeDirectionalPhaseDelay( ...
    cs,x,z,d,referenceCs,struct());
verifyEqual(testCase,newT,oldT);
verifyEqual(testCase,newDiag,oldDiag);
end

function testVolumetricTravelTime(testCase)
x = 0:.001:.003; y = x; z = x; cs = 2*ones(4,4,4);
d = [1 0 0]; referenceCs = 2;
[newT,newDiag] = swsynth.phase.eikonal.volumetric3d.computeTravelTime( ...
    cs,x,y,z,d,referenceCs,struct());
[oldT,oldDiag] = swsynth.propagation.volumetric3d.computeDirectionalTravelTime( ...
    cs,x,y,z,d,referenceCs,struct());
verifyEqual(testCase,newT,oldT);
verifyEqual(testCase,newDiag,oldDiag);
end

function testPhaseComputeDispatch(testCase)
req=struct("model","plane_wave","method","eikonal", ...
    "geometry","projected3d","direction_xyz",[1 0 0], ...
    "reference_cs_m_s",2,"x_m",0:.001:.004,"z_m",0:.001:.004, ...
    "cs_map_zx",2*ones(5,5));
r=swsynth.phase.compute(req);
expected=swsynth.phase.eikonal.projected3d.computeTravelTime( ...
    req.cs_map_zx,req.x_m,req.z_m,req.direction_xyz, ...
    req.reference_cs_m_s,struct());
verifyEqual(testCase,r.travel_time_s,expected);
end
