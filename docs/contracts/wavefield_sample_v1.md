# Wavefield Sample Contract v1

## Purpose

`wavefield_sample` is the backend-neutral interchange contract produced by the simulation framework for downstream analysis.

It must remain estimator-neutral. The contract describes the wavefield, coordinates, truth information, propagation metadata, validation state, and provenance without assuming a particular estimator.

Current producers include both `swsynth` and `kwsim`.

## Identity

```text
schema_name = wavefield_sample
schema_version = 1.0
```

Common identity fields include:

```text
sample_id
dataset_id
generator
scenario
seed
```

## Spatial dimensionality

The contract supports planar and volumetric samples.

### 2D

```text
spatial_dimension = 2
coordinates.array_order = "zx"
wavefield.data_zx(z,x)
```

Coordinates include:

```text
coordinates.x_m
coordinates.z_m
coordinates.dx_m
coordinates.dz_m
coordinates.observation_plane
coordinates.observation_y_m
```

Truth fields use the same `zx` convention, for example:

```text
truth.cs_map_zx
truth.k_map_zx
truth.rho_kg_m3_zx
truth.material_id_zx
truth.valid_mask_zx
```

### 3D

```text
spatial_dimension = 3
coordinates.array_order = "zyx"
wavefield.data_zyx(z,y,x)
```

Coordinates include:

```text
coordinates.x_m
coordinates.y_m
coordinates.z_m
coordinates.dx_m
coordinates.dy_m
coordinates.dz_m
```

Truth fields use the same `zyx` convention:

```text
truth.cs_map_zyx
truth.k_map_zyx
truth.rho_kg_m3_zyx
truth.material_id_zyx
truth.valid_mask_zyx
```

All truth maps must match the spatial dimensions of the exported wavefield.

## Wavefield metadata

Common fields include:

```text
wavefield.component
wavefield.quantity
wavefield.frequency_hz
wavefield.angular_frequency_rad_s
wavefield.is_complex
wavefield.units
wavefield.phasor_convention
wavefield.output_convention
```

The current public measurement axis is recorded separately in:

```text
measurement.quantity
measurement.component
measurement.axis_xyz
```

## Medium metadata

```text
medium.background_cs_m_s
medium.combine_mode
medium.objects
medium.config
```

The exact medium metadata available can depend on the producing backend.

## Propagation metadata

```text
propagation.model
propagation.source_dimension
propagation.direction_space
propagation.direction_count
propagation.direction_sampling_method
propagation.angular_support
propagation.require_in_plane
```

A sample can therefore distinguish, for example, a truly 2D field from a projected-3D field even when both export a 2D `data_zx` observation.

## Directions and sources

Direction metadata can include:

```text
directions.ux
directions.uy
directions.uz
directions.xyz
directions.plane_intersection
sources
```

Synthetic wavefields can expose the generating propagation directions. k-Wave runs can expose resolved physical source metadata instead.

## Extraction metadata

`extraction` describes how the public wavefield was obtained from backend-native results.

Current k-Wave conventions include:

```text
2D: method = native_2d_sensor_roi
3D: method = native_3d_sensor_roi
```

A k-Wave 3D result exports the complete sensor volume; it is not collapsed to a central 2D plane.

## Validation

```text
validation.valid
validation.analysis_ready
validation.output_convention
validation.backend_diagnostics
```

`analysis_ready` is intentionally estimator-neutral. Downstream consumers may impose additional requirements.

## Provenance

```text
provenance.resolved_config
provenance.run_id
provenance.campaign_id
provenance.source_path
provenance.created_utc
provenance.result_schema_version
```

## Saved file

Public runners save the contract as:

```text
data/wavefield_sample.mat
```

with MATLAB variable:

```text
wavefield_sample
```

Both `run_simulation` and campaign runs use this same contract, allowing downstream analysis to remain independent of the simulation backend.
