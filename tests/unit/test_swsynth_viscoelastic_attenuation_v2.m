function tests=test_swsynth_viscoelastic_attenuation_v2
tests=functiontests(localfunctions);
end

function testElasticLimit(tc)
addpath(fullfile(repoRoot(),"src"));
E=swsynth.medium.viscoelastic.dispersion( ...
    struct("model","elastic","density_kg_m3",1000,"mu_pa",4000),500);
verifyEqual(tc,E.phase_speed_m_s,2,"AbsTol",1e-10);
verifyEqual(tc,E.attenuation_np_m,0,"AbsTol",1e-10);
end

function testKelvinVoigtPositiveLoss(tc)
addpath(fullfile(repoRoot(),"src"));
spec=struct("model","kelvin_voigt","density_kg_m3",1000, ...
    "mu_pa",4000,"eta_pa_s",0.25);
K=swsynth.medium.viscoelastic.dispersion(spec,500);
verifyGreaterThan(tc,K.attenuation_np_m,0);
verifyGreaterThan(tc,K.phase_speed_m_s,0);
end

function testExamplesDryRun(tc)
addpath(fullfile(repoRoot(),"src"));
folder=fullfile(repoRoot(),"examples","swsynth","v2","08_shear_attenuation");
for name=["plane_elastic_reference.json","plane_kelvin_voigt.json"]
    config=jsondecode(fileread(fullfile(folder,name)));
    [~,meta]=swsynth.io.resolveConfigV2(config);
    verifyTrue(tc,meta.valid,char(name));
end
end

function testPlaneWaveEnvelopeDecays(tc)
addpath(fullfile(repoRoot(),"src"));
folder=fullfile(repoRoot(),"examples","swsynth","v2","08_shear_attenuation");
elastic=jsondecode(fileread(fullfile(folder,"plane_elastic_reference.json")));
visco=jsondecode(fileread(fullfile(folder,"plane_kelvin_voigt.json")));
[se,~]=swsynth.io.resolveConfigV2(elastic);
[sv,~]=swsynth.io.resolveConfigV2(visco);
E=swsynth.propagation.synthesize(se);
V=swsynth.propagation.synthesize(sv);
uE=swsynth.observation.projectComponent(E.U_xyz,[0,0,1]);
uV=swsynth.observation.projectComponent(V.U_xyz,[0,0,1]);
left=mean(abs(uV(:,1)));
right=mean(abs(uV(:,end)));
verifyGreaterThan(tc,left,right);
verifyEqual(tc,mean(abs(uE(:,1))),mean(abs(uE(:,end))),"RelTol",1e-10);
end

function testDispersiveSpeedDiffersFromElasticReference(tc)
addpath(fullfile(repoRoot(),"src"));
file=fullfile(repoRoot(),"examples","swsynth","v2", ...
    "08_shear_attenuation","plane_kelvin_voigt.json");
cfg=jsondecode(fileread(file));
[scenario,~]=swsynth.io.resolveConfigV2(cfg);
materialSpeed=double(scenario.medium.cs_m_s);
result=swsynth.propagation.synthesize(scenario);
phaseSpeed=result.propagation.material_dispersion.phase_speed_m_s;
verifyNotEqual(tc,phaseSpeed,materialSpeed);
verifyGreaterThan(tc,result.propagation.material_dispersion.attenuation_np_m,0);
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
