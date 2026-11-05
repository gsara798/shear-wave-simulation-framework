function tests = test_swsynth_elastic_point_eikonal_v2
% Tests for new lossless heterogeneous point sources in projected3d.
tests=functiontests(localfunctions);
end

function testUniformExtendedTravelTime(tc)
addFrameworkPath();
x=0:.001:.012;
z=(0:.001:.012)';
cs=2*ones(numel(z),numel(x));
alpha=zeros(size(cs));
src=[-.004,-.002,.006];
opts=struct("GridSpacingM",.001,"MaxGridCells",100000, ...
    "MaximumIterations",150,"ToleranceS",1e-9);
[T,A,diag]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
    cs,alpha,x,z,src,0,opts);
[Z,X]=ndgrid(z,x);
truth=sqrt((X-src(1)).^2+src(2)^2+(Z-src(3)).^2)/2;
verifyTrue(tc,diag.solver.converged);
verifyLessThan(tc,median(abs(T(:)-truth(:))),7e-4);
verifyEqual(tc,A,zeros(size(A)),"AbsTol",1e-12);
end

function testBilayerChangesFirstArrival(tc)
addFrameworkPath();
x=0:.001:.012;
z=(0:.001:.012)';
reference=2*ones(numel(z),numel(x));
layer=reference;layer(:,x>.006)=3;
alpha=zeros(size(layer));
src=[-.003,0,.006];
options=struct("GridSpacingM",.001,"MaxGridCells",100000, ...
    "MaximumIterations",150,"ToleranceS",1e-9);
[T0,A0]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
    reference,alpha,x,z,src,0,options);
[T1,A1]=swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
    layer,alpha,x,z,src,0,options);
verifyEqual(tc,A0,zeros(size(A0)),"AbsTol",1e-12);
verifyEqual(tc,A1,zeros(size(A1)),"AbsTol",1e-12);
verifyLessThan(tc,T1(7,end),T0(7,end));
verifyGreaterThan(tc,abs(T1(7,end)-T0(7,end)),1e-4);
end

function testElasticHeterogeneousConfigs(tc)
root=addFrameworkPath();
folder=fullfile(root,"examples","swsynth","v2","04_heterogeneous_media");
names=["point_source_elastic_bilayer_projected3d.json", ...
    "point_source_elastic_inclusion_projected3d.json"];
for name=names
    file=fullfile(folder,name);
    cfg=jsondecode(fileread(file));
    validation=simrunner.runConfig(file,DryRun=true);
    verifyEqual(tc,string(validation.status),"dry_run_valid");
    verifyTrue(tc,logical(validation.validation.valid));
    verifyEqual(tc,cfg.domain.Lx_m,.024,"AbsTol",1e-12);
    verifyEqual(tc,cfg.domain.Lz_m,.024,"AbsTol",1e-12);
    verifyEqual(tc,cfg.domain.dx_m,.0002,"AbsTol",1e-12);
    verifyEqual(tc,cfg.domain.dz_m,.0002,"AbsTol",1e-12);
    verifyEqual(tc,cfg.propagation.solver_options.GridSpacingM,.0005, ...
        "AbsTol",1e-12);
    verifyTrue(tc,all(cfg.sources.positions.position_xyz_m(:,1)<0 | ...
        cfg.sources.positions.position_xyz_m(:,1)>.024));
    if contains(name,"inclusion")
        verifyEqual(tc,cfg.medium.objects.radius_m,.005,"AbsTol",1e-12);
    else
        verifyEqual(tc,cfg.medium.objects.offset_m,.012,"AbsTol",1e-12);
    end
    verifyFalse(tc,isfield(cfg.propagation,"attenuation"));
    [scenario,meta]=swsynth.io.resolveConfigV2(cfg);
    verifyTrue(tc,meta.valid);
    out=swsynth.propagation.synthesize(scenario);
    verifyEqual(tc,string(out.propagation.phase_method),"eikonal");
    verifyTrue(tc,all(isfinite(out.U_xyz(:))));
    verifyGreaterThan(tc,max(abs(out.U_xyz(:))),1e-8);
    verifyGreaterThan(tc,numel(unique(out.medium.cs_map_zx)),1);
    verifyEqual(tc,out.component_count,2);
    S=swsynth.io.buildWavefieldSampleV2(out,scenario);
    verifyTrue(tc,S.validation.analysis_ready);
    verifyEqual(tc,numel(unique(S.truth.material_id_zx)),2);
end
end

function testHomogeneousElasticDoesNotRequireViscoelasticMaterial(tc)
root=addFrameworkPath();
file=fullfile(root,"examples","swsynth","v2", ...
    "04_heterogeneous_media","point_source_elastic_bilayer_projected3d.json");
cfg=jsondecode(fileread(file));
cfg.medium=struct("cs_m_s",2,"objects",[]);
cfg.sources.count=1;
cfg.sources.positions.position_xyz_m=[-.004,0,.006];
cfg.sources.excitation.force_direction_xyz=[0,0,1];
cfg.sources.excitation.relative_amplitude=1;
cfg.sources.excitation.phase_rad=0;
[scenario,~]=swsynth.io.resolveConfigV2(cfg);
out=swsynth.propagation.synthesize(scenario);
verifyTrue(tc,all(isfinite(out.U_xyz(:))));
verifyGreaterThan(tc,max(abs(out.U_xyz(:))),0);
end

function testSingleSourceExamplesGeometryAndMaterial(tc)
root=addFrameworkPath();
folder=fullfile(root,"examples","swsynth","v2","04_heterogeneous_media");
names=["single_source_elastic_inclusion_x_projected3d.json", ...
    "single_source_elastic_bilayer_soft_top_x_projected3d.json"];
for name=names
    file=fullfile(folder,name);
    dry=simrunner.runConfig(file,DryRun=true);
    verifyEqual(tc,string(dry.status),"dry_run_valid");
    cfg=jsondecode(fileread(file));
    verifyEqual(tc,cfg.sources.count,1);
    verifyEqual(tc,cfg.sources.positions.position_xyz_m(1),-.006, ...
        "AbsTol",1e-12);
    verifyEqual(tc,cfg.sources.positions.position_xyz_m(2),0, ...
        "AbsTol",1e-12);
    verifyEqual(tc,cfg.domain.Lx_m,.024,"AbsTol",1e-12);
    verifyEqual(tc,cfg.propagation.solver_options.GridSpacingM,.0005, ...
        "AbsTol",1e-12);
    [scenario,~]=swsynth.io.resolveConfigV2(cfg);
    req=scenario.domain;
    req.geometry=scenario.geometry;
    grid=swsynth.domain.buildGrid(req);
    maps=swsynth.medium.buildMaps(grid,scenario.medium);
    cs=maps.cs_map_zx;
    verifyEqual(tc,numel(unique(cs)),2);
    if contains(name,"bilayer")
        % Plot z increases upward: soft (2 m/s) above 12 mm,
        % hard (3 m/s) below, and source 2 mm above interface.
        verifyEqual(tc,cs(1,:),3*ones(1,size(cs,2)), ...
            "AbsTol",1e-12);
        verifyEqual(tc,cs(end,:),2*ones(1,size(cs,2)), ...
            "AbsTol",1e-12);
        verifyEqual(tc,cfg.sources.positions.position_xyz_m(3),.014, ...
            "AbsTol",1e-12);
        verifyEqual(tc,cfg.medium.objects.offset_m,.012, ...
            "AbsTol",1e-12);
    else
        verifyEqual(tc,cfg.medium.objects.radius_m,.005, ...
            "AbsTol",1e-12);
    end
end
end

function testAnalyticalStillRejectsHeterogeneousPointMedia(tc)
root=addFrameworkPath();
cfg=jsondecode(fileread(fullfile(root,"examples","swsynth","v2", ...
    "04_heterogeneous_media","point_source_elastic_bilayer_projected3d.json")));
cfg.propagation.phase_method="analytical";
% Reject at the public V2 configuration-validation boundary, before
% synthesis. The resolver intentionally blocks analytical heterogeneity.
verifyError(tc,@()swsynth.io.resolveConfigV2(cfg), ...
    "swsynth:V2AnalyticalRequiresHomogeneous");
end

function root=addFrameworkPath()
root=fileparts(fileparts(fileparts(mfilename("fullpath"))));
addpath(fullfile(root,"src"));
end
