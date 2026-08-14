function audit=auditGeometry(options)
%AUDITGEOMETRY Plot full domain, exterior PML, source, FOV, and interface.
% This function validates configuration geometry only; it never runs k-Wave.

arguments
    options.ConfigFile {mustBeTextScalar} = ""
    options.OutputDirectory {mustBeTextScalar} = ""
end
root=string(fileparts(fileparts(fileparts(fileparts( ...
    mfilename('fullpath'))))));
config_file=string(options.ConfigFile);
if strlength(config_file)==0
    config_file=fullfile(root,'configs','kwsim','two_d','benchmarks', ...
        'experimental_bilayer_400hz_source_polarization', ...
        'source_z_bilayer_soft_stiff_400hz.json');
end
output=string(options.OutputDirectory);
if strlength(output)==0
    output=fullfile(root,'outputs','benchmarks', ...
        'experimental_bilayer_400hz_source_polarization','preflight');
end
if ~isfolder(output),mkdir(output);end

requested=kwsim.io.loadConfigJson(config_file);
[cfg,preflight]=kwsim.two_d.validateConfig(requested);
if ~preflight.valid
    error('kwsim:BenchmarkGeometryInvalid','Geometry preflight failed.');
end
bounds=cfg.derived.realized_analysis_bounds_m_xz;
pml=cfg.solver.pml_size_points*[cfg.grid.dx_m,cfg.grid.dz_m];
domain=[0,cfg.derived.x_full_m(end),0,cfg.derived.z_full_m(end)];
pml_bounds=[domain(1)-pml(1),domain(2)+pml(1), ...
    domain(3)-pml(2),domain(4)+pml(2)];

fig=figure('Visible','off','Color','w','Position',[100,100,1100,650]);
hold on; axis equal; axis ij;
rectangle('Position',to_position(pml_bounds),'EdgeColor',[.45,.45,.45], ...
    'LineStyle','--','LineWidth',1.5);
rectangle('Position',to_position(domain),'EdgeColor','k','LineWidth',2);
rectangle('Position',to_position(bounds),'EdgeColor',[0,.35,.85], ...
    'LineWidth',2.5);
source_x=cfg.source.center_m_xz(1);
source_z=(cfg.source.contact_z_indices-1)*cfg.grid.dz_m;
h_source=plot(1e3*source_x*ones(size(source_z)),1e3*source_z,'ro-', ...
    'LineWidth',2,'MarkerFaceColor','r');
h_motion_z=quiver(1e3*source_x,1e3*mean(source_z),0,4,0, ...
    'r','LineWidth',2,'MaxHeadSize',1);
h_motion_x=quiver(1e3*source_x,1e3*mean(source_z)-0.5,4,0,0, ...
    'Color',[.7,0,.7],'LineWidth',2,'MaxHeadSize',1);
h_interface=yline(19,'Color',[.9,.45,0],'LineWidth',2,'LineStyle','-.');
xline(1e3*bounds(1),':','Color',[0,.35,.85]);
xlabel('simulation x (mm)');ylabel('simulation z (mm)');
title('Source-polarization benchmark geometry (preflight only)');
legend([h_source,h_motion_z,h_motion_x,h_interface], ...
    {'source contact','SOURCE-Z motion','SOURCE-X motion', ...
    'bilayer interface'}, ...
    'Location','eastoutside');
text(1e3*mean(bounds(1:2)),1e3*(bounds(3)+0.002), ...
    sprintf('common analysis FOV\n%.3f x %.3f mm', ...
    1e3*diff(bounds(1:2)),1e3*diff(bounds(3:4))), ...
    'HorizontalAlignment','center','Color',[0,.25,.7]);
grid on;
figure_file=fullfile(output,'source_domain_geometry.png');
exportgraphics(fig,figure_file,'Resolution',220);close(fig);

audit=struct('config_file',config_file,'figure_file',figure_file, ...
    'requested_gap_m',cfg.sensor.source_buffer_m, ...
    'realized_gap_m',cfg.derived.source_contact_to_analysis_gap_m, ...
    'source_center_m_xz',cfg.source.center_m_xz, ...
    'source_z_span_m',[min(source_z),max(source_z)], ...
    'analysis_bounds_m_xz',bounds,'domain_bounds_m_xz',domain, ...
    'pml_bounds_m_xz',pml_bounds,'solver_executed',false);
metadata_file=fullfile(output,'source_domain_geometry.json');
fid=fopen(metadata_file,'w');
if fid<0,error('kwsim:GeometryAuditWriteFailed','Cannot write %s.',metadata_file);end
cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'%s\n',jsonencode(audit,PrettyPrint=true));clear cleanup
audit.metadata_file=metadata_file;
end

function position=to_position(bounds)
position=1e3*[bounds(1),bounds(3),bounds(2)-bounds(1),bounds(4)-bounds(3)];
end
