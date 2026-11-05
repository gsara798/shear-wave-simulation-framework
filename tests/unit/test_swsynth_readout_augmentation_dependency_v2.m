function tests=test_swsynth_readout_augmentation_dependency_v2
tests=functiontests(localfunctions);
end

function testReadoutIsDeterministicAndPreservesGlobalRng(tc)
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
U=complex(ones(18,20),.2*ones(18,20));
cfg=struct("enabled",true,"level","medium","strength",1, ...
    "nt",32,"prf_hz",4000,"correlation_m",.00045, ...
    "depth_profile","exponential_0_to_1", ...
    "depth_weight_power",3,"depth_noise_floor",.12, ...
    "amplitude_normalization","max_abs");
before=rng;
[A,DA]=swsynth.observation.readout.applyDisplacementNoise( ...
    U,cfg,[.0005,.0005],(0:17)'*.0005,400,8512);
[B,DB]=swsynth.observation.readout.applyDisplacementNoise( ...
    U,cfg,[.0005,.0005],(0:17)'*.0005,400,8512);
verifyEqual(tc,A,B);
verifyEqual(tc,DA.snr_db,DB.snr_db);
verifyEqual(tc,rng,before);
verifyGreaterThan(tc,norm(A(:)-U(:)),0);
end
