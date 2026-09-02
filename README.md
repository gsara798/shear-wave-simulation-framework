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

k-Wave is an **external dependency** and is not vendored in this repository. Install it separately and set its location in MATLAB:

```matlab
setenv('KWSIM_KWAVE_PATH', '/absolute/path/to/k-wave-toolbox-version-1.4.1')
```

The framework checks that the supplied toolbox root contains the required k-Wave functions before running the solver.

## Quick start

Clone the repository and add `src` to the MATLAB path:

```matlab
addpath('/absolute/path/to/shear-wave-simulation-framework/src')
```

### k-Wave: validate a configuration

From the repository root:

```matlab
outcome = kwsim.cli.runConfig( ...
    'configs/kwsim/two_d/homogeneous_directional_cli.json', ...
    DryRun=true);
```

A dry run resolves the configuration and performs preflight validation without executing the solver or creating simulation outputs.

### k-Wave: run a simulation

```matlab
outcome = kwsim.cli.runConfig( ...
    'configs/kwsim/two_d/homogeneous_directional_cli.json');

disp(outcome.report.summary)
```

Configured runs can save the resolved configuration, simulation result, validation report, standardized wavefield sample, and diagnostic figures.

### Synthetic backend

```matlab
outcome = swsynth.cli.runConfig( ...
    'configs/swsynth/homogeneous_campaign_base.json');
```

The synthetic backend does not require k-Wave and is useful for fast controlled wavefield studies.

## Examples

User-facing examples are organized by backend:

```text
examples/
├── README.md
├── kwave/
│   ├── run_homogeneous_2d.m
│   └── run_homogeneous_3d.m
├── swsynth/
│   └── run_swsynth_homogeneous.m
├── plot_validation_checks.m
└── run_all.m
```

Run a complete 2D k-Wave example:

```matlab
addpath('examples/kwave')
outcome = run_homogeneous_2d();
```

This executes the simulation, retains the physical validation report, saves configured field figures, and displays a validation-check plot.

The 3D counterpart is:

```matlab
outcome = run_homogeneous_3d();
```

For a quick synthetic example:

```matlab
addpath('examples/swsynth')
outcome = run_swsynth_homogeneous();
```

See [`examples/README.md`](examples/README.md) for details.

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

The validation report is returned by the public run interface and can be visualized with:

```matlab
plot_validation_checks(outcome.report)
```

The helper is provided in `examples/plot_validation_checks.m`.

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
- spherical inclusions, finite cylinders, bilayers, and combined 3D geometry;
- harmonic extraction from time-domain sensor data;
- physical validation and diagnostic figures.

The baseline reduced-compressional-speed option is an explicit computational approximation. It reduces simulation cost while preserving an admissible elastic model; it is not a claim about physical tissue compressional speed.

## Synthetic backend

The `swsynth` package supports fast controlled wavefields with analytical and Eikonal propagation models. It includes homogeneous and heterogeneous media, configurable propagation directions, reproducible seeds, standardized wavefield output, and 3D volumetric generation.

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
src/
├── +kwsim/          k-Wave simulation backend
├── +swsynth/        analytical/Eikonal synthetic backend
├── +simcampaigns/   backend-neutral campaign system
└── +wavefield/      backend-neutral wavefield validation

configs/
├── kwsim/
├── swsynth/
└── campaigns/

examples/            user-facing workflows
benchmarks/          reproducible physics benchmarks
tests/               unit and integration tests
docs/                detailed documentation
archive/             retained historical development material
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
