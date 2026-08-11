function tests=test_reqml_q0_v2_external_campaigns
tests=functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.repo=string(fileparts(fileparts(fileparts(mfilename("fullpath")))));
end

function testAllCampaignsUseNewV2Identities(testCase)
files=campaign_files(testCase.TestData.repo); seeds=[]; total=0;
for file=files.'
    raw=fileread(file); c=jsondecode(raw);
    verifyFalse(testCase,contains(raw,"_v1"));
    verifyTrue(testCase,contains(string(c.campaign_name),"reqml_q0_v2"));
    total=total+numel(c.runs);
    for i=1:numel(c.runs)
        seeds(end+1)=override(c.runs(i),"seed"); %#ok<AGROW>
    end
end
verifyEqual(testCase,total,24);
verifyEqual(testCase,numel(unique(seeds)),24);
end

function testMatchedCoupledAngularAnchors(testCase)
files=campaign_files(testCase.TestData.repo);
for file=files.'
    c=jsondecode(fileread(file));
    for i=1:numel(c.runs)
        id=string(c.runs(i).design_id);
        if endsWith(id,"_low"), expected=[1,1,.01];
        elseif endsWith(id,"_mid"), expected=[16,4,pi];
        else, expected=[32,8,4*pi]; end
        if string(c.backend)=="swsynth"
            actual=[override(c.runs(i),"directions.count"), ...
                override(c.runs(i),"directions.in_plane_count"), ...
                override(c.runs(i),"directions.support.solid_angle_sr")];
        else
            actual=[override(c.runs(i),"source.vibrator_count"), ...
                override(c.runs(i),"source.exact_in_plane_sources"), ...
                override(c.runs(i),"source.angular_support_solid_angle_sr")];
        end
        verifyEqual(testCase,actual,expected,AbsTol=1e-14);
    end
end
end

function testPureCoreGeometryAndMemoryContract(testCase)
root=testCase.TestData.repo;
e=jsondecode(fileread(fullfile(root,"configs","swsynth","scientific", ...
    "reqml_q0_v2","inclusion_base.json")));
k=jsondecode(fileread(fullfile(root,"configs","kwsim","three_d", ...
    "reqml_q0_v2","inclusion_base.json")));
verifyEqual(testCase,e.domain.Lx_m,.15); verifyEqual(testCase,e.medium.objects.radius_m,.052);
verifyEqual(testCase,[k.grid.Nx,k.grid.Ny,k.grid.Nz],[301,225,301]);
verifyEqual(testCase,k.geometry.objects.radius_m,.052);
verifyEqual(testCase,string(k.geometry.objects.type),"sphere");
end

function files=campaign_files(root)
files=[
    fullfile(root,"configs","campaigns","swsynth","scientific","reqml_q0_v2","homogeneous.json")
    fullfile(root,"configs","campaigns","swsynth","scientific","reqml_q0_v2","inclusion.json")
    fullfile(root,"configs","campaigns","swsynth","scientific","reqml_q0_v2","bilayer.json")
    fullfile(root,"configs","campaigns","kwsim","scientific","reqml_q0_v2","homogeneous.json")
    fullfile(root,"configs","campaigns","kwsim","scientific","reqml_q0_v2","inclusion.json")
    fullfile(root,"configs","campaigns","kwsim","scientific","reqml_q0_v2","bilayer.json")
];
end

function value=override(run,path)
paths=string({run.overrides.path}); index=find(paths==path,1);
if isempty(index), error("test:MissingOverride","Missing %s",path); end
value=double(run.overrides(index).value);
end
