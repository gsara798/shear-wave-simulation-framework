function tests=test_swsynth_angular_aperture_campaigns_v2
tests=functiontests(localfunctions);
end

function testAngularCampaignsDryRun(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
folder=fullfile(root,"configs","campaigns","swsynth","parameter_studies");
names=["angular_aperture_plane_waves.json", ...
    "angular_aperture_spherical_sources.json"];
for name=names
    [runs,validation]=simcampaigns.validateCampaign(fullfile(folder,name));
    verifyTrue(tc,validation.valid,char(name));
    verifyEqual(tc,numel(runs),7);
end
end

function testPlaneWaveAngularQuota(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
p=fullfile(root,"examples","swsynth","v2","06_parameter_studies", ...
    "angular_aperture_plane_waves_base.json");
cfg=jsondecode(fileread(p));
for a=[15,30,45,60,90,120,180]
    cfg.incidence.sampling.cone_half_angle_deg=a;
    [scenario,~]=swsynth.io.resolveConfigV2(cfg);
    d=scenario.incidence.direction_xyz;
    verifyEqual(tc,size(d),[64,3]);
    verifyEqual(tc,sum(abs(d(:,2))<1e-12),8);
    verifyGreaterThanOrEqual(tc,min(d(:,1)),cosd(a)-1e-10);
end
end

function testPhysicalSourceAngularQuota(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
p=fullfile(root,"examples","swsynth","v2","06_parameter_studies", ...
    "angular_aperture_spherical_sources_base.json");
cfg=jsondecode(fileread(p));
for a=[15,30,45,60,90,120,180]
    cfg.sources.positions.support.half_angle_deg=a;
    [scenario,~]=swsynth.io.resolveConfigV2(cfg);
    req=scenario.sources;
    req.geometry=scenario.geometry;
    req.observation_y_m=0;
    bundle=swsynth.sources.prepare(req);
    xyz=bundle.sources.position_xyz_m;
    dirs=(xyz-[.012,0,.012])/.04;
    verifyEqual(tc,size(xyz),[64,3]);
    verifyEqual(tc,sum(abs(xyz(:,2))<1e-12),8);
    verifyGreaterThanOrEqual(tc,min(dirs(:,1)),cosd(a)-1e-10);
end
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
