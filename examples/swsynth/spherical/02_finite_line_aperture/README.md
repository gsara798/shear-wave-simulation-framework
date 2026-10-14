# 02 — Coherent finite line aperture

Follows the exact framework-native example and output structure. Three configurations in `config/`: a point source, a coherent 4 mm line and an 8 mm line. `run_simulation` generates separate timestamped runs with standard `config/`, `data/`, `figures/`, `validation/` directories and common simviz plot naming.

From MATLAB:
```matlab
fw="/Users/sara/local/shear-wave-simulation-framework";
addpath(fullfile(fw,"examples","swsynth","spherical","02_finite_line_aperture"));
outcomes=run_example();
```

`run_example(DryRun=true)` validates all configurations without simulation.
Tests: `runtests(fullfile(fw,"tests","unit","test_swsynth_finite_aperture.m"))`.

**Physics:** coherent uniformly weighted point forces along a *line*. The force direction is x; the observed displacement is Uz on an x-z slice with 3D source-observation geometry. A line aperture is not a finite rigid disk nor an Oestreicher sphere.
