# Field-regimes 2D benchmark

This benchmark compares three monofrequency shear-wave source regimes:

1. Directional.
2. Partially diffuse.
3. Diffuse.

It evaluates angular concentration, angular entropy, spatial coherence,
source-bank reproducibility, solver-channel count, and preservation of the
prescribed total drive.

## MATLAB usage

~~~matlab
projectRoot = pwd;

addpath(fullfile(projectRoot, "src"));
addpath(fullfile(projectRoot, "benchmarks"));

validation = kwsim_benchmarks.field_regimes_2d.run();
~~~

## Files

- `config.m`: full reference configuration for one regime.
- `compactConfig.m`: reduced configuration for automated testing.
- `run.m`: executes all three regimes.
- `evaluate.m`: compares previously calculated results.
- `plotResults.m`: creates the source, field, and spectrum comparison.
- `saveResults.m`: saves the validation structure and readable summary.
