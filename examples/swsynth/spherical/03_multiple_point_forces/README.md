# 03 — Multiple point-force sources (projected-3D analytical spherical)
Run the framework-native example:
```matlab
fw="/Users/sara/local/shear-wave-simulation-framework";
addpath(fullfile(fw,"examples","swsynth","spherical","03_multiple_point_forces"));
outcome=run_example();
```
The config declares three physical XYZ source positions in **metres** using `sources.position_xyz_m`, with `directions.count=3`. Each force uses the same `force_direction_xyz`, with independent random phases under the legacy phase policy. The simulator uses the source positions **instead of** the direction/radius mapping. The `directions.sampling_method=fibonacci` field remains present for backward-compatible directional draws/metadata but **does not place the sources** when explicit positions are supplied. The standard runner writes `outputs/<scenario>_<timestamp>/{config,data,figures,validation}` and normal simviz plots.

For traditional Fibonacci placement on a shell of radius R, **omit** `sources.position_xyz_m` and configure `directions.sampling_method=fibonacci`, `directions.count=N`, and `sources.radius_range_m=[R,R]`. With an explicit `position_xyz_m` matrix, its row count must equal N.

Physics: 3D spherical far-field shear projector, observed as Uz on a 2D x-z plane. No full Green tensor/P field or volumetric output yet.
