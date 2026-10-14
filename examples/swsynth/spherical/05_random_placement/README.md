# 05 — random spherical placement

This framework-native example runs 12 spherical far-field shear point forces located on a shell of radius 31 mm, using `sources.placement.method="random"`. The new excitation contract uses `force.mode=random_isotropic`, `amplitude.mode=random_uniform` with relative factors in [0.7,1.3], and `phase.mode=random_uniform`. These draws are seeded and reproducible. `in_phase` means all scalar excitation phases are zero; differing force-vector orientations can still change the physical displacement signs.

Run in MATLAB:
```matlab
fw="/Users/sara/local/shear-wave-simulation-framework";
addpath(fullfile(fw,"examples","swsynth","spherical","05_random_placement"));
outcome=run_example();
```
Produces the standard `outputs/<scenario>_<timestamp>/{config,data,figures,validation}` artifacts. Uses a true 3D spherical source distribution evaluated only on the x-z observation plane (projected-3D). It is **not** volumetric or a full elastodynamic Green model.
