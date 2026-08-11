function estimate = estimateMemory(cfg)
%ESTIMATEMEMORY Conservative memory preflight for a 3D elastic simulation.
%
% This estimate is intentionally conservative. It is used to reject obviously
% oversized configurations before invoking k-Wave, not to predict exact peak
% memory use.

arguments
    cfg struct
end

nx = double(cfg.grid.Nx);
ny = double(cfg.grid.Ny);
nz = double(cfg.grid.Nz);
voxel_count = nx * ny * nz;

data_cast = lower(string(cfg.solver.data_cast));
if contains(data_cast, "single")
    real_bytes = 4;
else
    real_bytes = 8;
end

% Approximate persistent volumetric arrays:
% velocity components, stress components, material properties, masks,
% split fields, temporary FFT work arrays, and solver bookkeeping.
persistent_real_arrays = 36;

% Spectral solvers also require complex work arrays.
complex_work_arrays = 12;
complex_bytes = 2 * real_bytes;

volume_bytes = voxel_count * ( ...
    persistent_real_arrays * real_bytes + ...
    complex_work_arrays * complex_bytes);

% Apply safety factor for MATLAB, GPU transfers, temporaries, and backend
% implementation details.
safety_factor = 1.5;
estimated_solver_bytes = ceil(volume_bytes * safety_factor);

% pstdElastic3D returns six split displacement fields for every recorded
% sensor point and time. This term dominates full-volume harmonic runs and
% must be included in the preflight rather than appearing only near the end
% of an otherwise successful solver execution.
if isfield(cfg, "derived") && isfield(cfg.derived, "sensor_points")
    sensor_point_count = double(cfg.derived.sensor_points);
else
    sensor_point_count = voxel_count;
end
if isfield(cfg, "geometry") && isfield(cfg.geometry, "maximum_cp_m_s")
    maximum_speed_m_s = max(double(cfg.geometry.maximum_cp_m_s), ...
        double(cfg.geometry.maximum_cs_m_s));
elseif lower(string(cfg.medium.cp_mode)) == "reduced"
    maximum_speed_m_s = double(cfg.medium.cs_m_s) * ...
        double(cfg.medium.reduced_cp_factor);
else
    maximum_speed_m_s = double(cfg.medium.physical_cp_m_s);
end
estimated_dt_s = double(cfg.grid.cfl) * min([ ...
    cfg.grid.dx_m,cfg.grid.dy_m,cfg.grid.dz_m]) / maximum_speed_m_s;
recorded_samples = ceil((double(cfg.time.analysis_cycles) / ...
    double(cfg.source.f0_hz)) / estimated_dt_s) + 1;
recorded_component_count = 6;
estimated_sensor_bytes = ceil(sensor_point_count * recorded_samples * ...
    recorded_component_count * real_bytes);
estimated_total_bytes = estimated_solver_bytes + estimated_sensor_bytes;

estimate = struct();
estimate.grid_size_xyz = [nx, ny, nz];
estimate.voxel_count = voxel_count;
estimate.real_bytes = real_bytes;
estimate.persistent_real_array_equivalents = persistent_real_arrays;
estimate.complex_work_array_equivalents = complex_work_arrays;
estimate.safety_factor = safety_factor;
estimate.estimated_solver_bytes = estimated_solver_bytes;
estimate.estimated_solver_gb = estimated_solver_bytes / 1e9;
estimate.sensor_point_count = sensor_point_count;
estimate.estimated_recorded_samples = recorded_samples;
estimate.recorded_component_count = recorded_component_count;
estimate.estimated_sensor_bytes = estimated_sensor_bytes;
estimate.estimated_sensor_gb = estimated_sensor_bytes / 1e9;
estimate.estimated_total_bytes = estimated_total_bytes;
estimate.estimated_total_gb = estimated_total_bytes / 1e9;
estimate.maximum_allowed_bytes = double(cfg.execution.maximum_memory_bytes);
estimate.within_limit = estimated_total_bytes <= ...
    double(cfg.execution.maximum_memory_bytes);

end
