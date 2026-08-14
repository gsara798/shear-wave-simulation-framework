function audit = auditGeometry(options)
%AUDITGEOMETRY Validate and plot all three SOURCE-X contact z positions.
% This is a geometry-only preflight and never calls k-Wave.

arguments
    options.OutputDirectory {mustBeTextScalar} = ""
end
root=string(fileparts(fileparts(fileparts(fileparts( ...
    mfilename('fullpath'))))));
config_root=fullfile(root,'configs','kwsim','two_d','benchmarks');
files=[ ...
    fullfile(config_root,'experimental_bilayer_400hz_source_polarization', ...
        'source_x_bilayer_soft_stiff_400hz.json'); ...
    fullfile(config_root,'experimental_bilayer_400hz_source_zposition', ...
        'source_x_bilayer_source_in_soft_400hz.json'); ...
    fullfile(config_root,'experimental_bilayer_400hz_source_zposition', ...
        'source_x_bilayer_source_in_stiff_400hz.json')];
names=["NEAR_INTERFACE";"SOURCE_IN_SOFT";"SOURCE_IN_STIFF"];
requested_z=[NaN;.0115;.0265]; expected_material=[1;1;2];
output=string(options.OutputDirectory);
if strlength(output)==0
    output=fullfile(root,'outputs','benchmarks', ...
        'experimental_bilayer_400hz_source_zposition','preflight');
end
if ~isfolder(output),mkdir(output);end

cfgs=cell(3,1); source_center_x_mm=zeros(3,1); source_center_z_mm=zeros(3,1);
contact_z_min_mm=zeros(3,1); contact_z_max_mm=zeros(3,1);
contact_to_interface_min_distance_mm=zeros(3,1); material_fraction=zeros(3,1);
distance_to_boundary_mm=zeros(3,1); distance_to_pml_outer_mm=zeros(3,1);
interface_z=.019;
for i=1:3
    requested=kwsim.io.loadConfigJson(files(i));
    [cfg,preflight]=kwsim.two_d.validateConfig(requested);
    if ~preflight.valid
        error('kwsim:SourceZPositionGeometryInvalid', ...
            'Geometry preflight failed for %s.',names(i));
    end
    cfgs{i}=cfg;
    z=(cfg.source.contact_z_indices-1)*cfg.grid.dz_m;
    [maps,~]=kwsim.two_d.buildGeometry(cfg);
    ids=maps.material_id_xz( ...
        cfg.source.center_index_xz(1),cfg.source.contact_z_indices);
    material_fraction(i)=mean(ids==expected_material(i));
    if material_fraction(i)~=1
        error('kwsim:SourceContactWrongMaterial', ...
            '%s contact is not wholly in material %d.',names(i),expected_material(i));
    end
    source_center_x_mm(i)=1e3*cfg.source.center_m_xz(1);
    source_center_z_mm(i)=1e3*cfg.source.center_m_xz(2);
    contact_z_min_mm(i)=1e3*min(z); contact_z_max_mm(i)=1e3*max(z);
    contact_to_interface_min_distance_mm(i)=1e3*min(abs(z-interface_z));
    domain_z_max=(cfg.grid.Nz-1)*cfg.grid.dz_m;
    distance_to_boundary_mm(i)=1e3*min(min(z),domain_z_max-max(z));
    pml_extent=cfg.solver.pml_size_points*cfg.grid.dz_m;
    distance_to_pml_outer_mm(i)=distance_to_boundary_mm(i)+1e3*pml_extent;
end

% The frozen near-interface result is the authoritative reuse check.
baseline_file=fullfile(root,'outputs','benchmarks', ...
    'experimental_bilayer_400hz_source_polarization', ...
    'source_x_bilayer_soft_stiff_400hz','data','result.mat');
if ~isfile(baseline_file)
    error('kwsim:MissingSourcePolarizationBaseline', ...
        'The completed near-interface baseline was not found: %s',baseline_file);
end
loaded=load(baseline_file,'result'); frozen=loaded.result;
near=cfgs{1};
% Waveform equality is checked directly against resolved metadata below; the
% source array contains a per-node matrix and is not the metadata waveform.
kwsim.io.locateKWave();
[grid_near,near]=kwsim.two_d.buildGrid(near);
[~,near_metadata]=kwsim.two_d.buildSingleContactSource(near,grid_near);
unchanged=isequal(double(frozen.source.center_m_xz),double(near_metadata.center_m_xz)) && ...
    isequal(double(frozen.source.contact_z_m(:)),double(near_metadata.contact_z_m(:))) && ...
    isequal(double(frozen.source.waveform_m_s(:)),double(near_metadata.waveform_m_s(:))) && ...
    isequal(double(frozen.source.polarization_xz),double(near_metadata.polarization_xz));
if ~unchanged
    error('kwsim:NearInterfaceBaselineChanged', ...
        'Resolved NEAR_INTERFACE source differs from the completed baseline.');
end

bounds=cfgs{1}.derived.realized_analysis_bounds_m_xz;
analysis_fov_xmin_mm=repmat(1e3*bounds(1),3,1);
analysis_fov_xmax_mm=repmat(1e3*bounds(2),3,1);
analysis_fov_zmin_mm=repmat(1e3*bounds(3),3,1);
analysis_fov_zmax_mm=repmat(1e3*bounds(4),3,1);
requested_center_z_mm=1e3*requested_z;
table_out=table(names,requested_center_z_mm,source_center_x_mm,source_center_z_mm, ...
    contact_z_min_mm,contact_z_max_mm,contact_to_interface_min_distance_mm, ...
    distance_to_boundary_mm,distance_to_pml_outer_mm,material_fraction, ...
    analysis_fov_xmin_mm,analysis_fov_xmax_mm,analysis_fov_zmin_mm, ...
    analysis_fov_zmax_mm,'VariableNames',{'condition','requested_center_z_mm', ...
    'source_center_x_mm','source_center_z_mm','contact_z_min_mm', ...
    'contact_z_max_mm','contact_to_interface_min_distance_mm', ...
    'distance_to_nearest_physical_boundary_mm','distance_to_pml_outer_mm', ...
    'intended_material_fraction','analysis_fov_xmin_mm','analysis_fov_xmax_mm', ...
    'analysis_fov_zmin_mm','analysis_fov_zmax_mm'});
writetable(table_out,fullfile(output,'source_position_geometry.csv'));
disp(table_out);

cfg=cfgs{1}; domain=[0,(cfg.grid.Nx-1)*cfg.grid.dx_m,0,(cfg.grid.Nz-1)*cfg.grid.dz_m];
pml=cfg.solver.pml_size_points*[cfg.grid.dx_m,cfg.grid.dz_m];
pml_bounds=[domain(1)-pml(1),domain(2)+pml(1),domain(3)-pml(2),domain(4)+pml(2)];
fig=figure('Visible','off','Color','w','Position',[100 100 1150 680]); hold on; axis equal; axis ij;
rectangle('Position',pos(pml_bounds),'EdgeColor',[.5 .5 .5],'LineStyle','--','LineWidth',1.5);
rectangle('Position',pos(domain),'EdgeColor','k','LineWidth',2);
rectangle('Position',pos(bounds),'EdgeColor',[0 .35 .85],'LineWidth',2.5);
yline(19,'-.','Color',[.9 .45 0],'LineWidth',2,'DisplayName','bilayer interface');
colors=[.75 0 .75;0 .55 .2;.85 .1 .1]; markers={'o','s','d'};
handles=gobjects(3,1);
for i=1:3
    handles(i)=plot(source_center_x_mm(i)*ones(2,1), ...
        [contact_z_min_mm(i);contact_z_max_mm(i)],'-','Color',colors(i,:), ...
        'Marker',markers{i},'MarkerFaceColor',colors(i,:),'LineWidth',2.2, ...
        'DisplayName',names(i));
    text(source_center_x_mm(i)+1,source_center_z_mm(i),names(i), ...
        'Color',colors(i,:),'FontWeight','bold','Interpreter','none');
end
xlabel('simulation x (mm)'); ylabel('simulation z (mm)');
title('SOURCE-X bilayer axial-position preflight'); grid on;
legend(handles,'Location','eastoutside','Interpreter','none');
figure_file=fullfile(output,'source_position_geometry.png');
exportgraphics(fig,figure_file,'Resolution',220); close(fig);
audit=struct('schema_name','kwsim_source_zposition_geometry_audit', ...
    'schema_version','1.0','baseline_unchanged',unchanged, ...
    'table_file',fullfile(output,'source_position_geometry.csv'), ...
    'figure_file',figure_file,'baseline_result_file',baseline_file, ...
    'domain_bounds_m_xz',domain,'pml_bounds_m_xz',pml_bounds, ...
    'analysis_bounds_m_xz',bounds,'conditions',table2struct(table_out));
fid=fopen(fullfile(output,'source_position_geometry.json'),'w');
cleanup=onCleanup(@()fclose(fid)); fprintf(fid,'%s\n',jsonencode(audit,PrettyPrint=true));
end

function p=pos(bounds)
p=1e3*[bounds(1),bounds(3),bounds(2)-bounds(1),bounds(4)-bounds(3)];
end
