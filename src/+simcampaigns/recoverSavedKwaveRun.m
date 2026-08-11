function recovery=recoverSavedKwaveRun(campaign_file,ordinal)
%RECOVERSAVEDKWAVERUN Adopt a saved, revalidated k-Wave campaign run.
% This is intentionally strict and is only for runs whose solver products
% were saved before a post-processing/validation exception prevented the
% campaign completion marker from being published.
arguments
    campaign_file {mustBeTextScalar}
    ordinal (1,1) double {mustBeInteger,mustBePositive}
end

[runs,expansion]=simcampaigns.expandCampaign(campaign_file);
if ordinal>numel(runs)
    error("simcampaigns:InvalidRecoveryOrdinal", ...
        "Recovery ordinal %d exceeds campaign run count %d.",ordinal,numel(runs));
end
run=runs(ordinal);
if string(run.backend)~="kwsim"
    error("simcampaigns:UnsupportedRecoveryBackend", ...
        "Saved-result recovery currently supports only kwsim runs.");
end

campaign_root=string(expansion.campaign.output.directory);
if ~is_absolute(campaign_root)
    campaign_root=fullfile(string(expansion.repository_root),campaign_root);
end
run_directory=fullfile(campaign_root,string(expansion.campaign.campaign_name),run.run_id);
marker_file=fullfile(run_directory,"campaign_run.json");
if isfile(marker_file)
    error("simcampaigns:RecoveryMarkerExists", ...
        "Run already has a campaign completion marker: %s",marker_file);
end
data_directory=fullfile(run_directory,"data");
result_file=fullfile(data_directory,"result.mat");
sample_file=fullfile(data_directory,"wavefield_sample.mat");
if ~isfile(result_file) || ~isfile(sample_file)
    error("simcampaigns:IncompleteSavedKwaveRun", ...
        "Recovery requires saved result.mat and wavefield_sample.mat in %s.",data_directory);
end

loaded=load(result_file,"result");
result=loaded.result;
verify_identity(result,run,run_directory);
kind=kwsim.validation.classify3DValidationScenario( ...
    result.config_resolved.scenario);
switch kind
    case "multi_source_homogeneous"
        report=kwsim.validation.evaluateMultiSourceHarmonic3D(result);
    case "heterogeneous_harmonic"
        report=kwsim.validation.evaluateHeterogeneousHarmonic3D(result);
    case "directional_homogeneous"
        report=kwsim.validation.evaluateDirectionalHarmonic3D(result);
    otherwise
        error("simcampaigns:UnsupportedSavedKwaveValidation", ...
            "No recovery validator is registered for scenario '%s'.", ...
            result.config_resolved.scenario);
end
if ~report.valid
    failed=strjoin(string({report.checks(~[report.checks.pass]).name}),", ");
    error("simcampaigns:SavedKwaveRevalidationFailed", ...
        "Saved k-Wave run remains invalid: %s.",failed);
end

result.valid=true;
result.diagnostics=report;
save(result_file,"result","-v7.3");
kwsim.io.saveValidationReport(report,data_directory,Overwrite=true);
quantity="displacement";
if isfield(result.config_resolved,"wavefield_sample") && ...
        isfield(result.config_resolved.wavefield_sample,"quantity")
    quantity=string(result.config_resolved.wavefield_sample.quantity);
end
sample=kwsim.samples.buildWavefieldSample(result,Quantity=quantity);
kwsim.samples.saveWavefieldSample(sample,data_directory,Overwrite=true);

marker=struct("schema_version","1.0","status","completed", ...
    "ordinal",run.ordinal,"design_id",run.design_id, ...
    "condition_id",run.condition_id,"realization_id",run.realization_id, ...
    "run_id",run.run_id,"backend",run.backend, ...
    "hash_sha256",run.hash_sha256,"outcome_status","completed_valid", ...
    "completed",string(datetime("now","Format","yyyy-MM-dd HH:mm:ss Z")), ...
    "recovered_from_saved_result",true);
write_json_atomically(marker_file,marker);
recovery=struct("run_directory",run_directory,"marker_file",marker_file, ...
    "result_file",result_file,"wavefield_sample_file",sample_file, ...
    "validation_report",report,"hash_sha256",run.hash_sha256);
end

function verify_identity(result,run,run_directory)
if ~isfield(result,"config_requested") || ~isfield(result,"config_resolved")
    error("simcampaigns:SavedKwaveIdentityMismatch", ...
        "Saved result lacks requested/resolved configuration provenance.");
end
expected=run.config; actual=result.config_requested;
fields=["scenario","seed","dimension"];
for field=fields
    if ~isfield(expected,field) || ~isfield(actual,field) || ...
            ~isequal(string(actual.(field)),string(expected.(field)))
        error("simcampaigns:SavedKwaveIdentityMismatch", ...
            "Saved result field '%s' does not match campaign run %s.",field,run.run_id);
    end
end
saved_run_directory=fullfile( ...
    string(result.config_resolved.output.directory), ...
    string(result.config_resolved.output.run_name));
if canonical_path(saved_run_directory)~=canonical_path(run_directory)
    error("simcampaigns:SavedKwaveIdentityMismatch", ...
        "Saved result output directory does not match campaign run identity.");
end
end

function value=canonical_path(value)
value=string(char(java.io.File(char(string(value))).getCanonicalPath()));
end

function write_json_atomically(path,value)
temporary=string(path)+".tmp";
fid=fopen(temporary,"w");
if fid<0, error("simcampaigns:RecoveryWriteFailed","Cannot create %s.",temporary); end
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,"%s",jsonencode(value,PrettyPrint=true)); clear cleanup
[moved,message]=movefile(temporary,path,"f");
if ~moved
    error("simcampaigns:RecoveryWriteFailed","Cannot publish %s: %s",path,message);
end
end

function tf=is_absolute(path)
characters=char(string(path));
if ispc
    tf=~isempty(regexp(characters,'^[A-Za-z]:[\\/]|^\\\\','once'));
else
    tf=startsWith(characters,filesep);
end
end
