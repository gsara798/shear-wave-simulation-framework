function tests=test_swsynth_campaign_parallel_modes
tests=functiontests(localfunctions);
end

function testCampaignFixturesAndParallelismAreExclusive(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
folder=fullfile(root,"configs","campaigns","swsynth","examples");
cases=["many_point_sources_parallel.json", ...
    "many_plane_waves_parallel.json", ...
    "many_point_sources_campaign_parallel.json", ...
    "many_plane_waves_campaign_parallel.json"];
for name=cases
    path=fullfile(folder,name);
    [runs,validation]=simcampaigns.validateCampaign(path);
    verifyTrue(tc,validation.valid,char(name));
    verifyEqual(tc,numel(runs),3);
    expectedSourceParallel=~contains(name,"campaign_parallel");
    for i=1:numel(runs)
        cfg=runs(i).config;
        enabled=false;
        if isfield(cfg,"execution")
            enabled=logical(cfg.execution.parallel);
        end
        verifyEqual(tc,enabled,expectedSourceParallel,char(name));
    end
end
end

function testProcessPoolRequirementDocumented(tc)
root=repoRoot();
source=fileread(fullfile(root,"src","+simcampaigns","runCampaign.m"));
verifyTrue(tc,contains(source,'parpool("Processes",workers)'));
verifyTrue(tc,contains(source,'parallel.ThreadPool'));
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
