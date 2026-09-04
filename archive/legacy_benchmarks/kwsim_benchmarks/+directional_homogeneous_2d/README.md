# Directional homogeneous 2D benchmark

This benchmark evaluates a stable, directional shear-wave field in a
homogeneous 2D elastic medium with known shear-wave speed.

The reference configuration uses:

- `cs = 2 m/s`;
- `rho = 1000 kg/m^3`;
- `f0 = 500 Hz`;
- a finite prescribed-velocity contact on the left boundary;
- axial source motion, transverse to the nominal `+x` propagation;
- eight recorded steady-state cycles.

## Reference run

~~~matlab
addpath("src");
addpath("benchmarks");

[result, report] = ...
    kwsim_benchmarks.directional_homogeneous_2d.run();
~~~

## Compact reliability validation

~~~matlab
cfg = ...
    kwsim_benchmarks.directional_homogeneous_2d.compactConfig();

validation = ...
    kwsim_benchmarks.directional_homogeneous_2d.validate(cfg);
~~~

The reliability suite compares:

1. A baseline run.
2. An exact repeat.
3. A 25% finer spatial grid.
4. A physically larger downstream domain.

It evaluates deterministic repeatability, cross-grid field correlation,
shear-speed convergence, and sensitivity to the absorbing boundary.
