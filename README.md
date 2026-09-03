# Shear-Wave Simulation Framework

MATLAB framework for reproducible shear-wave simulations and synthetic wavefield generation.

The repository provides two simulation backends:

- **k-Wave** for 2D and 3D elastic time-domain simulations;
- **swsynth** for analytical and Eikonal-based synthetic wavefields.

Both backends use JSON configuration files, standardized output folders, physical validation, and a common backend-neutral `wavefield_sample` contract for downstream analysis.

## What this repository does

The framework is responsible for generating and validating shear-wave fields. It supports homogeneous and heterogeneous media, directional and multi-source excitation, deterministic simulation campaigns, harmonic extraction from k-Wave time-domain data, and standardized 2D/3D wavefield export.

Estimator-specific processing intentionally lives outside this repository.

## Requirements

- MATLAB
- k-Wave 1.4.1 only when using the `kwsim` backend

k-Wave is an external dependency and is not included in this repository.

## 1. Set up MATLAB

Clone the repository, open MATLAB from the repository root, and configure the framework once per MATLAB session:

```matlab
setup_simulation_framework
```

If you want to run k-Wave simulations, provide the external toolbox path:

```matlab
setup_simulation_framework( ...
    KWavePath="/absolute/path/to/k-wave-toolbox-version-1.4.1")
```

Alternatively, set the environment variable `KWSIM_KWAVE_PATH` before starting MATLAB.

After setup, the public entry points remain available even if you change the working directory.

## 2. Run one simulation

Every public single-run example contains a `config.json`. Run any configuration with:

```matlab
outcome = run_simulation("path/to/config.json");
```

Examples:

```matlab
outcome = run_simulation( ...
    "examples/swsynth/volumetric3d/inclusion/config.json");
```

```matlab
outcome = run_simulation( ...
    "examples/kwave/2d/inclusion/config.json");
```

The backend and dimensionality are inferred from the JSON configuration.

### Validate without executing the solver

```matlab
outcome = run_simulation( ...
    "examples/kwave/3d/bilayer/config.json", ...
    DryRun=true);
```

### Optional single-run controls

```matlab
outcome = run_simulation( ...
    "examples/swsynth/volumetric3d/bilayer/config.json", ...
    PlotFigures=true, ...
    GeneratePdf=true);
```

Useful options are:

- `DryRun=true`: validate only;
- `PlotFigures=false`: skip standard figures;
- `GeneratePdf=true`: create a run PDF report;
- `OutputRoot="..."`: override the default output location.

### Single-run output

By default, outputs are written next to the selected JSON configuration:

```text
<config-folder>/outputs/<scenario>_<timestamp>/
├── config/
│   └── resolved_config.json
├── data/
│   ├── wavefield_sample.mat
│   └── run_summary.json
├── figures/
├── validation/
└── report/              # when a PDF is requested
```

Backend-specific files may also be stored in the same run directory, but the folders above form the common public output contract.

## 3. Run a campaign

A campaign JSON references one base configuration and defines multiple runs through either a parameter sweep or explicit run overrides.

Run a campaign with the same style of public entry point:

```matlab
report = run_campaign("path/to/campaign.json");
```

For example:

```matlab
report = run_campaign( ...
    "examples/swsynth/projected3d/campaign_field_regimes/campaign.json");
```

### Validate the entire campaign first

```matlab
report = run_campaign( ...
    "examples/swsynth/projected3d/campaign_field_regimes/campaign.json", ...
    DryRun=true);
```

A campaign dry run expands every requested run and validates all of them without executing a solver or creating simulation outputs.

### Resume a campaign

Campaigns resume completed runs by default:

```matlab
report = run_campaign("path/to/campaign.json", Resume=true);
```

Useful options are:

- `DryRun=true`: validate every expanded run only;
- `Resume=true`: skip already completed runs with matching identities;
- `ContinueOnError=true`: continue after an individual failed run;
- `PlotFigures=false`: skip standard figures after completed runs.

Use a Cartesian `sweep` when parameters are independent and every combination is desired. Use explicit `runs` when parameter values jointly define named physical conditions and must remain paired.

### Campaign output

The campaign JSON controls its output root. A completed campaign contains a summary plus one standardized directory per run:

```text
<campaign-output>/<campaign-name>/
├── campaign_summary.json
├── campaign_runs.csv
├── <run-id-1>/
│   ├── config/
│   ├── data/
│   ├── figures/
│   └── validation/
├── <run-id-2>/
│   └── ...
└── ...
```

Each run preserves deterministic identifiers, allowing interrupted campaigns to resume without repeating completed simulations.

## Terminal entry points

The same workflows are available from a shell:

```bash
bash scripts/sim-run examples/kwave/2d/inclusion/config.json
```

```bash
bash scripts/campaign-run examples/swsynth/projected3d/campaign_field_regimes/campaign.json
```

Validate without running:

```bash
bash scripts/sim-run examples/kwave/2d/inclusion/config.json --dry-run
bash scripts/campaign-run examples/swsynth/projected3d/campaign_field_regimes/campaign.json --dry-run
```

## Examples

User-facing examples are organized by backend and dimensionality:

```text
examples/
├── swsynth/
│   ├── 2d/
│   ├── projected3d/
│   └── volumetric3d/
└── kwave/
    ├── 2d/
    └── 3d/
```

Single-run examples contain a `config.json`. Campaign examples contain a campaign JSON plus a colocated base configuration.

See [`examples/README.md`](examples/README.md) for the full example tree and visualization conventions.

## Wavefield contract

The common interchange object is `wavefield_sample`.

Public coordinates are:

```text
x = lateral
y = elevational / out-of-plane
z = axial / depth
```

Public 2D maps use:

```text
[Nz, Nx]
suffix: _zx
```

Public 3D volumes use:

```text
[Nz, Ny, Nx]
suffix: _zyx
```

k-Wave solver orientation is handled internally by the adapter layer. The standardized sample carries coordinates, spacing, complex harmonic wavefield data, frequency, measurement metadata, and truth maps when available.

## Physical validation

Simulation validation belongs to this framework. Depending on the scenario, checks can include grid/resource preflight, source-frequency content, finite harmonic fields, P/S energy or polarization diagnostics, steady-state convergence, homogeneous wave-speed recovery, heterogeneous truth-region composition, source geometry, directional coverage, and deterministic repeatability.

## Backends

### k-Wave

The active `kwsim` backend supports 2D and 3D elastic simulations, homogeneous and heterogeneous materials, finite-contact sources, multi-source fields, angular source banks, harmonic extraction, physical validation, and standardized 2D/3D `wavefield_sample` export.

The reduced-compressional-speed option is an explicit computational approximation used to reduce simulation cost; it is not a claim about physical tissue compressional speed.

### swsynth

The `swsynth` backend supports fast analytical and Eikonal-based synthetic fields, homogeneous and heterogeneous media, configurable propagation directions, reproducible seeds, projected-3D observations, and true volumetric 3D generation.

## Repository layout

```text
setup_simulation_framework.m   configure the MATLAB session
run_simulation.m               public single-run entry point
run_campaign.m                 public campaign entry point

src/
├── +kwsim/                    k-Wave backend
├── +swsynth/                  analytical/Eikonal backend
├── +simrunner/                backend-neutral single-run dispatch
├── +simcampaigns/             backend-neutral campaign system
├── +simviz/                   shared visualization
├── +simreport/                PDF reporting
└── +wavefield/                wavefield contract validation

configs/                       reusable configurations and campaigns
examples/                      user-facing workflows
scripts/                       terminal entry points
tests/                         active unit and integration tests
docs/                          detailed documentation
archive/                       historical development material
```

## Tests

After setup, run the active unit tests with:

```matlab
r = runtests("tests/unit");
assertSuccess(r)
```

Run the complete active suite, including integration tests, with:

```matlab
addpath("tests")
results = run_all_tests();
```

Integration tests that execute the k-Wave backend require a valid external k-Wave installation.

## Documentation

Detailed documentation is available under `docs/`. Recommended starting points are:

- [`docs/kwsim/quickstart.md`](docs/kwsim/quickstart.md)
- [`docs/kwsim/configuration_guide.md`](docs/kwsim/configuration_guide.md)
- [`docs/kwsim/outputs_and_validation.md`](docs/kwsim/outputs_and_validation.md)
- [`docs/kwsim/campaigns.md`](docs/kwsim/campaigns.md)
- [`docs/kwsim/physics/finite_contact_sources.md`](docs/kwsim/physics/finite_contact_sources.md)
- [`docs/kwsim/physics/multiface_and_angular_sources.md`](docs/kwsim/physics/multiface_and_angular_sources.md)
- [`docs/kwsim/physics/heterogeneous_materials.md`](docs/kwsim/physics/heterogeneous_materials.md)
- [`docs/kwsim/physics/harmonic_analysis_and_ps_separation.md`](docs/kwsim/physics/harmonic_analysis_and_ps_separation.md)

Historical scripts and retired interfaces remain under `archive/` for provenance and are not part of the active public API.
