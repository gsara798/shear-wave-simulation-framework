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
verifyEqual(testCase,[k.grid.Nx,k.grid.Ny,k.grid.Nz],[304,240,304]);
verifyEqual(testCase,k.geometry.objects.radius_m,.052);
verifyEqual(testCase,string(k.geometry.objects.type),"sphere");
verifyEqual(testCase,k.geometry.objects.center_m_xyz(:).',[.075,.060,.075]);
verifyEqual(testCase, ...
    [k.grid.Nx,k.grid.Ny,k.grid.Nz]+2*double(k.solver.pml_size_points(:).'), ...
    [320,256,320]);
end

function testKwaveThinDomainsUseFftEfficientExpandedGrids(testCase)
root=testCase.TestData.repo;
for name=["homogeneous_base.json","bilayer_base.json"]
    k=jsondecode(fileread(fullfile(root,"configs","kwsim","three_d", ...
        "reqml_q0_v2",name)));
    verifyEqual(testCase,[k.grid.Nx,k.grid.Ny,k.grid.Nz],[304,48,304]);
    verifyEqual(testCase, ...
        [k.grid.Nx,k.grid.Ny,k.grid.Nz]+2*double(k.solver.pml_size_points(:).'), ...
        [320,64,320]);
end
end

function testKwaveCampaignCsvRetainsAngularProvenance(testCase)
root=string(tempname); mkdir(root); cleanup=onCleanup(@() rmdir(root,"s")); %#ok<NASGU>
config=kwsim.io.loadConfigJson(fullfile(testCase.TestData.repo,"configs", ...
    "kwsim","three_d","reqml_q0_v2","homogeneous_base.json"));
config.source.vibrator_count=16; config.source.exact_in_plane_sources=4;
config.source.in_plane_vibrator_count=4; config.source.angular_support_solid_angle_sr=pi;
run_dir=fullfile(root,"run_000001_test");
record=struct("ordinal",1,"run_id","run_000001_test","hash_sha256","abc", ...
    "status","completed","outcome_status","completed_valid", ...
    "run_directory",run_dir,"error_identifier","","error_message","");
report=struct("runs",record,"campaign_directory",root);
runs=struct("design_id","kwave_hom_cs2_mid","condition_id","kwave_hom_cs2_mid", ...
    "realization_id",1,"backend","kwsim","config",config);
csv=simcampaigns.writeCampaignRunsCsv(report,runs); t=readtable(csv,TextType="string");
verifyEqual(testCase,t.direction_count,16); verifyEqual(testCase,t.retained_direction_count,16);
verifyEqual(testCase,t.requested_in_plane_count,4); verifyEqual(testCase,t.retained_in_plane_count,4);
verifyEqual(testCase,t.solid_angle_sr,pi,AbsTol=1e-14);
verifyEqual(testCase,t.direction_support_type,"solid_angle_cap");
verifyEqual(testCase,t.geometry_family,"homogeneous"); verifyEqual(testCase,t.valid,1);
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
