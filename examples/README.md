# Examples

The examples are organized by simulation physics so that the dimensionality of the generated wavefield is explicit from the folder structure.

```text
examples/
├── swsynth/
│   ├── 2d/
│   │   └── homogeneous/
│   ├── projected3d/
│   │   ├── inclusion/
│   │   ├── bilayer/
│   │   └── campaign_field_regimes/
│   └── volumetric3d/
│       ├── homogeneous/
│       ├── inclusion/
│       └── bilayer/
└── kwave/
    ├── 2d/
    │   ├── homogeneous/
    │   ├── inclusion/
    │   └── bilayer/
    └── 3d/
        ├── homogeneous/
        ├── inclusion/
        └── bilayer/
```

Each example folder contains the JSON configuration next to the MATLAB runner.

## Dimensionality

- `swsynth/2d`: directions and output wavefield are two-dimensional, `U(z,x)`.
- `swsynth/projected3d`: directions/polarization are three-dimensional, but the observed output is a 2D plane `U(z,x)`.
- `swsynth/volumetric3d`: the generated field is a true 3D volume `U(z,y,x)`.
- `kwave/2d` and `kwave/3d`: full elastic k-Wave simulations with the corresponding solver dimensionality.

## Standard figures

The shared `simviz` layer is backend-independent once a `wavefield_sample` exists.

Planar samples generate:

- `sws.png`
- `wavefield_real.png`
- `wavefield_phase.png`
- `wavefield_amplitude.png`

Volumetric samples additionally generate orthogonal XY/XZ/YZ views and four cross-plane figures:

- `sws_crossplanes.png`
- `wavefield_amplitude_crossplanes.png`
- `wavefield_phase_crossplanes.png`
- `wavefield_real_crossplanes.png`

Synthetic samples may also generate `directions.png`. k-Wave 3D runs additionally generate physical source geometry when available.

## Volumetric synthetic examples

```matlab
cd examples/swsynth/volumetric3d/homogeneous
result = run_example();
```

```matlab
cd examples/swsynth/volumetric3d/inclusion
result = run_example();
```

```matlab
cd examples/swsynth/volumetric3d/bilayer
result = run_example();
```

The inclusion uses a spherical 3 m/s region in a 2 m/s background. The bilayer uses a planar slab interface. Heterogeneous volumetric examples use `phase_model="volumetric_eikonal"`.

## Projected-3D field-regime campaign

The campaign keeps the inclusion and propagation physics fixed while increasing the number of independent 3D propagation directions:

- `directional`: 1 direction
- `intermediate`: 16 directions
- `diffuse`: 128 directions

Validate only:

```matlab
cd examples/swsynth/projected3d/campaign_field_regimes
report = run_campaign();
```

Execute:

```matlab
report = run_campaign(Execute=true,PlotRuns=true);
```

These labels are an example convention for increasing angular complexity, not universal thresholds.

## k-Wave examples

Install k-Wave 1.4.1 outside this repository and set:

```matlab
setenv('KWSIM_KWAVE_PATH','/absolute/path/to/k-wave-toolbox-version-1.4.1')
```

For either dimension, choose `homogeneous`, `inclusion`, or `bilayer`:

```matlab
cd examples/kwave/2d/inclusion
outcome = run_example();
```

```matlab
cd examples/kwave/3d/bilayer
outcome = run_example();
```

All public k-Wave examples save a standardized `wavefield_sample` and then use the same `simviz` plotting functions as the synthetic examples. The 2D bilayer is represented explicitly by a rectangular second layer; the 3D bilayer uses the native planar bilayer geometry.

Use `DryRun=true` to validate a k-Wave configuration without executing the solver.
