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

## k-Wave examples (unchanged)

Public k-Wave examples remain under `examples/kwave/2d/` and `examples/kwave/3d/`.

```matlab
setup_simulation_framework(KWavePath="/absolute/path/to/k-wave-toolbox-version-1.4.1")
outcome = run_simulation("examples/kwave/2d/inclusion/config.json");
```

## Standard data contract

Both backends export `data/wavefield_sample.mat` with `wavefield_sample`, plus configuration, validation, summary JSON and optional plots/PDF. For V2, `wavefield.data_zx` and `data_zyx` are projections of complex vector relative-motion fields; the local material truth map is `k=2*pi*f/c_s`, not an REQ estimate.

Unit/integration validation of modular swsynth is described in `docs/architecture/V2_AUDIT_POST_CAMPAIGN_INTEGRATION_20261015.md`. The numerical Eikonal solver and k-Wave backend remain separate.
