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

Each single-run example contains a `config.json`. The recommended workflow is to run the JSON from the repository root rather than changing into the example directory.

## Setup once per MATLAB session

From the repository root:

```matlab
setup
```

For k-Wave, either set `KWSIM_KWAVE_PATH` in the shell or configure it explicitly:

```matlab
setup(KWavePath="/absolute/path/to/k-wave-toolbox-version-1.4.1")
```

`setup` adds only the framework source directory. It does not recursively add example folders, which avoids collisions between the many files named `run_example.m`.

## Unified single-run interface

Run any public JSON with the same function:

```matlab
outcome = run_simulation("examples/swsynth/volumetric3d/inclusion/config.json");
```

```matlab
outcome = run_simulation("examples/kwave/2d/inclusion/config.json");
```

Validate without executing:

```matlab
outcome = run_simulation( ...
    "examples/kwave/3d/bilayer/config.json", ...
    DryRun=true);
```

Generate the PDF report as part of the run:

```matlab
outcome = run_simulation( ...
    "examples/swsynth/volumetric3d/bilayer/config.json", ...
    GeneratePdf=true);
```

From a terminal the equivalent entry point is:

```bash
bash scripts/sim-run examples/kwave/2d/inclusion/config.json
```

The older `scripts/kwsim-run` and `scripts/swsynth-run` remain as compatibility wrappers around `scripts/sim-run`.

## Standard single-run output contract

By default a run is saved next to its JSON:

```text
<example>/outputs/<scenario>_<timestamp>/
├── config/
├── data/
│   ├── wavefield_sample.mat
│   └── run_summary.json
├── figures/
├── validation/
└── report/              # when a PDF is requested
```

Both backends use this layout. k-Wave may additionally save its native result MAT files and solver-specific metadata inside the same run.

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

## Geometry examples

The volumetric synthetic inclusion uses a spherical 3 m/s region in a 2 m/s background. The volumetric synthetic bilayer uses a planar slab interface. Heterogeneous volumetric examples use `phase_model="volumetric_eikonal"`.

The k-Wave 2D bilayer is represented explicitly by a rectangular second layer. The k-Wave 3D bilayer uses the native planar bilayer geometry. k-Wave 3D inclusions use the native spherical material primitive.

## Field-regime campaigns

Campaigns remain separate from the single-run interface because they expand one base configuration into multiple related runs. For example:

```matlab
cd examples/swsynth/projected3d/campaign_field_regimes
report = run_campaign(Execute=true,PlotRuns=true);
```

The example convention is:

- `directional`: 1 direction
- `intermediate`: 16 directions
- `diffuse`: 128 directions

These are example settings for increasing angular complexity, not universal physical thresholds.
