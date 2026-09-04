# Terminology

This glossary defines the main operational and physical terms used by the active simulation framework.

## Backend

The solver or generator used to create a wavefield.

- `kwsim`: k-Wave elastic time-domain simulations.
- `swsynth`: analytical or Eikonal-based synthetic wavefields.

The root-level `run_simulation` function dispatches to the correct backend from the JSON configuration.

## Campaign

A reproducible collection of related simulations defined by one campaign JSON. Campaigns can use Cartesian parameter sweeps or explicit named runs.

Public interface:

```matlab
report = run_campaign("path/to/campaign.json");
```

## Config / configuration

A JSON file describing one simulation. The input JSON records user intent; the resolved configuration records defaults, derived values, generated geometry, and the actual settings used for execution.

## Directional field

A wavefield dominated by one principal propagation direction. Source count alone does not define directionality; the realized angular structure is what matters physically.

## Diffuse field

An idealized field with broad angular support and no dominant propagation direction. A many-source simulation should not automatically be called diffuse without checking its realized directional structure.

In public examples, direction counts of 1, 16, and 128 are used as directional/intermediate/diffuse examples. These are not universal thresholds.

## Dry run

Validation of a configuration without solver execution or simulation output creation.

Single run:

```matlab
run_simulation("path/to/config.json", DryRun=true)
```

Campaign:

```matlab
run_campaign("path/to/campaign.json", DryRun=true)
```

## Harmonic field

A complex wavefield representing amplitude and phase at one temporal frequency. k-Wave runs obtain this field by reducing late-time time-domain sensor data at the configured excitation frequency.

## Heterogeneous medium

A simulation domain containing more than one material. Public examples include inclusions and bilayers.

## In-plane / out-of-plane

Terms defined relative to the `x-z` observation plane.

- in-plane directions lie primarily in `x-z`;
- out-of-plane directions include a nonzero `y` component.

For `swsynth/projected3d`, directions and polarization are 3D while the observed field remains a 2D `U(z,x)` plane.

## Intermediate field

A convenient descriptive label for a field with more angular complexity than a directional field but without claiming ideal diffusivity.

## k-Wave

The external MATLAB toolbox used by the `kwsim` backend. It is not vendored in this repository.

## Measurement axis

The physical axis associated with the exported scalar wavefield component. It is stored in `wavefield_sample.measurement.axis_xyz` rather than inferred from array orientation.

## P wave / compressional wave

A longitudinal elastic wave whose particle motion is primarily parallel to propagation direction.

## P/S contamination

A measure of compressional content relative to shear content. The exact diagnostic and acceptance threshold depend on the configured scenario.

## PML

Perfectly matched layer used to reduce numerical boundary reflections in k-Wave. PML settings affect cost and boundary behavior and should be changed carefully.

## Points per wavelength (PPW)

Number of spatial samples across one wavelength. For shear waves:

```text
lambda_s = cs / f0
PPW = lambda_s / spacing
```

Insufficient PPW can make a simulation inaccurate even when the solver completes.

## Preflight

Checks performed before solver execution, such as configuration consistency, grid resolution, geometry, CFL, source/sensor placement, and resource limits.

## Projected 3D

A synthetic field generated using three-dimensional propagation directions and polarization but observed on a two-dimensional `x-z` plane.

It is distinct from both a strictly 2D field and a volumetric 3D field.

## Public array orientation

The framework exposes arrays in physical-coordinate order:

```text
2D: [Nz, Nx]       -> suffix _zx
3D: [Nz, Ny, Nx]   -> suffix _zyx
```

k-Wave internal solver orientation is handled inside the adapter layer.

## Run

One simulation condition. A run may be launched directly with `run_simulation` or created as one member of a campaign.

## Run directory

The standardized output directory for one completed simulation:

```text
config/
data/
figures/
validation/
report/   # optional
```

## S wave / shear wave

A transverse elastic wave whose particle motion is primarily perpendicular to propagation direction.

## Scenario

A descriptive identifier in the configuration. It can participate in backend validation and output naming, so it should not be changed casually without understanding the configuration contract.

## Seed

Integer controlling supported deterministic random choices, such as phases or generated directions. Fixed seeds enable reproducible realizations.

## Sensor ROI

The region recorded or retained for analysis. For k-Wave 2D, the public adapter crops truth maps to the sensor ROI when required. For current k-Wave 3D export, the `wavefield_sample` contains the complete sensor volume.

## Source bank

A set of multiple source contacts or directional contributors used to generate a more complex wavefield.

## Source polarization

Direction of prescribed particle motion. For shear-dominant excitation it should be transverse to the intended propagation direction.

## Steady state

A regime in which the harmonic field changes little across late-time analysis intervals. k-Wave validation can use late-cycle comparisons to assess whether transients have sufficiently settled.

## `wavefield_sample`

The backend-neutral interchange object saved as:

```text
data/wavefield_sample.mat
```

It stores coordinates, complex harmonic wavefield data, frequency, measurement metadata, propagation metadata, truth maps when available, validation state, and provenance.

It is estimator-neutral.

## 2D wavefield sample

```text
spatial_dimension = 2
coordinates.array_order = "zx"
wavefield.data_zx(z,x)
```

## 3D wavefield sample

```text
spatial_dimension = 3
coordinates.array_order = "zyx"
wavefield.data_zyx(z,y,x)
```

Current k-Wave 3D export preserves the full sensor volume; it is not reduced to a central 2D slice.

## Validation

Checks used to determine whether a resolved configuration or completed simulation satisfies its configured numerical and physical requirements.

Solver completion alone does not imply validation success.

## Volumetric 3D

A true three-dimensional field defined over `z-y-x`, exported as `data_zyx`.

## `x`, `y`, `z`

Public physical coordinates:

```text
x = lateral
y = elevational / out-of-plane
z = axial / depth
```
