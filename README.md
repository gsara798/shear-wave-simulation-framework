# Shear-Wave Simulation Framework

MATLAB framework for reproducible shear-wave simulations and synthetic wavefield generation.

The repository provides two simulation backends:

- **k-Wave** for 2D and 3D elastic time-domain simulations;
- **swsynth** for analytical and Eikonal-based synthetic wavefields.

Both backends are designed around explicit configuration, reproducible outputs, physical validation, and a common backend-neutral `wavefield_sample` contract for downstream analysis.

## Scope

The framework is responsible for:

- generating shear-wave fields;
- defining homogeneous and heterogeneous media;
- configuring directional, multi-source, and angular source geometries;
- reducing k-Wave time-domain simulations to complex harmonic fields;
- validating simulation physics and numerical consistency;
- running deterministic parameter campaigns;
- exporting standardized wavefield samples.

Estimator-specific processing and estimator validation intentionally live outside this repository.

## Requirements

- MATLAB
- k-Wave 1.4.1 for the `kwsim` backend

k-Wave is an **external dependency** and is not vendored in this repository.

## Quick start

From the repository root, configure the MATLAB session once:

```matlab
setup
```

This keeps the repository entry points and `src/` on the MATLAB path even if the working directory changes later.

For k-Wave, either set `KWSIM_KWAVE_PATH` in the environment or configure it through setup:

```matlab
setup(KWavePath="/absolute/path/to/k-wave-toolbox-version-1.4.1")
```

Run any single JSON configuration with the same public entry point:

```matlab
outcome = run_simulation( ...
    "examples/swsynth/volumetric3d/inclusion/config.json");
```

```matlab
outcome = run_simulation( ...
    "examples/kwave/2d/inclusion/config.json");
```

Validate without executing a solver:

```matlab
outcome = run_simulation( ...
    "examples/kwave/3d/bilayer/config.json", ...
    DryRun=true);
```

Generate the standard figures and a PDF report as part of the run:

```matlab
outcome = run_simulation( ...
    "examples/swsynth/volumetric3d/bilayer/config.json", ...
    PlotFigures=true, ...
    GeneratePdf=true);
```

The equivalent terminal entry point is:

```bash
bash scripts/sim-run examples/kwave/2d/inclusion/config.json
```

## Standard single-run output

The unified runner writes outputs next to the selected JSON by default:

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

Backend-specific artifacts may also be retained inside the same run, but the folders above form the common public contract.

## Examples

Examples are organized explicitly by simulation dimensionality and geometry:

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

Single-run examples contain a `config.json` and can all be executed through `run_simulation`. Thin `run_example.m` wrappers remain for interactive use but are not required.

See [`examples/README.md`](examples/README.md) for the full example tree and plotting/output conventions.

## Physical validation

Simulation validation belongs to the framework. Depending on the scenario, checks can include:

- grid and resource preflight;
- source-frequency content;
- finite harmonic-field checks;
- P/S energy or polarization diagnostics;
- steady-state convergence;
- homogeneous wave-speed recovery;
- heterogeneous truth-region composition;
- source-bank geometry and directional coverage;
- deterministic repeatability.

The validation report is returned by the public run interface. k-Wave also retains its detailed solver-specific validation artifacts inside the standardized run directory.

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

k-Wave solver orientation is handled internally by the adapter layer.

The standardized sample carries coordinates, spatial spacing, complex harmonic wavefield data, frequency, measurement metadata, and truth maps when available.

## k-Wave backend

The active `kwsim` package supports:

- 2D and 3D elastic simulations;
- homogeneous and heterogeneous materials;
- finite-contact sources;
- single-contact and multi-source fields;
- generated angular source banks;
- circular/rectangular 2D geometry;
- spherical inclusions, finite cylinders, bilayers, and combined 3D geometry;
- harmonic extraction from time-domain sensor data;
- physical validation and diagnostic figures;
- standardized 2D and volumetric 3D `wavefield_sample` export.

The baseline reduced-compressional-speed option is an explicit computational approximation. It reduces simulation cost while preserving an admissible elastic model; it is not a claim about physical tissue compressional speed.

## Synthetic backend

The `swsynth` package supports fast controlled wavefields with analytical and Eikonal propagation models. It includes homogeneous and heterogeneous media, configurable propagation directions, reproducible seeds, standardized wavefield output, projected-3D observations, and true volumetric 3D generation.

## Campaigns

`simcampaigns` is the canonical campaign API for both backends.

Use a Cartesian `sweep` when independent parameters should form every combination. Use explicit `runs` when parameters jointly define named physical scenarios and must remain paired.

Example:

```matlab
[runs, expansion] = simcampaigns.expandCampaign( ...
    'configs/campaigns/kwsim/smoke/homogeneous_partial_3d_n8_p2_smoke.json');

disp(expansion.run_count)
```

Validate a campaign before execution:

```matlab
[~, validation] = simcampaigns.validateCampaign( ...
    'configs/campaigns/kwsim/smoke/homogeneous_partial_3d_n8_p2_smoke.json');

assert(validation.valid)
```

Execute or resume:

```matlab
report = simcampaigns.runCampaign( ...
    'configs/campaigns/kwsim/smoke/homogeneous_partial_3d_n8_p2_smoke.json', ...
    Resume=true, ...
    ContinueOnError=true);
```

Campaign runs receive deterministic identifiers and can be resumed without repeating completed simulations.

## Repository layout

```text
setup.m                 session setup
run_simulation.m        unified single-run entry point

src/
├── +kwsim/             k-Wave simulation backend
├── +swsynth/           analytical/Eikonal synthetic backend
├── +simrunner/         backend-neutral single-run dispatch
├── +simcampaigns/      backend-neutral campaign system
├── +simviz/            shared scientific visualization
├── +simreport/         PDF run/campaign reports
└── +wavefield/         backend-neutral wavefield validation

configs/
├── kwsim/
├── swsynth/
└── campaigns/

examples/               user-facing JSON workflows
scripts/                terminal entry points
benchmarks/             reproducible physics benchmarks
tests/                  unit and integration tests
docs/                   detailed documentation
archive/                retained historical development material
```

## Tests

Run the complete active suite from MATLAB:

```matlab
addpath('tests')
results = run_all_tests();
```

The test runner adds `src` and `benchmarks` automatically and runs all active tests recursively.

Tests that execute the k-Wave backend require a valid external k-Wave installation.

## Documentation

Detailed documentation is available under `docs/`.

Recommended starting points:

- [`docs/kwsim/quickstart.md`](docs/kwsim/quickstart.md)
- [`docs/kwsim/configuration_guide.md`](docs/kwsim/configuration_guide.md)
- [`docs/kwsim/outputs_and_validation.md`](docs/kwsim/outputs_and_validation.md)
- [`docs/kwsim/campaigns.md`](docs/kwsim/campaigns.md)
- [`docs/kwsim/physics/finite_contact_sources.md`](docs/kwsim/physics/finite_contact_sources.md)
- [`docs/kwsim/physics/multiface_and_angular_sources.md`](docs/kwsim/physics/multiface_and_angular_sources.md)
- [`docs/kwsim/physics/heterogeneous_materials.md`](docs/kwsim/physics/heterogeneous_materials.md)
- [`docs/kwsim/physics/harmonic_analysis_and_ps_separation.md`](docs/kwsim/physics/harmonic_analysis_and_ps_separation.md)

Historical scripts and retired interfaces are retained under `archive/` as development provenance and are not part of the active public API.
