function tests = test_simcampaigns_csv_metadata
%TEST_SIMCAMPAIGNS_CSV_METADATA Test heterogeneous object metadata in CSV.

tests = functiontests(localfunctions);

end

function setupOnce(testCase)

repository_root = fileparts(fileparts(fileparts( ...
    mfilename("fullpath"))));

addpath(fullfile(repository_root, "src"));

testCase.TestData.repository_root = ...
    string(repository_root);

end

function testWritesPrimaryObjectMetadata(testCase)
% A projected3d Eikonal V2 campaign must export truthful run metadata.
base=fullfile(testCase.TestData.repository_root, ...
    "configs","swsynth","v2", ...
    "projected3d_heterogeneous_eikonal.json");
output_root=string(tempname);
campaign=struct();
campaign.schema_version="1.1";
campaign.backend="swsynth";
campaign.campaign_name="v2_circle_csv_metadata";
campaign.base_config=string(base);
campaign.output=struct("directory",output_root);
campaign.sweep=struct( ...
    "path",{"medium.objects[1].cs_m_s","excitation.frequency_hz"}, ...
    "values",{[2.5 4],[400 500]});

temporary_campaign=string(tempname)+".json";
fid=fopen(temporary_campaign,"w");
assert(fid>=0);
guard=onCleanup(@() fclose(fid));
fprintf(fid,"%s",jsonencode(campaign,PrettyPrint=true));
clear guard
cleanup=onCleanup(@() cleanupPaths(temporary_campaign,output_root));
report=simcampaigns.runCampaign( ...
    temporary_campaign,Resume=true,ContinueOnError=false);
verifyTrue(testCase,report.success);
verifyEqual(testCase,report.completed_count,4);
csv_file=fullfile(output_root,campaign.campaign_name, ...
    "campaign_runs.csv");
campaign_runs=readtable(csv_file, ...
    TextType="string",VariableNamingRule="preserve");
verifyEqual(testCase,height(campaign_runs),4);
names=string(campaign_runs.Properties.VariableNames);
required=["primary_object_type","primary_object_cs_m_s", ...
    "primary_object_radius_m","frequency_hz","valid", ...
    "validation_report_path"];
verifyTrue(testCase,all(ismember(required,names)), ...
    "CSV columns found: "+strjoin(names,", "));
verifyEqual(testCase,string(campaign_runs.primary_object_type), ...
    repmat("circle",4,1));
verifyEqual(testCase,campaign_runs.primary_object_cs_m_s, ...
    [2.5;2.5;4;4]);
verifyEqual(testCase,campaign_runs.primary_object_radius_m, ...
    repmat(.002,4,1),"AbsTol",1e-12);
verifyEqual(testCase,campaign_runs.frequency_hz,[400;500;400;500]);
verifyEqual(testCase,campaign_runs.background_cs_m_s, ...
    repmat(2,4,1));
verifyEqual(testCase,string(campaign_runs.geometry_family), ...
    repmat("circular_inclusion",4,1));
verifyEqual(testCase,string(campaign_runs.propagation_model), ...
    repmat("plane_wave",4,1));
verifyEqual(testCase,campaign_runs.direction_count,ones(4,1));
verifyEqual(testCase,campaign_runs.retained_direction_count,ones(4,1));
verifyEqual(testCase,string(campaign_runs.direction_support_type), ...
    repmat("explicit",4,1));
verifyEqual(testCase,campaign_runs.retained_in_plane_fraction,ones(4,1));
verifyEqual(testCase,campaign_runs.valid,ones(4,1));
verifyTrue(testCase,all(isfile(string( ...
    campaign_runs.validation_report_path))));
% Spectral entropy is not an output of the V2 synthesizer; never fabricate
% these diagnostics in the CSV merely to fill old legacy columns.
verifyTrue(testCase,all(isnan(campaign_runs.angular_entropy)));
verifyTrue(testCase,all(isnan(campaign_runs.radial_entropy)));
clear cleanup
end

function cleanupPaths(temporary_campaign, output_root)

if isfile(temporary_campaign)
    delete(temporary_campaign);
end

if isfolder(output_root)
    rmdir(output_root, "s");
end

end
