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

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
