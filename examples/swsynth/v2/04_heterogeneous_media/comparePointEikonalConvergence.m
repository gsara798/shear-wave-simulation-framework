function result = comparePointEikonalConvergence(options)
%COMPAREPOINTEIKONALCONVERGENCE Grid convergence for two single-source examples.
% Read-only preflight by default. Does not change source example JSON files.
arguments
    options.Execute (1,1) logical = false
    options.OutputDirectory (1,1) string = ""
    options.GridSpacingsM (1,3) double = [.00075 .0005 .00025]
    options.MaxGridCells (1,1) double {mustBeInteger,mustBePositive} = 300000
end
folder=string(fileparts(mfilename("fullpath")));
names=["single_source_elastic_inclusion_x_projected3d.json", ...
    "single_source_elastic_bilayer_soft_top_x_projected3d.json"];
h=double(options.GridSpacingsM);
assert(isequal(h,[.00075 .0005 .00025]), ...
    "swsynth:ConvergenceSweep","Use 0.75, 0.5 and 0.25 mm.");
root=string(fileparts(fileparts(fileparts(fileparts(folder)))));
out=options.OutputDirectory;
if out=="",out=fullfile(root,"outputs","swsynth","v2", ...
    "point_eikonal_convergence_v1");end
assert(~isfolder(out),"swsynth:ConvergenceImmutable", ...
    "Output directory already exists. Use another OutputDirectory.");
scenarios=cell(2,1);maps=cell(2,1);gridPoints=zeros(2,3);
for i=1:2
    cfg=jsondecode(fileread(fullfile(folder,names(i))));
    [scenario,meta]=swsynth.io.resolveConfigV2(cfg);
    assert(meta.valid && string(scenario.geometry)=="projected3d" && ...
        scenario.sources.count==1 && ...
        string(scenario.propagation.phase_method)=="eikonal", ...
        "swsynth:ConvergenceConfig");
    request=scenario.domain;request.geometry=scenario.geometry;
    medium=swsynth.medium.buildMaps(swsynth.domain.buildGrid(request), ...
        scenario.medium);
    source=double(scenario.sources.positions.position_xyz_m(1,:));
    x=double(medium.x_m(:)');z=double(medium.z_m(:));
    oy=double(scenario.domain.observation_y_m);
    for j=1:3
        d=h(j);
        spanX=max(x(end),source(1))-min(x(1),source(1))+4*d;
        spanZ=max(z(end),source(3))-min(z(1),source(3))+4*d;
        spanY=abs(oy-source(2))+4*d;
        gridPoints(i,j)=prod(max(3,ceil([spanX spanY spanZ]/d)+1));
    end
    scenarios{i}=scenario;maps{i}=medium;
end
assert(all(gridPoints(:)<=options.MaxGridCells), ...
    "swsynth:ConvergenceMemory", ...
    "Grid preflight exceeds MaxGridCells (%d required, cap %d).", ...
    max(gridPoints(:)),options.MaxGridCells);
result=struct("case_names",names,"spacings_m",h, ...
    "grid_points",gridPoints,"executed",false, ...
    "output_directory",out);
fprintf("Eikonal preflight (grid cells: rows=cases; columns=spacings):\n");
disp(array2table(gridPoints,"VariableNames",["h075","h050","h025"]));
if ~options.Execute
    fprintf("No solves or files written. Execute=true to run.\n");
    return
end
assert(mkdir(out),"swsynth:ConvergenceOutput");
for i=1:2
    scenario=scenarios{i};medium=maps{i};
    x=double(medium.x_m(:)');z=double(medium.z_m(:));
    source=double(scenario.sources.positions.position_xyz_m(1,:));
    oy=double(scenario.domain.observation_y_m);
    f=double(scenario.harmonic.frequency_hz);
    speed=double(medium.cs_map_zx);
    T=cell(1,3);elapsed=zeros(1,3);diagnostics=cell(1,3);
    for j=1:3
        opts=struct("GridSpacingM",h(j), ...
            "MaxGridCells",options.MaxGridCells, ...
            "MaximumIterations",200,"ToleranceS",1e-9);
        objects=scenario.medium.objects;
        if numel(objects)==1 && string(objects{1}.type)=="bilayer" ...
                && objects{1}.edge_sigma_m==0
            obj=objects{1};interfaceAngle=double(obj.normal_angle_rad);
            opts.SpeedInterfacePlane=struct( ...
                "normal_xyz",[cos(interfaceAngle) 0 sin(interfaceAngle)], ...
                "offset_m",double(obj.offset_m), ...
                "speed_negative_m_s", ...
                    double(scenario.medium.background_cs_m_s), ...
                "speed_positive_m_s",double(obj.cs_m_s));
        end
        started=tic;
        [T{j},loss,diagnostics{j}]= ...
            swsynth.propagation.spherical.point_source.eikonal.solveExtended( ...
                speed,zeros(size(speed)),x,z,source,oy,opts);
        elapsed(j)=toc(started);
        assert(all(isfinite(T{j}(:))) && all(T{j}(:)>=0) && ...
            all(loss(:)==0) && diagnostics{j}.solver.converged, ...
            "swsynth:ConvergenceInvalid");
        fprintf("%s | %.2f mm | %.1f s\n",names(i),h(j)*1000,elapsed(j));
    end
    [Z,X]=ndgrid(z,x);
    r=sqrt((X-source(1)).^2+(oy-source(2)).^2+ ...
        (Z-source(3)).^2);
    nX=(X-source(1))./r;
    nY=(oy-source(2))./r;
    nZ=(Z-source(3))./r;
    force=double(scenario.sources.excitation.force_direction_xyz(1,:));
    axial=force(3)-nZ.*(nX*force(1)+nY*force(2)+nZ*force(3));
    % Exclude axial radiation nulls; arbitrary global amplitude cancels.
    valid=abs(axial)>=.05*max(abs(axial(:)));
    assert(nnz(valid)>100,"swsynth:ConvergenceEmptyMask");
    pair=["0.75 vs 0.5";"0.5 vs 0.25";"0.75 vs 0.25"];
    left=[1 2 1];right=[2 3 3];
    median_abs_dt_us=zeros(3,1);p95_abs_dt_us=zeros(3,1);
    max_abs_dt_us=zeros(3,1);median_abs_phase_rad=zeros(3,1);
    p95_abs_phase_rad=zeros(3,1);phasor_rms_difference=zeros(3,1);
    for k=1:3
        A=T{left(k)};B=T{right(k)};
        delta=A(valid)-B(valid);
        dt=abs(delta)*1e6;
        phase=abs(angle(exp(1i*2*pi*f*delta)));
        median_abs_dt_us(k)=median(dt);
        p95_abs_dt_us(k)=prctile(dt,95);
        max_abs_dt_us(k)=max(dt);
        median_abs_phase_rad(k)=median(phase);
        p95_abs_phase_rad(k)=prctile(phase,95);
        phasor_rms_difference(k)= ...
            sqrt(mean(abs(exp(1i*2*pi*f*delta)-1).^2));
    end
    comparisons=table(pair,median_abs_dt_us,p95_abs_dt_us, ...
        max_abs_dt_us,median_abs_phase_rad,p95_abs_phase_rad, ...
        phasor_rms_difference);
    stem=erase(names(i),".json");
    writetable(comparisons,fullfile(out,stem+"_metrics.csv"));
    spacing_mm=reshape(h,[],1)*1000;
    grid_points=reshape(gridPoints(i,:),[],1);
    elapsed_s=reshape(elapsed,[],1);
    assert(numel(spacing_mm)==3 && numel(grid_points)==3 && ...
        numel(elapsed_s)==3,"swsynth:ConvergenceRuntimeShape");
    runtime=table(spacing_mm,grid_points,elapsed_s);
    writetable(runtime,fullfile(out,stem+"_runtime.csv"));
    save(fullfile(out,stem+"_diagnostics.mat"), ...
        "T","x","z","valid","diagnostics","runtime","comparisons","-v7.3");
    fig=figure("Visible","off","Color","w","Position",[25 25 1300 740]);
    layout=tiledlayout(fig,2,3,"Padding","compact");
    for j=1:3
        ax=nexttile(layout);
        imagesc(ax,x*1000,z*1000,T{j}*1e3);
        set(ax,"YDir","normal");axis(ax,"image");colorbar(ax);
        title(ax,sprintf("First arrival (ms), h=%.2f mm",h(j)*1000));
        xlabel(ax,"x (mm)");ylabel(ax,"z (mm)");
    end
    for k=1:3
        ax=nexttile(layout);
        A=T{left(k)};B=T{right(k)};
        difference=(A-B)*1e6;difference(~valid)=NaN;
        imagesc(ax,x*1000,z*1000,difference);
        set(ax,"YDir","normal");axis(ax,"image");colorbar(ax);
        title(ax,pair(k)+" | difference (microseconds)");
        xlabel(ax,"x (mm)");ylabel(ax,"z (mm)");
    end
    sgtitle(layout,stem,"Interpreter","none");
    exportgraphics(fig,fullfile(out,stem+"_convergence.png"), ...
        "Resolution",150);close(fig);
    result.cases(i).name=names(i);
    result.cases(i).runtime=runtime;
    result.cases(i).comparisons=comparisons;
end
result.executed=true;
save(fullfile(out,"summary.mat"),"result");
fprintf("Finished: %s\n",out);
fprintf("Finest grid is a reference, NOT exact physical truth.\n");
end
