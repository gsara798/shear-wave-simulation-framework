# Examples

The examples are organized by simulation dimensionality and geometry.

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

Each single-run example contains a `config.json`. Run examples from the repository root with the public runner rather than changing into example directories.

## Setup once per MATLAB session

```matlab
setup_simulation_framework
```

For k-Wave:

```matlab
setup_simulation_framework( ...
    KWavePath="/absolute/path/to/k-wave-toolbox-version-1.4.1")
```

## Run one example

Synthetic volumetric inclusion:

```matlab
outcome = run_simulation( ...
    "examples/swsynth/volumetric3d/inclusion/config.json");
```

k-Wave 2D inclusion:

```matlab
outcome = run_simulation( ...
    "examples/kwave/2d/inclusion/config.json");
```

Validate without executing:

```matlab
outcome = run_simulation( ...
    "examples/kwave/3d/bilayer/config.json", ...
    DryRun=true);
```

## Run a campaign

Validate the public field-regime campaign:

```matlab
report = run_campaign( ...
    "examples/swsynth/projected3d/campaign_field_regimes/campaign.json", ...
    DryRun=true);
```

Execute or resume it:

```matlab
report = run_campaign( ...
    "examples/swsynth/projected3d/campaign_field_regimes/campaign.json");
```

The example convention is:

```text
directional  -> 1 direction
intermediate -> 16 directions
diffuse      -> 128 directions
```

These are example settings for increasing angular complexity, not universal physical thresholds.

## Dimensionality

- `swsynth/2d`: two-dimensional directions and output `U(z,x)`.
- `swsynth/projected3d`: 3D directions/polarization observed on a 2D `U(z,x)` plane.
- `swsynth/volumetric3d`: true volumetric `U(z,y,x)`.
- `kwave/2d`: 2D elastic k-Wave solver.
- `kwave/3d`: 3D elastic k-Wave solver with volumetric `wavefield_sample` output.

## Standard single-run output

By default, output is created next to the JSON:

```text
<example>/outputs/<scenario>_<timestamp>/
├── config/
├── data/
│   ├── wavefield_sample.mat
│   └── run_summary.json
├── figures/
├── validation/
└── report/              # when requested
```

k-Wave can retain additional native solver artifacts inside the same run.

## Standard figures

Planar samples:

```text
sws.png
wavefield_real.png
wavefield_phase.png
wavefield_amplitude.png
```

Volumetric samples additionally include:

```text
sws_crossplanes.png
wavefield_real_crossplanes.png
wavefield_phase_crossplanes.png
wavefield_amplitude_crossplanes.png
```

Synthetic runs may include `directions.png`. k-Wave 3D runs may include `source_geometry.png`.

## Terminal runners

Single run:

```bash
bash scripts/sim-run examples/kwave/2d/inclusion/config.json
```

Campaign:

```bash
bash scripts/campaign-run examples/swsynth/projected3d/campaign_field_regimes/campaign.json
```

The `run_example.m` files are thin interactive wrappers only. The root-level `run_simulation` and `run_campaign` functions are the recommended public API.
