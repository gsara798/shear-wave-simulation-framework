function cfg = compactValidationConfig()
%COMPACTVALIDATIONCONFIG Small but physically equivalent Stage 1 benchmark.
%
% This configuration keeps the same frequency, material, PPW, source model,
% and eight-cycle analysis window as the 96-by-96 reference. Its smaller
% physical domain makes repeated grid/PML tests practical during development.

cfg = kwsim.two_d.defaultConfig();
cfg.grid.Nx = 40;
cfg.grid.Nz = 40;
cfg.solver.pml_size_points = 8;
cfg.source.contact_radius_m = 1e-3;
cfg.sensor.source_buffer_m = 1e-3;
cfg.sensor.boundary_margin_m = 1e-3;
cfg.time.settling_cycles = 1;

end
