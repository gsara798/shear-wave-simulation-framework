function cfg = compactStage3Config(regime)
%COMPACTSTAGE3CONFIG Fast Stage 3 configuration for tests and development.
%
% This benchmark preserves 500 Hz excitation, 0.5 mm spacing, 2 m/s shear
% speed, eight recorded cycles, vector sources, and fixed total drive. The
% 48-by-48 domain supports fewer perimeter contacts than the reference
% 96-by-96 configuration and is not the final angular acceptance benchmark.

arguments
    regime (1,1) string {mustBeMember(regime, ...
        ["directional", "partially_diffuse", "diffuse"])} = "directional"
end

cfg = kwsim.two_d.stage3Config(regime);
cfg.grid.Nx = 48;
cfg.grid.Nz = 48;
cfg.solver.pml_size_points = 8;
cfg.source.contact_radius_m = 1e-3;
cfg.source.perimeter_margin_m = 2e-3;
cfg.sensor.source_buffer_m = 1e-3;
cfg.sensor.boundary_margin_m = 3e-3;
cfg.time.settling_cycles = 1;
cfg.output.directory = "";

switch regime
    case "directional"
        cfg.source.vibrator_count = 6;
    case "partially_diffuse"
        cfg.source.vibrator_count = 12;
    case "diffuse"
        cfg.source.vibrator_count = 12;
end

end
