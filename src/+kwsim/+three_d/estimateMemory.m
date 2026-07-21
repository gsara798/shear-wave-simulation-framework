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

estimate = struct();
estimate.grid_size_xyz = [nx, ny, nz];
estimate.voxel_count = voxel_count;
estimate.real_bytes = real_bytes;
estimate.persistent_real_array_equivalents = persistent_real_arrays;
estimate.complex_work_array_equivalents = complex_work_arrays;
estimate.safety_factor = safety_factor;
estimate.estimated_solver_bytes = estimated_solver_bytes;
estimate.estimated_solver_gb = estimated_solver_bytes / 1e9;
estimate.maximum_allowed_bytes = double(cfg.execution.maximum_memory_bytes);
estimate.within_limit = estimated_solver_bytes <= ...
    double(cfg.execution.maximum_memory_bytes);

end
