function tests=test_swsynth_observation_projection_v2
tests=functiontests(localfunctions);
end

function testSignedAxialProjection(testCase)
vectors=[1 2 3; 0 0 -4];
out=swsynth.observation.projectComponent(vectors,[0 0 5]);
verifyEqual(testCase,out,[3;-4]);
end

function testComplexFieldsAndArbitraryAxis(testCase)
vectors=[1+2i 0 0;0 3i 0];
out=swsynth.observation.projectComponent(vectors,[1 1 0]);
verifyEqual(testCase,out,[(1+2i);3i]/sqrt(2),"AbsTol",1e-14);
end

function testVolumetricVectorComponentLast(testCase)
u=zeros(2,3,4,3);
u(:,:,:,1)=3;
u(:,:,:,3)=4;
observed=swsynth.observation.projectComponent(u,[3 0 4]);
verifySize(testCase,observed,[2 3 4]);
verifyEqual(testCase,observed, ...
    repmat(5.0,2,3,4),"AbsTol",1e-14);
end

function testRejectInvalidObservationAxis(testCase)
verifyError(testCase,@() swsynth.observation.projectComponent( ...
    [1 2 3],[0 0 0]),"swsynth:InvalidObservationAxis");
end

function testRejectWrongVectorShape(testCase)
verifyError(testCase,@() swsynth.observation.projectComponent( ...
    [1 2;3 4],[0 0 1]),"swsynth:InvalidObservationVectors");
end
