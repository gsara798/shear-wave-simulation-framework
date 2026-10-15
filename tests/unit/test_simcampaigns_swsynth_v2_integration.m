function tests=test_simcampaigns_swsynth_v2_integration
tests=functiontests(localfunctions);
end

function setupOnce(tc)
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
tc.TestData.root=string(root);
end

function testV2ConfigUsesModularDryRunWithoutRngSideEffects(tc)
cfgFile=fullfile(tc.TestData.root,"configs","swsynth","v2", ...
    "homogeneous_plane_base.json");
config=jsondecode(fileread(cfgFile));
before=rng;
o=simcampaigns.backends.validateRun(config,"swsynth");
verifyEqual(tc,o.status,"dry_run_valid");
verifyEqual(tc,o.implementation,"modular_v2");
verifyEqual(tc,o.validation.frequency_hz,500);
verifyEqual(tc,o.validation.dimension,2);
verifyEqual(tc,rng,before);
end

function testFlatJsonXYZVectorsAreNormalizedButMatricesPreserved(tc)
% MATLAB jsondecode may represent [x,y,z] as 3-by-1; the new V2
% boundary must normalize only singleton vectors, never an N-by-3 set.
file=fullfile(tc.TestData.root,"configs","swsynth","v2", ...
    "projected3d_heterogeneous_eikonal.json");
cfg=jsondecode(fileread(file));
[scenario,meta]=swsynth.io.resolveConfigV2(cfg);
verifyEqual(tc,size(scenario.incidence.direction_xyz),[1 3]);
verifyEqual(tc,scenario.incidence.direction_xyz,[1 0 0]);
verifyEqual(tc,meta.measurement_axis_xyz,[0 0 1]);
r=swsynth.propagation.synthesize(scenario);
sample=swsynth.io.buildWavefieldSampleV2(r,scenario, ...
    struct("measurement_axis_xyz",meta.measurement_axis_xyz));
wavefield.validateSample(sample);

% The multi-direction configuration still has N-by-3 incidences.
file=fullfile(tc.TestData.root,"configs","swsynth","v2", ...
    "homogeneous_plane_base.json");
[scenario,meta]=swsynth.io.resolveConfigV2( ...
    jsondecode(fileread(file)));
verifyEqual(tc,size(scenario.incidence.direction_xyz),[2 3]);
verifyEqual(tc,scenario.incidence.direction_xyz,[1 0 0;-1 0 0]);
verifyEqual(tc,meta.measurement_axis_xyz,[0 0 1]);
end

function testV2CampaignFourRunsSaveCorrectWavefieldContractAndResume(tc)
src=fullfile(tc.TestData.root,"configs","campaigns","swsynth", ...
    "smoke","swsynth_v2_homogeneous_smoke.json");
request=jsondecode(fileread(src));
dirPath=string(tempname);
request.output.directory=dirPath;
tmp=string(tempname)+".json";
writeTestJson(tmp,request);
guard=onCleanup(@() clean(tmp,dirPath));
before=rng;
[runs,validation]=simcampaigns.validateCampaign(tmp);
verifyTrue(tc,validation.valid);
verifyEqual(tc,validation.run_count,4);
verifyEqual(tc,numel(runs),4);
verifyEqual(tc,string(runs(1).config.schema_version),"2.0");
verifyEqual(tc,rng,before);

report=simcampaigns.runCampaign(tmp, ...
    Resume=true,ContinueOnError=false);
verifyTrue(tc,report.success);
verifyEqual(tc,report.completed_count,4);
verifyEqual(tc,report.failed_count,0);
for i=1:numel(report.runs)
    runDir=string(report.runs(i).run_directory);
    samplePath=fullfile(runDir,"data","wavefield_sample.mat");
    summaryPath=fullfile(runDir,"data","run_summary.json");
    verifyTrue(tc,isfile(samplePath));
    verifyTrue(tc,isfile(summaryPath));
    verifyTrue(tc,isfile(fullfile(runDir,"config","resolved_config.json")));
    verifyTrue(tc,isfile(fullfile(runDir, ...
        "validation","validation_report.json")));
    loaded=load(samplePath,"wavefield_sample");
    sample=loaded.wavefield_sample;
    wavefield.validateSample(sample);
    [~,expectedRunId]=fileparts(runDir);
    verifyEqual(tc,sample.sample_id,string(expectedRunId));
    verifyEqual(tc,sample.provenance.run_id,string(expectedRunId));
    summary=jsondecode(fileread(summaryPath));
    verifyEqual(tc,string(summary.implementation),"modular_v2");
    verifyEqual(tc,string(sample.generator.backend),"fast_synthetic_v2");
    verifyEqual(tc,string(summary.backend),"swsynth");
    verifyEqual(tc,string(sample.propagation.phase_model),"analytical");
    verifyEqual(tc,double(sample.wavefield.frequency_hz), ...
        double(summary.frequency_hz));
    verifyEqual(tc,double(sample.truth.cs_map_zx(1,1)), ...
        double(summary.background_cs_m_s));
    verifyEqual(tc,double(sample.truth.k_map_zx(1,1)), ...
        2*pi*summary.frequency_hz/summary.background_cs_m_s, ...
        "AbsTol",1e-12);
    verifyTrue(tc,any(abs(sample.wavefield.data_zx(:))>0));
end
verifyEqual(tc,rng,before);
second=simcampaigns.runCampaign(tmp, ...
    Resume=true,ContinueOnError=false);
verifyTrue(tc,second.success);
verifyEqual(tc,second.skipped_count,4);
verifyEqual(tc,second.completed_count,0);
clear guard
end

function testSimrunnerDetectsAndExecutesV2DirectConfig(tc)
cfgFile=fullfile(tc.TestData.root,"configs","swsynth","v2", ...
    "homogeneous_plane_base.json");
dry=simrunner.runConfig(cfgFile,DryRun=true);
verifyEqual(tc,dry.backend,"swsynth");
verifyEqual(tc,dry.implementation,"modular_v2");
outPath=string(tempname);
guard=onCleanup(@() clean("",outPath));
out=simrunner.runConfig(cfgFile, ...
    OutputRoot=outPath,PlotFigures=false,GeneratePdf=false);
verifyEqual(tc,string(out.backend),"swsynth");
verifyEqual(tc,string(out.implementation),"modular_v2");
verifyTrue(tc,isfile(out.paths.wavefield_sample));
loaded=load(out.paths.wavefield_sample,"wavefield_sample");
wavefield.validateSample(loaded.wavefield_sample);
clear guard
end

function testV2FiguresUseSavedWavefieldSample(tc)
cfgFile=fullfile(tc.TestData.root,"configs","swsynth","v2", ...
    "homogeneous_plane_base.json");
outputRoot=string(tempname);
guard=onCleanup(@() clean("",outputRoot));
out=simrunner.runConfig(cfgFile,OutputRoot=outputRoot, ...
    PlotFigures=true,FigureVisible="off",GeneratePdf=false);
verifyTrue(tc,isfile(out.paths.wavefield_sample));
verifyTrue(tc,isfile(fullfile(out.paths.run,"figures","sws.png")));
verifyTrue(tc,isfile(fullfile(out.paths.run, ...
    "figures","wavefield_real.png")));
verifyTrue(tc,isfile(fullfile(out.paths.run, ...
    "figures","wavefield_phase.png")));
clear guard
end

function testSeededRandomSphericalV2RunIsReproducible(tc)
cfgFile=fullfile(tc.TestData.root,"configs","swsynth","v2", ...
    "two_sources_projected3d.json");
config=jsondecode(fileread(cfgFile));
before=rng;
root=string(tempname);
mkdir(root);
guard=onCleanup(@() clean("",root));
first=simcampaigns.backends.executeRun(config,"swsynth", ...
    fullfile(root,"first"));
second=simcampaigns.backends.executeRun(config,"swsynth", ...
    fullfile(root,"second"));
a=load(first.paths.wavefield_sample,"wavefield_sample");
b=load(second.paths.wavefield_sample,"wavefield_sample");
wavefield.validateSample(a.wavefield_sample);
wavefield.validateSample(b.wavefield_sample);
verifyEqual(tc,a.wavefield_sample.wavefield.data_zx, ...
    b.wavefield_sample.wavefield.data_zx);
verifyEqual(tc,a.wavefield_sample.excitation.phase_rad, ...
    b.wavefield_sample.excitation.phase_rad);
verifyEqual(tc,a.wavefield_sample.seed,53053);
verifyEqual(tc,a.wavefield_sample.sources.count,2);
verifyEqual(tc,a.wavefield_sample.directions.retained_count,0);
verifyEqual(tc,rng,before);
clear guard
end

function testHeterogeneousPlaneEikonalUsesV2InBoth3DGeometries(tc)
root=string(tempname);
mkdir(root);
guard=onCleanup(@() clean("",root));
fixtures=["projected3d_heterogeneous_eikonal", ...
    "volumetric3d_heterogeneous_eikonal"];
for i=1:numel(fixtures)
    file=fullfile(tc.TestData.root,"configs","swsynth","v2", ...
        fixtures(i)+".json");
    cfg=jsondecode(fileread(file));
    dry=simcampaigns.backends.validateRun(cfg,"swsynth");
    verifyEqual(tc,dry.status,"dry_run_valid");
    verifyEqual(tc,dry.validation.phase_method,"eikonal");
    out=simcampaigns.backends.executeRun(cfg,"swsynth", ...
        fullfile(root,fixtures(i)));
    verifyEqual(tc,out.implementation,"modular_v2");
    loaded=load(out.paths.wavefield_sample,"wavefield_sample");
    sample=loaded.wavefield_sample;
    wavefield.validateSample(sample);
    verifyEqual(tc,sample.propagation.phase_model,"eikonal");
    if i==1
        verifyEqual(tc,sample.spatial_dimension,2);
        verifyEqual(tc,sample.truth.cs_map_zx(5,5),3);
        verifyEqual(tc,sample.truth.cs_map_zx(1,1),2);
    else
        verifyEqual(tc,sample.spatial_dimension,3);
        verifyEqual(tc,sample.truth.cs_map_zyx(4,4,4),3);
        verifyEqual(tc,sample.truth.cs_map_zyx(1,1,1),2);
    end
end
clear guard
end

function testDryRunRejectsMalformedV2BeforeCampaignWrites(tc)
cfgFile=fullfile(tc.TestData.root,"configs","swsynth","v2", ...
    "homogeneous_plane_base.json");
base=jsondecode(fileread(cfgFile));
bad=base;
bad.incidence.direction_xyz=[0 0 0;0 0 1];
verifyError(tc, ...
    @() simcampaigns.backends.validateRun(bad,"swsynth"), ...
    "swsynth:V2InvalidIncidentWaves");

bad=base;
bad.propagation.phase_method="eikonal";
verifyError(tc, ...
    @() simcampaigns.backends.validateRun(bad,"swsynth"), ...
    "swsynth:V2UnsupportedPhase");

bad=base;
bad.medium.objects=struct("type","circle", ...
    "cs_m_s",4,"center_xz_m",[.005 .005],"radius_m",.001);
verifyError(tc, ...
    @() simcampaigns.backends.validateRun(bad,"swsynth"), ...
    "swsynth:V2AnalyticalRequiresHomogeneous");
end

function testUnseededStochasticCampaignRejectedInDryRun(tc)
file=fullfile(tc.TestData.root,"configs","swsynth","v2", ...
    "two_sources_projected3d.json");
config=jsondecode(fileread(file));
config=rmfield(config,"seed");
verifyError(tc,@() simcampaigns.backends.validateRun(config,"swsynth"), ...
    "swsynth:V2SeedRequired");
end

function testLegacySwsynthConfigRejectedWithoutLegacyFallback(tc)
file=fullfile(tc.TestData.root,"configs","swsynth","v2", ...
    "homogeneous_plane_base.json");
legacy=jsondecode(fileread(file));
legacy=rmfield(legacy,"schema_version");
verifyError(tc,@() simcampaigns.backends.validateRun(legacy,"swsynth"), ...
    "swsynth:LegacyConfigUnsupported");
verifyError(tc,@() simcampaigns.backends.executeRun(legacy,"swsynth", ...
    string(tempname)), ...
    "swsynth:LegacyConfigUnsupported");
end


function testLegacySwsynthRejectedByEveryPublicV2Entry(testCase)
file=fullfile(testCase.TestData.root,"configs","swsynth","v2", ...
    "homogeneous_plane_base.json");
legacy=jsondecode(fileread(file));
legacy=rmfield(legacy,"schema_version");
tempFile=string(tempname)+".json";
writeTestJson(tempFile,legacy);
guard=onCleanup(@() clean(tempFile,""));
verifyError(testCase, ...
    @() simcampaigns.backends.loadBaseConfig(tempFile,"swsynth"), ...
    "swsynth:LegacyConfigUnsupported");
verifyError(testCase, ...
    @() simrunner.runConfig(tempFile,DryRun=true,Backend="swsynth"), ...
    "swsynth:LegacyConfigUnsupported");
clear guard
end

function writeTestJson(file,value)
fid=fopen(file,"w");
if fid<0; error("test:WriteFailed","Cannot create campaign.");end
c=onCleanup(@() fclose(fid));
fprintf(fid,"%s",jsonencode(value,PrettyPrint=true));
clear c
end

function clean(tempFile,outputRoot)
if strlength(string(tempFile))>0 && isfile(tempFile)
    delete(tempFile);
end
if strlength(string(outputRoot))>0 && isfolder(outputRoot)
    rmdir(outputRoot,"s");
end
end
