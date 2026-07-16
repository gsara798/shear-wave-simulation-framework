function cfg = compactConfig()
%COMPACTCONFIG Small directional homogeneous configuration for testing.
%
% Frequency, material properties, spatial resolution, source physics, and
% the eight-cycle analysis window match the full reference benchmark.

cfg = ...
    kwsim_benchmarks.directional_homogeneous_2d.config();

cfg.scenario = "compact_directional_homogeneous_2d";

cfg.grid.Nx = 40;
cfg.grid.Nz = 40;

cfg.solver.pml_size_points = 8;

cfg.sensor.source_buffer_m = 1e-3;
cfg.sensor.boundary_margin_m = 1e-3;

cfg.time.settling_cycles = 1;

cfg.output.directory = "";

end
