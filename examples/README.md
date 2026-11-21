# Examples and configuration entry points

This branch uses **modular swsynth V2 only**. The historical `examples/swsynth/` tree (V1 JSONs and old generated artifacts) has been removed from `develop/v2`. It is preserved in the separate backup worktree and Git history. **Do not use those V1 examples with V2.**

## Active swsynth V2 examples

Single-run JSONs live in `configs/swsynth/v2/`:
- `homogeneous_plane_base.json`: directional plane-wave superposition in 2D
- `two_sources_projected3d.json`: two coherent physical point sources
- `projected3d_heterogeneous_eikonal.json`: heterogeneous projected 3D plane-wave Eikonal
- `volumetric3d_heterogeneous_eikonal.json`: heterogeneous volumetric 3D plane-wave Eikonal

The campaign fixture is `configs/campaigns/swsynth/smoke/swsynth_v2_homogeneous_smoke.json`. It references the 2D base configuration and sweeps material speed and frequency across four runs.

```matlab
setup_simulation_framework
outcome = run_simulation( ...
    "configs/swsynth/v2/volumetric3d_heterogeneous_eikonal.json", ...
    DryRun=true);
outcome = run_simulation( ...
    "configs/swsynth/v2/homogeneous_plane_base.json", ...
    PlotFigures=true);
report = run_campaign( ...
    "configs/campaigns/swsynth/smoke/swsynth_v2_homogeneous_smoke.json", ...
    DryRun=true);
```

The **simulation** JSON must specify `"schema_version": "2.0"`; campaign JSONs use their independent campaign schema.

## V2 displacement readout noise example

`examples/swsynth/v2/09_displacement_readout_noise/` contains a single
off-plane point source with an x-directed force, z-axis displacement readout,
and a paired six-level Boukraa-like temporal-noise campaign. It preserves
the standard figure generator and export order; see the folder README.

## k-Wave examples (unchanged)

Public k-Wave examples remain under `examples/kwave/2d/` and `examples/kwave/3d/`.

```matlab
setup_simulation_framework(KWavePath="/absolute/path/to/k-wave-toolbox-version-1.4.1")
outcome = run_simulation("examples/kwave/2d/inclusion/config.json");
```

## Standard data contract

Both backends export `data/wavefield_sample.mat` with `wavefield_sample`, plus configuration, validation, summary JSON and optional plots/PDF. For V2, `wavefield.data_zx` and `data_zyx` are projections of complex vector relative-motion fields; the local material wavenumber truth map follows `k=2*pi*f/c_s`.

Unit/integration validation of modular swsynth is described in `docs/architecture/V2_AUDIT_POST_CAMPAIGN_INTEGRATION_20261015.md`. The numerical Eikonal solver and k-Wave backend remain separate.

## Parallel execution: choose one level

A campaign can use either of two parallelism levels, but **not both at the same time**.

**Independent simulations in parallel** (the run JSONs must have `execution.parallel` absent or false):

```matlab
report=run_campaign( ...
    "configs/campaigns/swsynth/examples/many_point_sources_campaign_parallel.json", ...
    ParallelLevel="campaign", NumWorkers=4);

report=run_campaign( ...
    "configs/campaigns/swsynth/examples/many_plane_waves_campaign_parallel.json", ...
    ParallelLevel="campaign", NumWorkers=4);
```

**Contributions within a simulation in parallel** (the base JSONs set `execution.parallel=true`):

```matlab
report=run_campaign( ...
    "configs/campaigns/swsynth/examples/many_point_sources_parallel.json", ...
    ParallelLevel="sources", NumWorkers=4);
```

For source-level parallelism, the worker count is taken from the individual simulation JSON's `execution.num_workers`, **not** from `run_campaign(...,NumWorkers=...)`; the latter controls campaign-level workers. Individual simulation source parallelism remains available with `run_simulation`.

The campaign scheduler executes runs concurrently only in `ParallelLevel="campaign"`, writes each run to its own output directory and publishes campaign summary/CSV and completion markers on the client. The previous sequential scheduling remains the default. Both modes require MATLAB Parallel Computing Toolbox when the corresponding parallelism is activated. Campaign parallelism does not support nested source parallelism and rejects base configs with `execution.parallel=true` instead of silently opening nested pools. Select a distinct campaign name/output directory for each benchmark; `Resume` reuses completed runs.
