function cfg = compactConfig(regime)
%COMPACTCONFIG Fast finite-contact configuration for testing.

arguments
    regime (1,1) string {mustBeMember(regime, ...
        ["directional", "partially_diffuse", "diffuse"])} = ...
        "directional"
end

cfg = kwsim_benchmarks.finite_contacts_2d.config(regime);

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
        vibrator_count = 4;

    case "partially_diffuse"
        vibrator_count = 8;

    case "diffuse"
        vibrator_count = 8;
end

cfg = kwsim.sources.configureVibratorBank( ...
    cfg, regime, vibrator_count);

cfg = kwsim.sources.configureFiniteContact( ...
    cfg, ...
    ContactRadiusM=2e-3, ...
    NodeSpacingPoints=4, ...
    Profile="raised_cosine");

end
