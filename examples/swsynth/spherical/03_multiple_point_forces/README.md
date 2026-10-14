# 03 — Multiple point forces: explicit placement

Run the framework-native example from MATLAB:

```matlab
fw="/Users/sara/local/shear-wave-simulation-framework";
addpath(fullfile(fw,"examples","swsynth","spherical","03_multiple_point_forces"));
outcome=run_example();
```

The input uses `sources.count=3` and `sources.placement.method="explicit"` with three XYZ locations. **No Fibonacci sampler or radial source placement is selected in the input.** The compatibility adapter converts this into the current `swsynth.run` interface, retaining the legacy generator internally for deterministic phase draws. Explicit XYZ coordinates alone determine actual source locations.

For sampled radial source placement, select exactly one of `sources.placement.method="fibonacci"` or `"random"`, set `radius_m` and optionally `support`. Do not supply XYZ locations simultaneously. Old configurations using `directions.sampling_method` + `sources.radius_range_m` remain supported unchanged.

The output uses the standard `outputs/<scenario>_<timestamp>/{config,data,figures,validation}` contract and simviz plots. It is an analytic 3D spherical shear far-field model evaluated on an x-z observation plane (projected-3D), not a full Green tensor or a volumetric simulation. The current excitation is still one **shared** force orientation with random independent phases; per-source orientations/amplitudes are a separate next module.
