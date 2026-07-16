function cfg = compactConfig()
%COMPACTCONFIG Small circular-inclusion case for automated validation.
%
% Material contrast, frequency, spacing, source physics, and diagnostic
% thresholds match the full circular-inclusion benchmark.

cfg = ...
    kwsim_benchmarks.circular_inclusion_2d.config();
cfg.scenario = "compact_circular_inclusion";

cfg.grid.Nx = 40;
cfg.grid.Nz = 40;

cfg.solver.pml_size_points = 8;

cfg.sensor.source_buffer_m = 1e-3;
cfg.sensor.boundary_margin_m = 1e-3;

cfg.time.settling_cycles = 1;
cfg.output.directory = "";

center_x_m = ...
    0.5 * (cfg.grid.Nx - 1) * cfg.grid.dx_m;

center_z_m = ...
    0.5 * (cfg.grid.Nz - 1) * cfg.grid.dz_m;

cfg.geometry.objects = ...
    kwsim.geometry.two_d.makeCircleObject( ...
        [center_x_m, center_z_m], ...
        3e-3, ...
        2, ...
        3.0, ...
        1020, ...
        "compact_central_inclusion");

end
