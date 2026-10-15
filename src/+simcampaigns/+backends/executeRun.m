function outcome = executeRun(config, backend, run_directory)
%EXECUTERUN Execute and save one backend-specific simulation run.
arguments
    config (1,1) struct
    backend {mustBeTextScalar}
    run_directory {mustBeTextScalar}
end
backend = lower(string(backend));
run_directory = string(run_directory);
switch backend
    case "kwsim"
        outcome = executeKwsim(config,run_directory);
    case "swsynth"
        swsynth.io.requireV2Config(config);
        outcome = simcampaigns.backends.executeSwsynthV2(config,run_directory);
    otherwise
        error("simcampaigns:UnsupportedBackend","Unsupported simulation campaign backend: %s",backend);
end
end

function outcome = executeKwsim(config,run_directory)
configured=config;
campaign_directory=string(fileparts(run_directory));
[~,run_name]=fileparts(run_directory);
if ~isfield(configured,"output") || ~isstruct(configured.output) || ~isscalar(configured.output)
    configured.output=struct();
end
configured.output.enabled=true;
configured.output.directory=campaign_directory;
configured.output.run_name=string(run_name);
configured.output.append_timestamp=false;
configured.output.overwrite=false;
config_file=writeTemporaryConfig(configured);
cleanup=onCleanup(@() deleteIfPresent(config_file));
outcome=kwsim.cli.runConfig(config_file);
clear cleanup
end

function config_file=writeTemporaryConfig(config)
config_file=string(tempname)+".json"; file_id=fopen(config_file,"w");
if file_id<0, error("simcampaigns:TemporaryConfigWriteFailed","Could not create a temporary run configuration."); end
cleanup=onCleanup(@() fclose(file_id)); fprintf(file_id,"%s",jsonencode(config,PrettyPrint=true)); clear cleanup
end
function deleteIfPresent(path_value)
if isfile(path_value), delete(path_value); end
end
