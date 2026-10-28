function outcome = executeSwsynthV2(config,runDirectory)
%EXECUTESWSYNTHV2 Save one modular swsynth run in simcampaigns layout.
% Explicit schema_version=2.0 prevents legacy backend dispatch.
arguments
    config (1,1) struct
    runDirectory {mustBeTextScalar}
end
[scenario,meta]=swsynth.io.resolveConfigV2(config);
runDirectory=string(runDirectory);
if isfolder(runDirectory)
    error("simcampaigns:RunDirectoryExists", ...
        "Run directory already exists: %s",runDirectory);
end
configDir=fullfile(runDirectory,"config");
dataDir=fullfile(runDirectory,"data");
figureDir=fullfile(runDirectory,"figures");
validationDir=fullfile(runDirectory,"validation");
[ok,msg]=mkdir(dataDir);
if ~ok
    error("simcampaigns:DirectoryCreateFailed","%s",msg);
end
mkdir(configDir);
mkdir(figureDir);
mkdir(validationDir);
try
    % Seed both deterministic and stochastic source policies while leaving
    % the caller's global RNG unchanged. Source stream support can replace
    % this scoped wrapper in a later refactor.
    if ~isempty(meta.seed)
        originalRng=rng;
        rngCleanup=onCleanup(@() rng(originalRng)); %#ok<NASGU>
        rng(meta.seed,"twister");
    end
    started=tic;
    synthesis=swsynth.propagation.synthesize(scenario);
    elapsed=toc(started);
    if exist("rngCleanup","var")
        clear rngCleanup
    end

    sampleOptions=struct("measurement_axis_xyz", ...
        meta.measurement_axis_xyz,"scenario_name",meta.scenario_name);
    if ~isempty(meta.seed)
        sampleOptions.seed=meta.seed;
    end
    wavefield_sample=swsynth.io.buildWavefieldSampleV2( ...
        synthesis,scenario,sampleOptions);
    % Separate post-projection observation stages. Propagation is performed
    % only once; the clean reference is preserved for paired noise studies.
    noiseDiag=struct("enabled",false,"model","none");
    readoutDiag=struct("enabled",false,"model","none");
    cleanShear=[];
    preReadoutShear=[];
    hasShear=isfield(config,"shear_noise") && config.shear_noise.enabled;
    hasReadout=isfield(config,"readout_noise") && config.readout_noise.enabled;
    if hasShear || hasReadout
        fieldName="data_zx";
        spacing=[synthesis.domain.dz_m,synthesis.domain.dx_m];
        if string(scenario.geometry)=="volumetric3d"
            fieldName="data_zyx";
            spacing=[synthesis.domain.dz_m,synthesis.domain.dy_m,synthesis.domain.dx_m];
        end
        cleanShear=wavefield_sample.wavefield.(fieldName);
        preReadoutShear=cleanShear;
        if hasShear
            shearSeed=meta.seed;
            if isfield(config.shear_noise,"seed")
                shearSeed=double(config.shear_noise.seed);
            end
            [preReadoutShear,noiseDiag]=swsynth.noise.applyShearNoise( ...
                cleanShear,config.shear_noise,spacing,shearSeed);
            wavefield_sample.provenance.shear_noise=noiseDiag;
        end
        measuredShear=preReadoutShear;
        if hasReadout
            readoutSeed=meta.seed;
            if isfield(config.readout_noise,"seed")
                readoutSeed=double(config.readout_noise.seed);
            end
            [measuredShear,readoutDiag]= ...
                swsynth.observation.readout.applyDisplacementNoise( ...
                preReadoutShear,config.readout_noise,spacing, ...
                synthesis.domain.z_m,meta.frequency_hz,readoutSeed);
            wavefield_sample.provenance.readout_noise=readoutDiag;
        end
        wavefield_sample.wavefield.(fieldName)=measuredShear;
        wavefield_sample.wavefield.is_complex=~isreal(measuredShear);
        if hasShear && hasReadout
            wavefield_sample.measurement.model= ...
                "signed_vector_projection_with_shear_and_readout_noise";
        elseif hasShear
            wavefield_sample.measurement.model= ...
                "signed_vector_projection_with_shear_disturbance";
        else
            wavefield_sample.measurement.model= ...
                "signed_vector_projection_with_displacement_readout_noise";
        end
    end
    [~,runName]=fileparts(runDirectory);
    wavefield_sample.sample_id=string(runName);
    wavefield_sample.provenance.run_id=string(runName);
    info=wavefield.validateSample(wavefield_sample);
    validation=struct("valid",logical(wavefield_sample.validation.valid), ...
        "analysis_ready",logical(wavefield_sample.validation.analysis_ready), ...
        "scope","schema_and_finite_phasor_only", ...
        "physics_validated",false, ...
        "spatial_dimension",info.spatial_dimension, ...
        "array_order",info.array_order, ...
        "implementation","modular_v2");

    resolvedPath=fullfile(configDir,"resolved_config.json");
    validationPath=fullfile(validationDir,"validation_report.json");
    summaryPath=fullfile(dataDir,"run_summary.json");
    samplePath=fullfile(dataDir,"wavefield_sample.mat");

    writeJson(resolvedPath,config);
    writeJson(validationPath,validation);
    save(samplePath,"wavefield_sample","-v7.3");
    if ~isempty(cleanShear)
        save(fullfile(dataDir,"shear_clean_reference.mat"), ...
            "cleanShear","preReadoutShear","noiseDiag","readoutDiag","-v7.3");
    end

    count=double(synthesis.component_count);
    summary=struct("schema_version","1.0", ...
        "backend","swsynth","implementation","modular_v2", ...
        "status","completed_valid", ...
        "scenario",meta.scenario_name, ...
        "spatial_dimension",info.spatial_dimension, ...
        "frequency_hz",meta.frequency_hz, ...
        "background_cs_m_s",meta.background_cs_m_s, ...
        "medium_object_count",meta.material_object_count, ...
        "propagation_model",meta.model, ...
        "phase_model",meta.phase_method, ...
        "component_count",count, ...
        "direction_count",0, ...
        "retained_direction_count",0, ...
        "wavefield_size",info.expected_size, ...
        "elapsed_solver_time_s",elapsed, ...
        "valid",validation.valid, ...
        "analysis_ready",validation.analysis_ready, ...
        "measurement_axis_xyz",meta.measurement_axis_xyz);
    summary.shear_noise_enabled=logical(noiseDiag.enabled);
    if noiseDiag.enabled
        summary.shear_noise_snr_db=noiseDiag.snr_db;
        summary.shear_noise_relative_perturbation_norm=noiseDiag.relative_perturbation_norm;
    end
    summary.readout_noise_enabled=logical(readoutDiag.enabled);
    if readoutDiag.enabled
        summary.readout_noise_snr_db=readoutDiag.snr_db;
        summary.readout_noise_relative_perturbation_norm= ...
            readoutDiag.relative_perturbation_norm;
    end
    if ~isempty(cleanShear)
        totalDifference=wavefield_sample.wavefield.(fieldName)-cleanShear;
        if all(totalDifference(:)==0)
            summary.total_noise_snr_db=Inf;
        else
            summary.total_noise_snr_db=20*log10( ...
                norm(cleanShear(:))/max(norm(totalDifference(:)),eps));
        end
    end
    if meta.model=="plane_wave"
        summary.direction_count=count;
        summary.retained_direction_count=count;
    end
    if ~isempty(meta.seed)
        summary.seed=meta.seed;
    end
    writeJson(summaryPath,summary);

    outcome=struct("status","completed_valid", ...
        "backend","swsynth","implementation","modular_v2", ...
        "valid",validation.valid, ...
        "paths",struct("run",runDirectory, ...
            "resolved_config",resolvedPath, ...
            "validation_report",validationPath, ...
            "summary",summaryPath, ...
            "wavefield_sample",samplePath, ...
            "figures",figureDir));
catch err
    if isfolder(runDirectory)
        rmdir(runDirectory,"s");
    end
    rethrow(err);
end
end

function writeJson(path,value)
fid=fopen(path,"w");
if fid<0
    error("simcampaigns:V2JsonWriteFailed","Could not create %s.",path);
end
guard=onCleanup(@() fclose(fid));
fprintf(fid,"%s",jsonencode(value,PrettyPrint=true));
clear guard;
end

