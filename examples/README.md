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
│       └── homogeneous/
└── kwave/
    ├── 2d/
    │   └── homogeneous/
    └── 3d/
        └── homogeneous/
```

Each example folder contains the JSON configuration next to the MATLAB runner.

## How to read the synthetic examples

- `swsynth/2d`: directions and output wavefield are two-dimensional, `U(z,x)`.
- `swsynth/projected3d`: directions/polarization are three-dimensional, propagation uses projected-3D physics, but the observed output is a 2D plane `U(z,x)`.
- `swsynth/volumetric3d`: the generated field is a true 3D volume `U(z,y,x)`.
- `kwave/2d` and `kwave/3d`: full elastic k-Wave simulations with the corresponding solver dimensionality.

The decisive configuration fields are `propagation.model`, `propagation.phase_model`, and `directions.space`; `directions.space="three_dimensional"` alone does not imply a volumetric output.

## Synthetic 2D homogeneous field

```matlab
cd examples/swsynth/2d/homogeneous
outcome = run_example();
```

## Projected-3D heterogeneous examples

```matlab
cd examples/swsynth/projected3d/inclusion
outcome = run_example();
```

```matlab
cd examples/swsynth/projected3d/bilayer
outcome = run_example();
```

Both use `projected3d_eikonal` and return an observed 2D wavefield.

## Projected-3D inclusion campaign: field regimes

The campaign keeps the inclusion, frequency, full-sphere angular support, and projected-3D Eikonal propagation fixed. It changes the number of independent 3D propagation directions:

- `directional`: 1 direction
- `intermediate`: 16 directions
- `diffuse`: 128 directions

These labels are an example convention for increasing angular complexity, not universal thresholds. The older k-Wave 2D benchmark used the name `partially_diffuse` for its intermediate regime and implemented it by mixing coherent and random drive.

Validate/expand the six-run campaign (two realizations per regime):

```matlab
cd examples/swsynth/projected3d/campaign_field_regimes
report = run_campaign();
```

Execute it with:

```matlab
report = run_campaign(Execute=true);
```

## True volumetric 3D synthetic field

```matlab
cd examples/swsynth/volumetric3d/homogeneous
result = run_example();
```

This example uses the volumetric 3D Eikonal phase model and returns `wavefield_sample.wavefield.data_zyx`.

## k-Wave

Install k-Wave 1.4.1 outside this repository and set:

```matlab
setenv('KWSIM_KWAVE_PATH', '/absolute/path/to/k-wave-toolbox-version-1.4.1')
```

Then use:

```matlab
cd examples/kwave/2d/homogeneous
outcome = run_example();
```

or

```matlab
cd examples/kwave/3d/homogeneous
outcome = run_example();
```

The k-Wave examples display the framework's physical validation checks. Downstream estimator validation belongs outside this repository.
