function tests=test_swsynth_shear_noise_v2
tests=functiontests(localfunctions);
end

function testDeterminismAndIndependentRng(tc)
addpath(fullfile(repoRoot(),"src"));
U=complex(ones(12,14),0.4*ones(12,14));
cfg=struct("enabled",true,"source_amplitude_jitter_std",0.01, ...
    "source_phase_jitter_cycles_std",0.005, ...
    "propagation_relative_std",0.02,"correlation_m",0.0005);
before=rng;
[A,DA]=swsynth.noise.applyShearNoise(U,cfg,[0.0004,0.0004],345);
[B,DB]=swsynth.noise.applyShearNoise(U,cfg,[0.0004,0.0004],345);
verifyEqual(tc,A,B);
verifyEqual(tc,DA.snr_db,DB.snr_db);
verifyEqual(tc,rng,before);
verifyGreaterThan(tc,norm(A(:)-U(:)),0);
end

function testDisabledIsClean(tc)
addpath(fullfile(repoRoot(),"src"));
U=randn(8,7)+1i*randn(8,7);
[A,D]=swsynth.noise.applyShearNoise(U,struct("enabled",false),[0.001,0.001],123);
verifyEqual(tc,A,U);
verifyFalse(tc,D.enabled);
end

function testDryRunAndSeed(tc)
addpath(fullfile(repoRoot(),"src"));
p=fullfile(repoRoot(),"examples","swsynth","v2","07_shear_noise", ...
    "shear_noise_correlated_projected3d.json");
cfg=jsondecode(fileread(p));
[~,meta]=swsynth.io.resolveConfigV2(cfg);
verifyTrue(tc,meta.valid);
verifyError(tc,@()swsynth.noise.validateConfig( ...
    struct("enabled",true,"correlation_m",-1)), ...
    "swsynth:InvalidShearNoise");
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
