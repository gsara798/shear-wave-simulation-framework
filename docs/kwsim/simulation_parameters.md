# Simulation Parameters

This document summarizes the main parameter groups used by the active k-Wave backend. Exact available fields depend on dimensionality and scenario, so new configurations should always start from a working public example.

Recommended starting points:

```text
examples/kwave/2d/homogeneous/config.json
examples/kwave/2d/inclusion/config.json
examples/kwave/2d/bilayer/config.json
examples/kwave/3d/homogeneous/config.json
examples/kwave/3d/inclusion/config.json
examples/kwave/3d/bilayer/config.json
```

After editing a configuration, validate it with:

```matlab
run_simulation("path/to/config.json", DryRun=true)
```

## Top-level identity

### `dimension`

Selects the 2D or 3D k-Wave path. Do not convert a 2D configuration to 3D by changing only this value; grid, source, sensor, geometry, and validation structures also differ.

### `scenario`

Describes the physical/validation case and contributes to output identity. Preserve the scenario conventions of the example you are modifying unless you understand the associated dispatch behavior.

### `seed`

Controls deterministic random choices supported by the configuration. Keep it fixed for exact realization reproducibility; vary it deliberately for realization studies.

## Grid

Typical grid fields include:

```text
Nx, Nz, dx_m, dz_m                 # 2D
Nx, Ny, Nz, dx_m, dy_m, dz_m       # 3D
cfl
minimum_shear_ppw
```

All spacings are in meters.

The shear wavelength is:

```text
lambda_s = cs / f0
```

and points per wavelength are determined by `lambda_s / spacing`. Increasing frequency or decreasing shear-wave speed reduces wavelength and can make a previously valid grid under-resolved.

Increasing point count or decreasing spacing increases memory use and runtime, especially in 3D.

## Medium

Common homogeneous-medium fields describe:

```text
shear-wave speed
compressional-speed policy
density
```

Shear-wave speed is expressed in m/s and density in kg/m^3.

The reduced-compressional-speed mode is a computational approximation used to reduce elastic simulation cost. It must not be interpreted as physical tissue compressional speed.

Heterogeneous configurations define local material properties through geometry/material structures. Use an existing inclusion or bilayer example as the template.

## Geometry

The active backend supports homogeneous domains and heterogeneous geometries including inclusion and bilayer examples, with additional primitives available in the implementation.

Geometry is expressed in SI units and public physical coordinates:

```text
x = lateral
y = elevational / out-of-plane
z = axial / depth
```

Object placement and boundary clearance are validated before execution.

## Source

Source configuration can control:

```text
f0_hz
velocity amplitude
contact model and size
contact sampling
source location or boundary face
target propagation direction
polarization
phase
source-bank count and policies
```

### Frequency

`f0_hz` controls temporal frequency and, together with SWS, the shear wavelength. Frequency changes therefore affect both physics and numerical resolution.

### Amplitude

The current model prescribes particle velocity at source nodes. In the linear regime, changing amplitude should scale wavefield amplitude rather than wave speed.

### Contact geometry

Finite contacts represent a nonzero source region on the numerical boundary. Their realized discretization depends on grid spacing and source sampling policy.

### Direction and polarization

For shear-dominant excitation, polarization should be transverse to the intended propagation direction.

### Source banks

Multi-source configurations can define multiple directions, phases, and source contacts. More sources do not automatically imply a diffuse field; realized angular structure must be interpreted separately.

## Time

Important time controls include settling and analysis intervals.

- settling cycles allow startup transients to decay;
- analysis cycles provide data for harmonic extraction and steady-state assessment.

Shortening either can reduce runtime but may invalidate the harmonic field. Use validation metrics rather than runtime alone to choose these settings.

## Sensor

The sensor configuration controls the region recorded by k-Wave and retained for harmonic analysis.

Important considerations include:

- separation from source contacts;
- boundary/PML margin;
- memory required for recorded time-series data;
- whether a full 3D sensor volume is retained.

The current public 3D `wavefield_sample` exports the full available sensor volume as `data_zyx(z,y,x)`.

## Solver

Solver options can control numerical backend, data precision, and PML behavior.

These settings can materially affect memory, runtime, stability, and reproducibility. They should normally be inherited from a verified example unless a numerical study specifically requires changing them.

## Harmonic analysis

k-Wave runs are time-domain simulations. The framework reduces late-time sensor data to a complex harmonic field at the excitation frequency.

The resulting complex field carries both amplitude and phase. Validation may also examine source-frequency purity, stationarity, P/S contamination, or speed recovery depending on scenario.

## Diagnostics and validation thresholds

Diagnostics can define limits for numerical resolution, memory, wavefield validity, physical contamination, geometry, and other scenario-specific checks.

Thresholds are part of a configured scientific test. Do not loosen a threshold merely to make a failing simulation pass; first determine whether the failure is numerical, physical, or operational.

## Output

The public `run_simulation` interface standardizes the important outputs regardless of backend:

```text
config/
data/wavefield_sample.mat
data/run_summary.json
figures/
validation/
report/                     # optional
```

k-Wave may retain additional native MAT files and metadata according to backend output settings.

The standardized wavefield export is estimator-neutral; this repository does not contain downstream estimator processing.

## Campaign overrides

Campaigns modify existing configuration values using paths such as:

```text
medium.cs_m_s
source.f0_hz
seed
```

or scenario-specific nested paths.

Use a Cartesian `sweep` only when every parameter combination is meaningful. Use explicit `runs` when several values define one paired physical condition.

Validate the complete campaign before execution:

```matlab
run_campaign("path/to/campaign.json", DryRun=true)
```

## Parameters to change with extra care

The following can strongly affect stability, validity, or interpretation:

- grid spacing and point count;
- CFL;
- PML settings;
- compressional-speed model;
- source/contact discretization;
- source polarization;
- sensor ROI;
- settling and analysis duration;
- memory limits;
- validation thresholds.

When uncertain, copy the closest public example, change one parameter group at a time, and dry-run after each meaningful change.
