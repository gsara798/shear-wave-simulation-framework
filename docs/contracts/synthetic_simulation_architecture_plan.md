# Architecture Plan: Synthetic Simulation and Adaptive REQ Integration

## Status

Proposed architecture for reorganizing the synthetic simulation code currently located in:

```text
req-ml/src/+reqml/+simulate/
```

and integrating it with:

```text
shear-wave-simulation-framework
```

This document defines the intended boundaries between full-wave k-Wave simulation, fast synthetic wavefield generation, REQ feature extraction, Adaptive REQ model training and evaluation, and dataset provenance.

No files should be moved until this architecture is reviewed and accepted.

# 1. Architectural objective

The target workflow is:

```text
wavefield generation
        ↓
standard simulation sample
        ↓
REQ feature extraction
        ↓
model training and inference
        ↓
evaluation and reporting
```

The simulation repository should generate wavefields and truth. The Adaptive REQ repository should consume those wavefields and perform REQ analysis, feature extraction, model training, inference, reliability assessment, evaluation, and reporting.

# 2. Repository responsibilities

## 2.1 `shear-wave-simulation-framework`

Primary responsibility:

```text
generate reproducible synthetic and full-wave shear-wave fields
```

It should contain two distinct backends.

### Full-wave backend

```text
src/+kwsim/
```

Responsibilities:

- k-Wave integration;
- 2D and 3D elastodynamic simulation;
- source construction;
- material construction;
- heterogeneous geometry;
- harmonic extraction;
- P/S diagnostics;
- physical validation;
- campaign execution;
- REQ-ready sample export.

### Fast synthetic backend

```text
src/+swsynth/
```

Responsibilities:

- fast synthetic wavefield generation;
- plane-wave superposition;
- spherical-wave superposition;
- controlled angular support;
- deterministic random phases;
- amplitude and polarization control;
- phenomenological geometric decay;
- simple noise models;
- rapid training-data generation;
- standard simulation-result export.

The synthetic backend is not a replacement for k-Wave. It is a lower-fidelity, computationally inexpensive generator for controlled experiments.

## 2.2 `req-ml`

Primary responsibility:

```text
convert wavefields into REQ features, predictions, and scientific conclusions
```

Responsibilities:

- local and radial spectra;
- cumulative radial energy;
- REQ quantile estimation;
- theoretical quantile features;
- learned quantile models;
- model training;
- frozen-model inference;
- SWS reconstruction;
- uncertainty and reliability analysis;
- dataset splits;
- evaluation metrics;
- experiment runners;
- figures and result tables.

The repository should consume a standard data contract independent of the wavefield source.

# 3. Public namespaces

```matlab
kwsim
swsynth
adaptive_req
```

Examples:

```matlab
kwsim.campaigns.runCampaign(...)
cfg = swsynth.defaultConfig();
result = swsynth.run(cfg);
features = reqml.features.extract_radial_features(...);
```

# 4. Proposed synthetic backend structure

Initial implementation:

```text
shear-wave-simulation-framework/
└── src/
    └── +swsynth/
        ├── defaultConfig.m
        ├── validateConfig.m
        ├── run.m
        ├── synthesizeWavefield2D.m
        ├── generateDirections.m
        ├── buildMediumMaps.m
        ├── summarizePlaneIntersection.m
        └── makeReqSample.m
```

The first migration should remain compact. Do not create many subpackages until responsibilities are stable.

# 5. Naming decisions

## Main synthesis function

Historical:

```text
simulate_rswe_plane
```

New:

```text
swsynth.synthesizeWavefield2D
```

Reasons:

- `rswe` is historical and unclear;
- `plane` can be misread as plane-wave-only;
- the function supports spherical and plane-wave models;
- the public output is a 2D observed field `U(z,x)`.

## Public runner

Historical:

```text
reqml.simulate.run_single_simulation
```

New:

```text
swsynth.run
```

## Configuration terminology

| Current | Proposed |
|---|---|
| `WaveModel` | `propagation.model` |
| `SourceSampling` | `directions.support.type` |
| `AngularSamplingMethod` | `directions.sampling_method` |
| `ForceInPlaneWave` | `directions.require_in_plane` |
| `Nwaves` | `directions.count` |
| `rmin`, `rmax` | `sources.radius_range_m` |
| `AmpJitter` | `sources.amplitude_jitter_fraction` |
| `DecayAlpha` | `amplitude.geometric_decay_exponent` |
| `SNR` | `noise.snr_db` |
| `Is2D` | `directions.space` |

`DecayAlpha` must not be interpreted as material attenuation. The current behavior is geometric amplitude decay proportional to `1/R^exponent`.

# 6. Proposed configuration structure

```matlab
cfg.schema_version = "1.0";
cfg.scenario = "synthetic_wavefield_2d";
cfg.seed = 1001;

cfg.domain.Lx_m = 0.05;
cfg.domain.Lz_m = 0.05;
cfg.domain.dx_m = 1e-4;
cfg.domain.dz_m = 1e-4;
cfg.domain.observation_y_m = 0;

cfg.medium.background_cs_m_s = 2.0;
cfg.medium.geometry.type = "homogeneous";

cfg.wavefield.frequency_hz = 500;
cfg.wavefield.observed_component = "axial";

cfg.propagation.model = "spherical_wave";

cfg.directions.count = 32;
cfg.directions.space = "three_dimensional";
cfg.directions.support.type = "cone";
cfg.directions.support.axis_xyz = [-1, 0, 0];
cfg.directions.support.half_angle_deg = 70;
cfg.directions.sampling_method = "fibonacci";
cfg.directions.require_in_plane = true;

cfg.sources.radius_range_m = [0.045, 0.05];
cfg.sources.phase_policy = "random_uniform";
cfg.sources.amplitude_jitter_fraction = 0.10;

cfg.amplitude.geometric_decay_exponent = 0;
cfg.noise.snr_db = Inf;
cfg.execution.use_parallel = true;
```

# 7. Migration table

| Current file | Proposed destination | Proposed public name |
|---|---|---|
| `simulate_rswe_plane.m` | simulation framework | `swsynth.synthesizeWavefield2D` |
| `run_single_simulation.m` | simulation framework | `swsynth.run` |
| `build_aperture_schedule.m` | simulation framework | `swsynth.buildAngularSupportSchedule` |
| `apply_sampling_step.m` | simulation framework or experiment helper | `swsynth.applyAngularSupportStep` |
| `estimate_fibonacci_cone_plane_coverage.m` | simulation framework | `swsynth.evaluateFibonacciPlaneCoverage` |
| `summarize_wave_direction_plane_coverage.m` | simulation framework | `swsynth.summarizePlaneIntersection` |
| `build_patch_windows.m` | Adaptive REQ | `reqml.patches.buildWindows` |

# 8. Code that remains in Adaptive REQ

These responsibilities remain:

```text
+estimators
+features
+inference
+metrics
+quantile
+spectrum
+theory
```

`build_patch_windows.m` should remain in Adaptive REQ because it constructs local REQ analysis patches. Proposed destination:

```text
src/+reqml/+patches/buildWindows.m
```

# 9. Legacy k-Wave code in Adaptive REQ

The package:

```text
src/+reqml/+kwave/
```

should eventually disappear from the active Adaptive REQ API.

Migration strategy:

1. preserve it temporarily;
2. replace active experiment dependencies with `kwsim` outputs;
3. compare any unique behavior against the current framework;
4. archive only after equivalence is verified;
5. remove it after no active references remain.

# 10. Standard simulation-result contract

Both `kwsim` and `swsynth` should produce a common REQ-facing sample.

Minimum fields:

```matlab
sample.schema_version
sample.generator
sample.generator_commit
sample.scenario
sample.seed

sample.field.U_zx
sample.field.component
sample.field.frequency_hz
sample.field.is_complex

sample.coordinates.x_m
sample.coordinates.z_m
sample.coordinates.dx_m
sample.coordinates.dz_m

sample.truth.cs_map_zx
sample.truth.material_id_zx
sample.truth.valid_mask_zx

sample.wavefield.direction_space
sample.wavefield.propagation_model
sample.wavefield.direction_count
sample.wavefield.angular_support
sample.wavefield.directional_bias
sample.wavefield.effective_angular_dimension

sample.validation.valid
sample.validation.req_ready

sample.provenance.resolved_config
sample.provenance.source_file
sample.provenance.run_id
```

# 11. Dataset manifest contract

Adaptive REQ experiments should not rely on manually remembered paths.

Suggested manifest fields:

```text
sample_id
dataset_id
generator
generator_repository
generator_commit
campaign_name
campaign_run_id
scenario
geometry_family
field_family
frequency_hz
background_cs_m_s
inclusion_cs_m_s
seed
realism
req_sample_path
resolved_config_path
validation_report_path
valid
req_ready
split_group
```

Suggested structure:

```text
req-ml/
├── datasets/
│   ├── README.md
│   ├── registry.json
│   └── manifests/
└── outputs/
    ├── datasets/
    ├── models/
    ├── experiments/
    ├── figures/
    └── temporary/
```

Large files remain outside Git. Manifests and registry metadata remain versioned.

# 12. Compatibility strategy

Existing experiments call:

```matlab
reqml.simulate.run_single_simulation
```

Temporary wrappers should preserve compatibility:

```matlab
function sim = run_single_simulation(cfg, varargin)

warning( ...
    "adaptive_req:DeprecatedSyntheticSimulator", ...
    "Use swsynth.run instead.");

sim = swsynth.run(cfg, varargin{:});

end
```

Wrappers should emit deprecation warnings, preserve outputs, translate old configuration names, and remain until experiments are migrated.

# 13. Migration phases

## Phase 1 — Architecture and inventory

- approve this document;
- inspect the remainder of `simulate_rswe_plane.m`;
- inspect all tests;
- inspect configuration defaults;
- inspect active experiment dependencies;
- identify hard-coded paths;
- identify current output contracts.

## Phase 2 — Add `swsynth` skeleton

Create:

```text
src/+swsynth/
tests/unit/
docs/contracts/
docs/user_guide/
examples/synthetic/
configs/synthetic/
```

Add:

```text
defaultConfig
validateConfig
run
```

No scientific behavior changes.

## Phase 3 — Migrate synthesis

Move behavior from:

```text
simulate_rswe_plane
run_single_simulation
```

Requirements:

- identical seeds;
- identical field orientation;
- identical medium maps;
- identical direction generation;
- identical phases and amplitudes;
- identical noise behavior;
- identical diagnostics;
- regression tests.

## Phase 4 — Migrate direction helpers

Move and rename:

```text
build_aperture_schedule
apply_sampling_step
estimate_fibonacci_cone_plane_coverage
summarize_wave_direction_plane_coverage
```

## Phase 5 — Keep patch logic in Adaptive REQ

Move:

```text
build_patch_windows
```

to:

```text
reqml.patches.buildWindows
```

## Phase 6 — Add common sample export

Both `kwsim` and `swsynth` export compatible samples.

## Phase 7 — Add dataset registry

Implement in Adaptive REQ:

```text
loadDatasetManifest
validateDatasetManifest
importKwsimCampaign
indexSyntheticDataset
resolveSamplePaths
```

## Phase 8 — Retire duplicated k-Wave code

Replace active use of:

```text
reqml.kwave
```

with:

```text
kwsim
```

# 14. Testing requirements

Before deleting historical functions, verify:

- same output dimensions;
- same coordinate orientation;
- same realization for a fixed seed;
- same material maps;
- same wavenumber maps;
- same wave directions;
- same plane-coverage diagnostics;
- same clean field within tolerance;
- same noisy field within tolerance;
- same patch-level REQ inputs;
- same compact experiment result.

Suggested simulation-framework tests:

```text
test_swsynth_configuration
test_swsynth_directions
test_swsynth_medium_maps
test_swsynth_plane_wave
test_swsynth_spherical_wave
test_swsynth_reproducibility
test_swsynth_req_sample
```

Suggested Adaptive REQ integration tests:

```text
test_load_swsynth_sample
test_load_kwsim_sample
test_common_sample_contract
test_legacy_synthetic_wrapper
```

# 15. Non-goals for the first migration

Do not add during the initial refactor:

- parallel campaign execution;
- cluster support;
- new propagation physics;
- new noise models;
- viscoelastic attenuation;
- new heterogeneous geometries;
- new ML models;
- large-scale dataset generation.

The first objective is architectural clarity with identical scientific behavior.

# 16. Decision summary

```text
shear-wave-simulation-framework
├── kwsim
│   └── full-wave k-Wave simulation
└── swsynth
    └── fast synthetic wavefield generation

req-ml
└── adaptive_req
    ├── REQ
    ├── features
    ├── models
    ├── inference
    ├── evaluation
    ├── patches
    └── dataset integration
```

Immediate next step:

1. inspect remaining synthetic implementation details;
2. inspect tests and config defaults;
3. create an issue and branch in the simulation framework;
4. add the `swsynth` skeleton and regression tests;
5. do not remove existing Adaptive REQ code yet.
