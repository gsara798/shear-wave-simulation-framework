# Outputs and Validation

Both backends expose a common public output layout through `run_simulation` and `run_campaign`.

## Standard single-run layout

By default, a single run is created next to the selected configuration JSON:

```text
<config-folder>/outputs/<scenario>_<timestamp>/
├── config/
├── data/
│   ├── wavefield_sample.mat
│   └── run_summary.json
├── figures/
├── validation/
└── report/              # created when a PDF is requested
```

This directory structure is the backend-neutral public contract. k-Wave may retain additional native MAT files and metadata inside the same run.

## `config/`

The resolved configuration records the values actually used after defaults, derived timing, geometry resolution, and operational settings are applied. k-Wave can also retain requested and resolved MAT representations.

The resolved configuration is a core reproducibility artifact.

## `data/wavefield_sample.mat`

The file contains a variable named `wavefield_sample` using the common backend-neutral contract.

For planar data:

```text
spatial_dimension = 2
coordinates.array_order = "zx"
wavefield.data_zx(z,x)
```

For volumetric data:

```text
spatial_dimension = 3
coordinates.array_order = "zyx"
wavefield.data_zyx(z,y,x)
```

Truth maps, when available, use the same spatial dimensions and suffix convention as the wavefield.

See [`../contracts/wavefield_sample_v1.md`](../contracts/wavefield_sample_v1.md).

## `data/run_summary.json`

This is the compact backend-neutral run summary. It records basic identity, status, dimensionality, physical configuration, and other run-level metadata available from the backend.

k-Wave may additionally retain native files such as `result.mat` and `summary.mat` for solver-specific inspection.

## `validation/`

Simulation validation belongs to this framework. Depending on the backend and scenario, validation can include:

- configuration and resource preflight;
- points per wavelength and CFL checks;
- finite harmonic fields;
- source-frequency content;
- steady-state behavior;
- P/S or cross-polarization diagnostics;
- homogeneous shear-speed recovery;
- heterogeneous material/truth checks;
- source geometry and angular coverage.

A completed solver run is not automatically a scientifically valid run. Validation thresholds are part of each configured scenario and are not universal constants.

k-Wave retains its detailed solver-specific validation artifacts under `validation/`. Synthetic runs store their validation report there as JSON.

## `figures/`

The shared `simviz` layer generates standard figures from `wavefield_sample`.

Planar samples normally include:

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

Synthetic fields may include `directions.png`. k-Wave 3D runs may include `source_geometry.png` because those sources have physical finite-distance locations.

## `report/`

For a single run, request a PDF with:

```matlab
outcome = run_simulation( ...
    "path/to/config.json", ...
    GeneratePdf=true);
```

The `report/` directory is optional and is not created when no PDF is requested.

## Campaign outputs

Campaigns contain aggregate files plus one standard directory per run:

```text
<campaign-output>/<campaign_name>/
├── campaign_summary.json
├── campaign_runs.csv
├── <run_id>/
│   ├── config/
│   ├── data/
│   ├── figures/
│   └── validation/
└── ...
```

`campaign_summary.json` records campaign execution state. `campaign_runs.csv` provides one row per expanded simulation.

## Reproducibility

For a scientific result, preserve at least:

```text
input JSON
resolved configuration
wavefield_sample.mat
run_summary.json
validation artifacts
seed
software commit
```

Backend-native files may also be retained when they are needed for detailed solver diagnostics.

## Downstream analysis

The simulation repository stops at validated wavefield generation and export. Estimator-specific processing is intentionally outside this repository. The simulation output should therefore remain estimator-neutral.
