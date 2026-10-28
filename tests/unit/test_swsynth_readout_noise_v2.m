function tests=test_swsynth_readout_noise_v2
tests=functiontests(localfunctions);
end

function testReproducibilityAndGlobalRngIsolation(tc)
addpath(fullfile(repoRoot(),"src"));
U=complex(ones(24,30),0.4*ones(24,30));
cfg=mediumReadout();
before=rng;
[A,DA]=swsynth.observation.readout.applyDisplacementNoise( ...
    U,cfg,[0.0004,0.0004],(0:23)'*0.0004,500,81001);
[B,DB]=swsynth.observation.readout.applyDisplacementNoise( ...
    U,cfg,[0.0004,0.0004],(0:23)'*0.0004,500,81001);
verifyEqual(tc,A,B);
verifyEqual(tc,DA.snr_db,DB.snr_db);
verifyEqual(tc,rng,before);
verifyGreaterThan(tc,norm(A(:)-U(:)),0);
end

function testZeroStrengthPreservesCleanPhasor(tc)
addpath(fullfile(repoRoot(),"src"));
U=complex(randn(15,17),randn(15,17));
cfg=mediumReadout();
cfg.strength=0;
[A,D]=swsynth.observation.readout.applyDisplacementNoise( ...
    U,cfg,[0.0004,0.0004],(0:14)'*0.0004,500,42);
verifyEqual(tc,A,U);
verifyTrue(tc,D.enabled);
verifyEqual(tc,D.snr_db,Inf);
end

function testStrengthIsLinearForFixedNoiseSeed(tc)
addpath(fullfile(repoRoot(),"src"));
U=complex(ones(32,40),0.2*ones(32,40));
cfg=mediumReadout();
z=(0:31)'*0.0004;
[A,~]=swsynth.observation.readout.applyDisplacementNoise( ...
    U,cfg,[0.0004,0.0004],z,500,111);
cfg.strength=2;
[B,~]=swsynth.observation.readout.applyDisplacementNoise( ...
    U,cfg,[0.0004,0.0004],z,500,111);
verifyLessThan(tc,norm(B(:)-U(:)-2*(A(:)-U(:))) / ...
    max(norm(B(:)-U(:)),eps),1e-10);
end

function testFixedReferenceIsIndependentOfFieldAmplitude(tc)
addpath(fullfile(repoRoot(),"src"));
cfg=mediumReadout();
cfg.amplitude_normalization="fixed_reference";
cfg.reference_amplitude=2.5;
z=(0:19)'*0.0004;
[A,DA]=swsynth.observation.readout.applyDisplacementNoise( ...
    ones(20,24),cfg,[0.0004,0.0004],z,500,81);
[B,DB]=swsynth.observation.readout.applyDisplacementNoise( ...
    0.1*ones(20,24),cfg,[0.0004,0.0004],z,500,81);
verifyEqual(tc,DA.additive_sigma,DB.additive_sigma);
verifyEqual(tc,DA.reference_amplitude,2.5);
verifyGreaterThan(tc,norm(A(:)-1),0);
verifyGreaterThan(tc,norm(B(:)-0.1),0);
end

function testDepthWeightsAndVolume(tc)
addpath(fullfile(repoRoot(),"src"));
U=complex(ones(40,30,6),0.3*ones(40,30,6));
cfg=mediumReadout();
[A,D]=swsynth.observation.readout.applyDisplacementNoise( ...
    U,cfg,[0.0004,0.0004,0.0004],(0:39)'*0.0004,500,333);
verifySize(tc,A,size(U));
verifyLessThan(tc,D.depth_weight_z(1),D.depth_weight_z(end));
verifyGreaterThan(tc,norm(A(:)-U(:)),0);
end

function testDryRunValidation(tc)
addpath(fullfile(repoRoot(),"src"));
base=fullfile(repoRoot(),"examples","swsynth","v2", ...
    "09_displacement_readout_noise","single_point_force_x_readout_base.json");
cfg=jsondecode(fileread(base));
[scenario,meta]=swsynth.io.resolveConfigV2(cfg);
verifyTrue(tc,meta.valid);
verifyFalse(tc,isfield(scenario,"readout_noise")); % post-synthesis only
bad=cfg;
bad.readout_noise.amplitude_normalization="fixed_reference";
verifyError(tc,@()swsynth.io.resolveConfigV2(bad), ...
    "swsynth:InvalidReadoutNoise");
bad=cfg;
bad.readout_noise.prf_hz=800;
verifyError(tc,@()swsynth.io.resolveConfigV2(bad), ...
    "swsynth:InvalidReadoutNoise");
end

function testRunStoresCleanAndMeasuredFields(tc)
addpath(fullfile(repoRoot(),"src"));
base=fullfile(repoRoot(),"examples","swsynth","v2", ...
    "09_displacement_readout_noise","single_point_force_x_readout_base.json");
cfg=jsondecode(fileread(base));
cfg.domain.Lx_m=0.008;
cfg.domain.Lz_m=0.008;
cfg.domain.dx_m=0.0005;
cfg.domain.dz_m=0.0005;
cfg.readout_noise.strength=1.0;
cfg.shear_noise.enabled=true;
cfg.shear_noise.propagation_relative_std=0.01;
cfg.shear_noise.seed=73001;
runDir=string(tempname);
cleanup=onCleanup(@()deleteDir(runDir)); %#ok<NASGU>
out=simcampaigns.backends.executeSwsynthV2(cfg,runDir);
S=load(out.paths.wavefield_sample,"wavefield_sample");
R=load(fullfile(runDir,"data","shear_clean_reference.mat"));
verifyTrue(tc,isfield(S.wavefield_sample.provenance,"readout_noise"));
verifyTrue(tc,isfield(S.wavefield_sample.provenance,"shear_noise"));
verifyGreaterThan(tc,norm(R.preReadoutShear(:)-R.cleanShear(:)),0);
verifyGreaterThan(tc,norm(S.wavefield_sample.wavefield.data_zx(:)- ...
    R.preReadoutShear(:)),0);
summary=jsondecode(fileread(fullfile(runDir,"data","run_summary.json")));
verifyTrue(tc,summary.readout_noise_enabled);
verifyTrue(tc,summary.shear_noise_enabled);
verifyTrue(tc,isfinite(summary.total_noise_snr_db));
end

function cfg=mediumReadout()
cfg=struct("enabled",true,"level","medium","strength",1, ...
    "nt",32,"prf_hz",4000,"correlation_m",0.00045, ...
    "depth_profile","exponential_0_to_1","depth_weight_power",3, ...
    "depth_noise_floor",0.12,"amplitude_normalization","max_abs");
end

function deleteDir(path)
if isfolder(path),rmdir(path,"s");end
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
