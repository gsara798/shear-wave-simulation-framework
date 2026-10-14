# 01 — Shear far-field radiation from a vector point force

Uses exactly the same `setup` → `run_simulation` contract as `examples/swsynth/projected3d/inclusion`. Configurations are in `config/force_x.json` and `config/force_z.json`. Output per run: `outputs/<scenario>_<timestamp>/{config,data,figures,validation}`; `simviz` produces standard amplitude, phase, real-part and SWS plots.

From MATLAB:
```matlab
fw="/Users/sara/local/shear-wave-simulation-framework";
addpath(fullfile(fw,"examples","swsynth","spherical","01_point_force_shear"));
outcomes=run_example();
```

For tests: `run_example(DryRun=true)`; `runtests(fullfile(fw,"tests","unit","test_swsynth_point_force_radiation.m"))`.

**Physics:** 3D point-force position/polarization and spherical phase, *2D x-z observation of axial Uz*, not volumetric 3D or the complete elastodynamic Green tensor. This model includes the transverse far-field shear projector only.
