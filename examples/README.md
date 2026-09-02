# Examples

Each example is self-contained: the MATLAB entry point and the JSON configuration it executes live in the same folder. This is intentional so that a new user can open one example directory and see exactly what is being simulated.

## Setup

The example functions add `src/` automatically when called from a repository checkout.

For k-Wave examples, install k-Wave 1.4.1 outside this repository and set:

```matlab
setenv('KWSIM_KWAVE_PATH', '/absolute/path/to/k-wave-toolbox-version-1.4.1')
```

## Synthetic wavefield examples

### Homogeneous

Folder:

```text
examples/swsynth/homogeneous/
  config.json
  run_example.m
```

Run from that folder or add it to the MATLAB path:

```matlab
outcome = run_example();
```

### Circular inclusion

```text
examples/swsynth/inclusion/
  config.json
  run_example.m
```

This example uses `projected3d_eikonal` so that the heterogeneous SWS map changes the propagation physics.

### Bilayer

```text
examples/swsynth/bilayer/
  config.json
  run_example.m
```

This also uses `projected3d_eikonal` and shows refraction/phase-delay changes across a two-material interface.

The three single-run synthetic examples display a compact validation figure containing the ground-truth SWS map, `real(U)`, and `|U|` using `plot_wavefield_sample`.

## Campaign example

```text
examples/swsynth/campaign/
  base_config.json
  campaign.json
  run_campaign.m
```

Validate and inspect the expanded campaign without executing it:

```matlab
report = run_campaign();
```

Execute all runs:

```matlab
report = run_campaign(Execute=true);
```

The example campaign sweeps SWS, frequency, direction count, and seed. Its output directory is local to the example folder.

## k-Wave examples

The k-Wave examples follow the same self-contained pattern:

```text
examples/kwave/homogeneous_2d/
  config.json
  run_example.m

examples/kwave/homogeneous_3d/
  config.json
  run_example.m
```

They retain the framework's physical validation report and can display `plot_validation_checks(report)` after a full solver run.

## Notes

- `config.json` or `base_config.json` is the configuration actually executed by that example.
- Downstream estimator validation does not belong in this repository.
- The examples are intentionally small enough to be understandable and modifiable rather than reproducing full research campaigns.
