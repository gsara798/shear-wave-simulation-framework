function [kgrid, cfg, metadata] = buildGrid(cfg)
%BUILDGRID Create the k-Wave 3D grid and resolve the simulation time.
%
% k-Wave solver arrays use [Nx,Ny,Nz]. Public arrays are converted later
% by the run adapter to [Nz,Ny,Nx].

arguments
    cfg struct
end

kgrid = kWaveGrid( ...
    cfg.grid.Nx, cfg.grid.dx_m, ...
    cfg.grid.Ny, cfg.grid.dy_m, ...
    cfg.grid.Nz, cfg.grid.dz_m);

c_max_m_s = ...
    max( ...
        cfg.geometry.maximum_cp_m_s, ...
        cfg.geometry.maximum_cs_m_s);

if isempty(cfg.time.end_time_s)
    % Conservative automatic duration:
    %
    % 1. allow a shear wave to cross the domain diagonal;
    % 2. allow the requested settling cycles;
    % 3. retain the requested analysis cycles.
    domain_size_m_xyz = [
        (cfg.grid.Nx - 1) * cfg.grid.dx_m, ...
        (cfg.grid.Ny - 1) * cfg.grid.dy_m, ...
        (cfg.grid.Nz - 1) * cfg.grid.dz_m
    ];

    maximum_shear_travel_s = ...
        norm(domain_size_m_xyz) / ...
        cfg.geometry.minimum_cs_m_s;

    settling_duration_s = ...
        cfg.time.settling_cycles / cfg.source.f0_hz;

    analysis_duration_s = ...
        cfg.time.analysis_cycles / cfg.source.f0_hz;

    end_time_s_resolved = maximum_shear_travel_s + ...
        settling_duration_s + analysis_duration_s;
else
    end_time_s_resolved = double(cfg.time.end_time_s);
    analysis_duration_s = ...
        cfg.time.analysis_cycles / cfg.source.f0_hz;
end

kgrid.makeTime(c_max_m_s, cfg.grid.cfl, end_time_s_resolved);

recorded_samples = ceil(analysis_duration_s / kgrid.dt) + 1;
recorded_samples = min(recorded_samples, numel(kgrid.t_array));
record_start_index = numel(kgrid.t_array) - recorded_samples + 1;

cfg.time.end_time_s_resolved = end_time_s_resolved;
cfg.time.dt_s = double(kgrid.dt);
cfg.time.Nt = numel(kgrid.t_array);
cfg.time.record_start_index = record_start_index;
cfg.time.recorded_samples = recorded_samples;
cfg.time.t_record_s = ...
    double(kgrid.t_array(record_start_index:end));

metadata = struct();
metadata.grid_size_xyz = [
    cfg.grid.Nx, ...
    cfg.grid.Ny, ...
    cfg.grid.Nz
];
metadata.spacing_m_xyz = [
    cfg.grid.dx_m, ...
    cfg.grid.dy_m, ...
    cfg.grid.dz_m
];
metadata.domain_size_m_xyz = [
    (cfg.grid.Nx - 1) * cfg.grid.dx_m, ...
    (cfg.grid.Ny - 1) * cfg.grid.dy_m, ...
    (cfg.grid.Nz - 1) * cfg.grid.dz_m
];
metadata.dt_s = double(kgrid.dt);
metadata.Nt = numel(kgrid.t_array);
metadata.end_time_s = double(kgrid.t_array(end));
metadata.record_start_index = record_start_index;
metadata.recorded_samples = recorded_samples;
metadata.t_record_s = cfg.time.t_record_s;
metadata.c_max_m_s = c_max_m_s;
metadata.orientation = "[Nx,Ny,Nz] internal";

end
