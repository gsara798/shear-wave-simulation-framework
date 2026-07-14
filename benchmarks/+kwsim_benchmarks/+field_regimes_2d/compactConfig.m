function cfg = compactConfig(regime)
%COMPACTCONFIG Fast field-regimes configuration for testing.
%
% The 48-by-48 domain supports fewer perimeter contacts than the reference
% 96-by-96 configuration and is not the final angular benchmark.

arguments
    regime (1,1) string {mustBeMember(regime, ...
        ["directional", "partially_diffuse", "diffuse"])} = ...
        "directional"
end

cfg = kwsim_benchmarks.field_regimes_2d.config(regime);

cfg.grid.Nx = 48;
cfg.grid.Nz = 48;
cfg.solver.pml_size_points = 8;
cfg.source.perimeter_margin_m = 2e-3;
cfg.sensor.source_buffer_m = 1e-3;
cfg.sensor.boundary_margin_m = 3e-3;
cfg.time.settling_cycles = 1;
cfg.output.directory = "";

switch regime
    case "directional"
        vibrator_count = 6;

    case "partially_diffuse"
        vibrator_count = 12;

    case "diffuse"
        vibrator_count = 12;
end

cfg = kwsim.sources.configureVibratorBank( ...
    cfg, regime, vibrator_count);

cfg = kwsim.sources.configurePointContact( ...
    cfg, ContactRadiusM=1e-3);

end
