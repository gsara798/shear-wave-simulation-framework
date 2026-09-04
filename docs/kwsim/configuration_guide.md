# Configuration Guide

This guide explains how to create and modify JSON configurations for the k-Wave backend.

Use the workflow:

```text
start from a public example
→ copy the JSON
→ edit selected parameters
→ dry run
→ execute
→ inspect validation and figures
```

## Start from a public example

Do not begin from an empty JSON file. The recommended starting points are:

```text
examples/kwave/2d/homogeneous/config.json
examples/kwave/2d/inclusion/config.json
examples/kwave/2d/bilayer/config.json
examples/kwave/3d/homogeneous/config.json
examples/kwave/3d/inclusion/config.json
examples/kwave/3d/bilayer/config.json
```

Copy the closest case and modify the copy.

## Validate before execution

```matlab
outcome = run_simulation( ...
    "path/to/config.json", ...
    DryRun=true);
```

A dry run resolves defaults and derived values, checks the configuration, and performs resource preflight without executing k-Wave.

## Main configuration sections

A k-Wave configuration is organized into sections such as:

```json
{
  "dimension": 3,
  "scenario": "my_scenario",
  "seed": 1001,
  "grid": {},
  "medium": {},
  "geometry": {},
  "source": {},
  "time": {},
  "sensor": {},
  "solver": {},
  "analysis": {},
  "execution": {},
  "diagnostics": {},
  "output": {}
}
```

Not every section is used by every scenario. Prefer copying an existing working example over adding fields from memory.

## Shear-wave speed

Typical homogeneous configurations define:

```json
"medium": {
  "cs_m_s": 2.0
}
```

Units are m/s.

## Excitation frequency

```json
"source": {
  "f0_hz": 500
}
```

The shear wavelength is:

```text
lambda_s = cs / f0
```

Changing `cs_m_s`, `f0_hz`, or grid spacing changes the points per wavelength and therefore numerical resolution.

## Grid

A 2D grid defines `Nx`, `Nz`, `dx_m`, and `dz_m`. A 3D grid additionally defines `Ny` and `dy_m`.

Increasing point count or decreasing spacing increases memory use and runtime, especially in 3D. Always dry-run after changing grid size or spacing.

## Medium and compressional speed

The k-Wave backend supports homogeneous and heterogeneous elastic media. The reduced-compressional-speed mode is an explicit computational approximation used to reduce cost; it is not a claim about physical tissue compressional speed.

## Geometry

Public examples demonstrate homogeneous media, inclusions, and bilayers. The backend also contains additional geometry primitives used by advanced configurations.

All geometry values use SI units. Placement is validated against the numerical domain and relevant source/sensor constraints.

## Sources

Source configuration controls frequency, amplitude, contact geometry, target propagation direction, polarization, and source-bank policies.

For shear-dominant excitation, source polarization should be transverse to the intended propagation direction. Multi-source and generated angular fields should be based on an existing verified configuration rather than assembled manually from scratch.

## Time and harmonic analysis

k-Wave simulations run in the time domain. Late-time sensor data are reduced to a complex harmonic field at the configured source frequency.

Settling and analysis duration affect steady-state quality and runtime. Do not shorten them without checking the validation metrics.

## Output behavior

When a configuration is run through `run_simulation`, the public runner ensures that a standardized wavefield sample is saved and creates the common run layout:

```text
config/
data/wavefield_sample.mat
data/run_summary.json
figures/
validation/
```

The backend may retain additional native files according to its output settings.

## Seed and reproducibility

Keep seeds fixed when exact realization reproducibility is required. Change them deliberately when studying realization variability.

## Requested versus resolved configuration

The input JSON records user intent. The resolved configuration records defaults, derived timing, generated source geometry, and other values actually used by the backend.

Preserve the resolved configuration with scientific results.

## Recommended editing sequence

```text
1. Choose the closest public example.
2. Copy its config.json to a descriptive location.
3. Change one parameter group at a time.
4. Run run_simulation(..., DryRun=true).
5. Review resolution, frequency, SWS, geometry, source placement, and memory.
6. Execute with run_simulation(...).
7. Inspect validation and standard figures.
8. Inspect the resolved configuration.
9. Record the output directory and software commit.
```

## Parameters requiring extra care

Changes to the following can affect stability or interpretation and should not be made casually:

- PML settings;
- CFL;
- points per wavelength;
- source/contact sampling;
- source polarization;
- angular source-bank geometry;
- compressional-speed model;
- settling and analysis duration;
- sensor region;
- memory limits;
- validation thresholds.

For detailed field-level parameter definitions, see [Simulation Parameters](simulation_parameters.md).
