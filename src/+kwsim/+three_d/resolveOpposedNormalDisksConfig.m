function [cfg, source_x] = resolveOpposedNormalDisksConfig(cfg)
%RESOLVEOPPOSEDNORMALDISKSCONFIG Two in-phase x-normal finite disk drives.
% Called exclusively by the standard 3D vibrator-bank resolver.
arguments
 cfg struct
end
if cfg.source.vibrator_count~=2
 error("kwsim:InvalidOpposedDisks","Exactly two vibrators required.");
end
if ~strcmpi(string(cfg.source.contact_model),"finite_disk")
 error("kwsim:InvalidOpposedDisks","Finite disk contacts required.");
end
dx=cfg.grid.dx_m;
margin=round(cfg.source.boundary_margin_m/dx);
ix=[1+margin,cfg.grid.Nx-margin];
cy=round((cfg.grid.Ny+1)/2);
cz=round((cfg.grid.Nz+1)/2);
assert(ix(2)>ix(1),"Opposed contacts overlap.");
centers=[ix(1),cy,cz;ix(2),cy,cz];
faces=["x_min","x_max"];
directions=[1 0 0;-1 0 0];
occupied=false(cfg.grid.Nx,cfg.grid.Ny,cfg.grid.Nz);
template=struct("name","","face","","node_linear_indices",[], ...
 "center_index_xyz",[NaN NaN NaN],"center_m_xyz",[NaN NaN NaN], ...
 "polarization_xyz",[1 0 0],"nominal_propagation_xyz",[NaN NaN NaN], ...
 "phase_rad",0,"velocity_amplitude_m_s",cfg.source.velocity_amplitude_m_s, ...
 "contact_node_count",0,"realized_radius_y_m",NaN, ...
 "realized_radius_z_m",NaN);
v=repmat(template,2,1);
for j=1:2
 d=kwsim.three_d.makeSparseDiskMaskOnFace(cfg,faces(j),centers(j,:));
 assert(~any(d.mask_xyz & occupied,"all"),"Disk overlap.");
 occupied=occupied|d.mask_xyz;
 v(j).name="opposed_disk_"+string(j);
 v(j).face=faces(j);
 v(j).node_linear_indices=d.node_linear_indices;
 v(j).center_index_xyz=centers(j,:);
 v(j).center_m_xyz=d.center_m_xyz;
 v(j).polarization_xyz=[1 0 0]; % same laboratory drive sign, deliberately normal
 v(j).nominal_propagation_xyz=directions(j,:);
 v(j).phase_rad=cfg.source.phase_rad; % equal phase at contacts
 v(j).velocity_amplitude_m_s=cfg.source.velocity_amplitude_m_s;
 v(j).contact_node_count=d.node_count;
 v(j).realized_radius_y_m=d.realized_radius_tangent_m(1);
 v(j).realized_radius_z_m=d.realized_radius_tangent_m(2);
end
cfg.source.vibrators=v;
cfg.source.center_index_xyz=centers(1,:);
cfg.source.center_m_xyz=v(1).center_m_xyz;
cfg.source.contact_node_count=nnz(occupied);
cfg.source.contact_radius_points_y=round(cfg.source.contact_radius_m/cfg.grid.dy_m);
cfg.source.contact_radius_points_z=round(cfg.source.contact_radius_m/cfg.grid.dz_m);
cfg.source.realized_radius_y_m=max([v.realized_radius_y_m]);
cfg.source.realized_radius_z_m=max([v.realized_radius_z_m]);
cfg.source.contact_mask_yz=squeeze(occupied(ix(1),:,:));
cfg.source.contact_node_subscripts_yz=find_nodes(cfg.source.contact_mask_yz);
cfg.source.acquisition_plane_y_index_full=cy;
cfg.source.drive_kind="normal_surface_velocity";
cfg.source.expected_wave_types="mixed_p_and_s";
source_x=ix(1);
end

function rows=find_nodes(mask)
[i,j]=find(mask);
rows=[i j];
end
