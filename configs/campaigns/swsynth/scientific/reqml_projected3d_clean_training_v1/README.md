# REQ-ML projected-3D clean training campaign v1

This campaign set generates clean synthetic projected-3D wavefields for
training and evaluating REQ-ML.

## Scientific scope

The training set will contain four geometry families:

1. homogeneous;
2. bilayer;
3. circular inclusion;
4. bilayer with circular inclusion.

All training campaigns use the `swsynth` backend. k-Wave simulations are
reserved for external validation and are not included in model training.

## Homogeneous campaign

The homogeneous campaign uses a deterministic Cartesian parameter sweep over:

- shear-wave speed: 1.0, 2.0, 3.0, and 4.0 m/s;
- frequency: 200, 400, and 600 Hz;
- projected-3D direction count: 1, 4, 8, 32, and 128;
- lateral sampling `dx`: 0.25 and 0.40 mm;
- axial sampling `dz`: 0.25 and 0.40 mm;
- two independent random source realizations.

The complete campaign contains:

```text
4 shear-wave speeds
× 3 frequencies
× 5 direction counts
× 2 dx values
× 2 dz values
× 2 seeds
= 480 runs
```

The campaign JSON is located at:

```text
configs/campaigns/swsynth/scientific/
└── reqml_projected3d_clean_training_v1/
    └── homogeneous.json
```

Its base simulation configuration is located at:

```text
configs/swsynth/scientific/
└── reqml_projected3d_clean_training_v1/
    └── homogeneous_base.json
```

## Projected-3D wavefields

The direction space is three-dimensional and uses full-sphere angular support.
The measured wavefield remains a two-dimensional `x-z` observation plane.

The source count is varied because REQ performance depends on the projected
wavefield geometry and not only on the local wavelength. The selected values
cover directional, sparse multi-source, intermediate, and broad-angular
projected-3D regimes.

## Propagation model

All geometry families in this campaign set should use:

```text
propagation.model = spherical_wave
```

Using the same propagation model prevents propagation type from becoming
confounded with material geometry. In particular, the homogeneous family
should not use `plane_wave` while the heterogeneous families use
`spherical_wave`.

## Clean-data definition

The campaign contains no additive measurement noise or simulated readout noise:

```text
noise.snr_db = 1000
```

Random source phases and the configured source-amplitude jitter are part of
the reproducible wavefield realization. They are controlled by the run seed.

Noise robustness, readout effects, and reliability masking will be evaluated
in later stages after the clean predictor has been trained and frozen.

## Spatial sampling

The campaign varies both `dx` and `dz` independently, producing four sampling
configurations:

```text
0.25 × 0.25 mm
0.25 × 0.40 mm
0.40 × 0.25 mm
0.40 × 0.40 mm
```

The most demanding sampling condition is:

```text
cs = 1.0 m/s
frequency = 600 Hz
max(dx,dz) = 0.40 mm
shear PPW = 4.1667
```

There are 30 runs below 6 shear points per wavelength. These cases are kept
deliberately as a coarse-sampling regime.

Because `swsynth` constructs the field synthetically rather than solving the
k-Wave finite-difference equations, this PPW value is not a solver-stability
criterion. It is nevertheless an important spectral-sampling variable for
REQ and must be preserved in the downstream dataset metadata.

REQ-ML evaluation should therefore report or stratify performance by shear
points per wavelength.

## Reproducibility

The campaign JSON is the source of truth. The parameter combinations are
expanded deterministically by the standard campaign infrastructure.

The public workflow is:

```matlab
[campaign, metadata] = ...
    simcampaigns.loadCampaignJson(campaignFile);

[runs, expansion] = ...
    simcampaigns.expandCampaign(campaignFile);

[~, validation] = ...
    simcampaigns.validateCampaign(campaignFile);

report = simcampaigns.runCampaign( ...
    campaignFile, ...
    Resume=true, ...
    ContinueOnError=true);
```

No campaign-specific generation script is required.

Each expanded run receives:

- a deterministic ordinal;
- a configuration-derived SHA-256 hash;
- a deterministic run identifier;
- a reproducible seed;
- an independently saved resolved configuration;
- a standardized wavefield sample;
- campaign-level status and metadata.

The campaign runner supports safe resume. Completed runs with matching hashes
are skipped rather than recomputed.

## Current validation status

The homogeneous campaign has been checked before execution:

```text
Expanded runs: 480
Unique run IDs: 480
Unique configuration hashes: 480
Campaign dry-run: 480/480 swsynth runs valid
Minimum shear PPW: 4.1667
Runs below 6 shear PPW: 30
```

The Cartesian sweep is exactly balanced:

| Parameter | Levels | Runs per level |
|---|---:|---:|
| Shear-wave speed | 4 | 120 |
| Frequency | 3 | 160 |
| Direction count | 5 | 96 |
| `dx` | 2 | 240 |
| `dz` | 2 | 240 |
| Seed | 2 | 240 |

## Planned campaign families

After the homogeneous campaign is completed and checked, the same campaign
infrastructure will be used for:

1. bilayer;
2. circular inclusion;
3. bilayer with circular inclusion.

The heterogeneous campaign designs will use reduced Cartesian grids so that
their configurations remain explicit, understandable, and reproducible
without introducing campaign-specific generation scripts.

## External validation

k-Wave simulations are not part of this training campaign. They will form a
separate external validation set for the IUS study after the clean REQ-ML
model has been trained and frozen.
