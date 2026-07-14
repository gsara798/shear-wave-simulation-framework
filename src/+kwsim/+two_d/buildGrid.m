function [kgrid, cfg] = buildGrid(cfg)
%BUILDGRID Create the k-Wave grid and resolve the recorded time interval.
%
% k-Wave uses (x,y) for its 2D grid. Within kwsim, that second coordinate
% is consistently interpreted as axial depth z.

arguments
    cfg struct
end

kgrid = kWaveGrid(cfg.grid.Nx, cfg.grid.dx_m, ...
    cfg.grid.Nz, cfg.grid.dz_m);
c_max = max(cfg.medium.cp_m_s, cfg.medium.cs_m_s);
kgrid.makeTime(c_max, cfg.grid.cfl, cfg.time.end_time_s_resolved);

analysis_duration_s = cfg.time.analysis_cycles / cfg.source.f0_hz;
recorded_samples = ceil(analysis_duration_s / kgrid.dt) + 1;
recorded_samples = min(recorded_samples, numel(kgrid.t_array));
record_start_index = numel(kgrid.t_array) - recorded_samples + 1;

cfg.time.dt_s = kgrid.dt;
cfg.time.Nt = numel(kgrid.t_array);
cfg.time.record_start_index = record_start_index;
cfg.time.recorded_samples = recorded_samples;
cfg.time.t_record_s = kgrid.t_array(record_start_index:end);
cfg.derived.actual_sensor_memory_bytes = cfg.derived.sensor_points * ...
    recorded_samples * 4 * 4;

end
