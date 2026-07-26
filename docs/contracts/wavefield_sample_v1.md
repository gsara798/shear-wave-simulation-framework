# Wavefield Sample Contract v1

## Purpose

The wavefield sample is a backend-neutral data contract for downstream
estimators and dataset tooling.

It must not encode assumptions specific to REQ or any other estimator.

Potential consumers include:

- REQ estimators;
- wavelet estimators;
- Helmholtz estimators;
- finite-difference estimators;
- machine-learning models;
- visualization and quality-control tools.

Potential producers include:

- `swsynth`;
- `kwsim`;
- finite-element solvers;
- Eikonal simulators;
- experimental acquisitions.

## Required identity fields

```text
schema_name
schema_version
sample_id
dataset_id
generator
scenario
seed
```

For version 1:

```text
schema_name = wavefield_sample
schema_version = 1.0
```

## Coordinates

```text
coordinates.x_m
coordinates.z_m
coordinates.dx_m
coordinates.dz_m
coordinates.array_order
coordinates.observation_plane
coordinates.observation_y_m
```

Version 1 uses:

```text
array_order = zx
```

All public maps therefore follow:

```text
array(z,x)
```

## Wavefield

```text
wavefield.data_zx
wavefield.component
wavefield.frequency_hz
wavefield.angular_frequency_rad_s
wavefield.is_complex
wavefield.units
wavefield.output_convention
```

`data_zx` is the estimator-facing wavefield.

## Truth

```text
truth.cs_map_zx
truth.k_map_zx
truth.material_id_zx
truth.valid_mask_zx
```

All truth maps must have the same z-x dimensions as `wavefield.data_zx`.

## Medium

```text
medium.background_cs_m_s
medium.combine_mode
medium.objects
```

## Propagation

```text
propagation.model
propagation.direction_space
propagation.direction_count
propagation.direction_sampling_method
propagation.angular_support
propagation.require_in_plane
```

## Directions and sources

```text
directions.ux
directions.uy
directions.uz
directions.plane_intersection
sources
```

## Validation

```text
validation.valid
validation.analysis_ready
validation.output_convention
```

`analysis_ready` is intentionally estimator-neutral. Individual estimators
may apply additional requirements after loading the sample.

## Provenance

```text
provenance.resolved_config
provenance.run_id
provenance.campaign_id
provenance.source_path
provenance.created_utc
```

## Backend implementations

The first implementation is:

```matlab
result = swsynth.run(cfg);
sample = result.sample;
```

or explicitly:

```matlab
sample = swsynth.buildWavefieldSample(result);
```

A future `kwsim` implementation should produce the same top-level contract.
