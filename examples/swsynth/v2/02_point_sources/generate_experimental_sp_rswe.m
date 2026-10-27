function files=generate_experimental_sp_rswe(options)
%GENERATE_EXPERIMENTAL_SP_RSWE Eight V2 projected-3D point-source scenarios.
% SP: opposing +/- x-wall actuators, normal forces.
% RSWE: five tightly grouped points on EACH of four lateral walls.
% This is an analytic unbounded point-force model, NOT box reflections or FEM.
arguments
 options.OutputDir (1,1) string = fullfile(fileparts(mfilename("fullpath")),"experimental_sp_rswe_generated")
 options.Frequencies (1,:) double = [300 600]
 options.Speeds (1,:) double = [2 3.4]
 options.GroupOffsetM (1,1) double {mustBePositive} = .002
 options.Seed (1,1) double {mustBeInteger} = 53053
end
assert(~isempty(options.Frequencies)&&all(isfinite(options.Frequencies)&options.Frequencies>0));
assert(~isempty(options.Speeds)&&all(isfinite(options.Speeds)&options.Speeds>0));
assert(options.GroupOffsetM < .008,"Point clusters must remain compact.");
if ~isfolder(options.OutputDir),mkdir(options.OutputDir);end

% Observation FOV: x,z from 0 to 24 mm, y=0. Lateral cube walls
% x=-8/32 mm and y=-20/+20 mm, with 5 mm physical clearance.
% Inward normal forces are specified in physical xyz.
fov=.024;
xleft=-.008; xright=.032; yfront=-.020; yback=.020;
xc=fov/2; zc=fov/2; d=options.GroupOffsetM;
% Dice-five formation: center plus four corners of a d-by-d square.
offset=[-d -d; -d d; 0 0; d -d; d d];
% SP: single point on each opposing x-facing wall.
posSP=[xleft .004 zc; xright -.004 zc];
forceSP=[1 0 0; -1 0 0];
% RSWE: face-local axes: x walls use (y,z), y walls use (x,z).
pos=zeros(20,3);force=zeros(20,3);k=0;
for face=1:4
 for j=1:5
  k=k+1; a=offset(j,1);bb=offset(j,2);
  switch face
   case 1, pos(k,:)=[xleft a zc+bb];force(k,:)=[1 0 0];
   case 2, pos(k,:)=[xright a zc+bb];force(k,:)=[-1 0 0];
   case 3, pos(k,:)=[xc+a yfront zc+bb];force(k,:)=[0 1 0];
   case 4, pos(k,:)=[xc+a yback zc+bb];force(k,:)=[0 -1 0];
  end
 end
end
files=strings(0,1);
for field=["sp","rswe"]
 if field=="sp"
  xyz=posSP;forces=forceSP;
 else
  xyz=pos;forces=force;
 end
 for cs=options.Speeds
  for freq=options.Frequencies
   c=struct();
   c.schema_version="2.0";
   c.scenario="experimental_"+field+"_cs"+strrep(sprintf("%g",cs),".","p")+"_f"+string(freq);
   c.seed=options.Seed;
   c.geometry="projected3d";
   c.domain=struct("Lx_m",fov,"Lz_m",fov,"dx_m",.0003, ...
      "dz_m",.0003,"observation_y_m",0);
   c.medium=struct("cs_m_s",cs,"objects",[]);
   c.harmonic=struct("frequency_hz",freq,"quantity","relative_motion");
   c.propagation=struct("model","spherical_wave", ...
      "phase_method","analytical","geometric_decay_exponent",1, ...
      "normalization","sqrt_count");
   c.sources=struct("count",size(xyz,1), ...
      "positions",struct("method","explicit","position_xyz_m",xyz), ...
      "excitation",struct("force_policy","fixed","force_direction_xyz",forces, ...
      "amplitude_policy","fixed","relative_amplitude",ones(size(xyz,1),1), ...
      "phase_policy","fixed","phase_rad",zeros(size(xyz,1),1)));
   c.measurement=struct("axis_xyz",[0 0 1]);
   filename=fullfile(options.OutputDir,c.scenario+".json");
   fid=fopen(filename,"w");
   assert(fid>0,"Could not create %s",filename);
   fprintf(fid,"%s\n",jsonencode(c,PrettyPrint=true));fclose(fid);
   files(end+1,1)=filename; %#ok<AGROW>
  end
 end
end
fprintf("Created %d V2 scenarios in %s\n",numel(files),options.OutputDir);
end
