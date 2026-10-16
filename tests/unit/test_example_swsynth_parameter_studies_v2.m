function tests=test_example_swsynth_parameter_studies_v2
tests=functiontests(localfunctions);
end

function testCampaignExpansionsAndDryRuns(tc)
root=repoRoot();
addpath(fullfile(root,"src"));
folder=fullfile(root,"examples","swsynth","v2","06_parameter_studies");
names=["frequency_sweep.json","material_speed_sweep.json", ...
    "incident_wave_count_sweep.json","random_realizations.json"];
expected=[5,4,5,5];
for i=1:numel(names)
    file=fullfile(folder,names(i));
    [runs,validation]=simcampaigns.validateCampaign(file);
    verifyTrue(tc,validation.valid,char(names(i)));
    verifyEqual(tc,numel(runs),expected(i),char(names(i)));
end
end

function testSourceCountsAndSeeds(tc)
root=repoRoot();
folder=fullfile(root,"examples","swsynth","v2","06_parameter_studies");
[runs,~]=simcampaigns.expandCampaign(fullfile(folder,"incident_wave_count_sweep.json"));
verifyEqual(tc,arrayfun(@(r)double(r.config.incidence.sampling.count),runs), ...
    [4;8;16;32;64]);
[runs,~]=simcampaigns.expandCampaign(fullfile(folder,"random_realizations.json"));
verifyEqual(tc,arrayfun(@(r)double(r.config.seed),runs), ...
    [53053;53054;53055;53056;53057]);
end

function root=repoRoot()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
