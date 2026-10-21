function tests=test_shear_noise_uniform
tests=functiontests(localfunctions);
end
function testUniformNoiseHasConstantAbsoluteScale(t)
rng(5);
U=ones(64,64);
U(:,33:end)=0.05;
cfg=struct("enabled",true,"spatial_scaling","uniform_global_rms", ...
 "source_amplitude_jitter_std",0,"source_phase_jitter_cycles_std",0, ...
 "propagation_relative_std",0.04,"correlation_m",0, ...
 "amplitude_floor_fraction",0.05);
[Y,D]=swsynth.noise.applyShearNoise(U,cfg,[0.0004,0.0004],70001);
N=Y-U;
left=std(abs(N(:,1:32)),0,"all");
right=std(abs(N(:,33:end)),0,"all");
verifyLessThan(t,abs(left-right)/max(left,right),0.35);
verifyEqual(t,D.spatial_scaling,"uniform_global_rms");
verifyTrue(t,isfinite(D.snr_db));
end
function testDefaultBackwardCompatible(t)
cfg=struct("enabled",true,"propagation_relative_std",0.02, ...
 "correlation_m",0,"amplitude_floor_fraction",0.05);
U=ones(20,20);
[a,~]=swsynth.noise.applyShearNoise(U,cfg,[0.001,0.001],17);
cfg.spatial_scaling="relative_local";
[b,~]=swsynth.noise.applyShearNoise(U,cfg,[0.001,0.001],17);
verifyEqual(t,a,b);
end
function testInvalidScalingRejected(t)
cfg=struct("enabled",true,"spatial_scaling","invalid");
verifyError(t,@()swsynth.noise.validateConfig(cfg),"swsynth:InvalidShearNoise");
end
