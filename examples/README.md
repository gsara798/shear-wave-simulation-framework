# Examples

These examples are intentionally small, user-facing entry points to the public simulation APIs.

## Setup

Add the repository source directory to MATLAB. The example functions do this automatically when called from the repository checkout.

For k-Wave examples, install k-Wave 1.4.1 outside this repository and set:

```matlab
setenv('KWSIM_KWAVE_PATH', '/absolute/path/to/k-wave-toolbox-version-1.4.1')
```

## k-Wave

```matlab
outcome = run_homogeneous_2d();
outcome = run_homogeneous_3d();
```

Both examples run a configured simulation, retain the framework's physical validation report, save the configured field figures, and display a validation-check plot.

## Synthetic wavefields

```matlab
outcome = run_swsynth_homogeneous();
```

This executes the analytical synthetic-wavefield backend and returns the generated standardized wavefield sample.

## Validation plots

`plot_validation_checks(report)` visualizes the pass/fail state of the physical validation checks returned by the k-Wave framework. These checks validate the simulation itself; downstream estimator validation belongs outside this repository.

## Run all examples

```matlab
results = run_all();
```

By default `run_all` performs dry runs for the k-Wave examples so that the entry point remains quick. Set `RunKWave=true` to execute the k-Wave solvers.
