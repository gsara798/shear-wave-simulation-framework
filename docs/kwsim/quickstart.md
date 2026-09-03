# Quick Start

This guide shows the shortest public workflow for running k-Wave simulations in the framework.

## 1. Requirements

- MATLAB
- k-Wave 1.4.1 for k-Wave simulations

k-Wave is an external dependency and is not bundled with this repository.

## 2. Configure the MATLAB session

From the repository root, run once per MATLAB session:

```matlab
setup_simulation_framework( ...
    KWavePath="/absolute/path/to/k-wave-toolbox-version-1.4.1")
```

If `KWSIM_KWAVE_PATH` is already defined in the environment, the path argument may be omitted:

```matlab
setup_simulation_framework
```

The setup function adds the repository root and `src/` to the MATLAB path. It does not recursively add example folders.

## 3. Start from a public example

The recommended user-facing k-Wave examples are:

```text
examples/kwave/2d/homogeneous/config.json
examples/kwave/2d/inclusion/config.json
examples/kwave/2d/bilayer/config.json
examples/kwave/3d/homogeneous/config.json
examples/kwave/3d/inclusion/config.json
examples/kwave/3d/bilayer/config.json
```

Use the closest example as a starting point instead of building a configuration from scratch.

## 4. Validate before executing

A dry run resolves and validates the configuration without executing the solver or creating simulation outputs:

```matlab
outcome = run_simulation( ...
    "examples/kwave/2d/inclusion/config.json", ...
    DryRun=true);
```

Dry runs are recommended after meaningful configuration changes, especially before expensive 3D simulations.

## 5. Execute a simulation

Use the same public entry point without `DryRun`:

```matlab
outcome = run_simulation( ...
    "examples/kwave/2d/inclusion/config.json");
```

The runner performs configuration loading, preflight validation, k-Wave execution, harmonic extraction, physical validation, standardized sample export, and standard figure generation.

For a 3D example:

```matlab
outcome = run_simulation( ...
    "examples/kwave/3d/inclusion/config.json");
```

## 6. Standard output layout

By default, outputs are created next to the selected JSON:

```text
<config-folder>/outputs/<scenario>_<timestamp>/
├── config/
├── data/
│   ├── wavefield_sample.mat
│   └── run_summary.json
├── figures/
├── validation/
└── report/              # only when a PDF is requested
```

k-Wave may retain additional native artifacts such as `result.mat`, `summary.mat`, resolved MAT files, and a manifest. Those backend-specific files are additional to the common public layout above.

`data/wavefield_sample.mat` is the backend-neutral interchange object used by downstream analysis. In 2D it stores `data_zx(z,x)`; in 3D it stores the complete `data_zyx(z,y,x)` volume.

## 7. Standard figures

Planar samples normally generate:

```text
sws.png
wavefield_real.png
wavefield_phase.png
wavefield_amplitude.png
```

Volumetric samples additionally generate orthogonal cross-plane figures. k-Wave 3D runs can also generate `source_geometry.png` when source geometry metadata are available.

## 8. Generate a PDF report

```matlab
outcome = run_simulation( ...
    "examples/kwave/2d/inclusion/config.json", ...
    GeneratePdf=true);
```

## 9. Terminal interface

The backend-neutral terminal runner is:

```bash
bash scripts/sim-run examples/kwave/2d/inclusion/config.json
```

Validate only:

```bash
bash scripts/sim-run examples/kwave/2d/inclusion/config.json --dry-run
```

The older `scripts/kwsim-run` wrapper is retained only for compatibility and delegates to `scripts/sim-run`.

## 10. Physical validation

Solver completion is not equivalent to physical validity. Depending on the scenario, validation can include grid resolution, source-frequency content, finite-field checks, P/S contamination, steady-state behavior, shear-speed recovery, heterogeneous truth composition, and source geometry diagnostics.

Inspect the `validation/` directory and the standard figures before using a run for scientific analysis.

## 11. Campaigns

For multiple related simulations, use the public campaign runner instead of scripting repeated calls manually:

```matlab
report = run_campaign("path/to/campaign.json", DryRun=true);
report = run_campaign("path/to/campaign.json");
```

See [Campaigns](campaigns.md) for the campaign JSON contract and resume behavior.

## Next steps

- [Configuration Guide](configuration_guide.md)
- [Outputs and Validation](outputs_and_validation.md)
- [Campaigns](campaigns.md)
- [Wavefield Sample Contract](../contracts/wavefield_sample_v1.md)
