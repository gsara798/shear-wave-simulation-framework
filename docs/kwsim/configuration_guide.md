# Configuration Guide

This guide explains how to create and modify JSON configurations for the k-Wave simulation backend.

Use the workflow:

```text
copy a verified configuration
→ edit selected parameters
→ dry run
→ execute
→ inspect physical validation
```

## Start from an existing configuration

Do not begin from an empty JSON file. Start from the closest verified case.

Representative configurations include:

```text
configs/kwsim/two_d/homogeneous_directional_cli.json
configs/kwsim/three_d/homogeneous_directional_cli.json
configs/kwsim/three_d/heterogeneous_sphere_3d.json
configs/kwsim/three_d/heterogeneous_cylinder_3d.json
configs/kwsim/three_d/heterogeneous_bilayer_3d.json
configs/kwsim/three_d/heterogeneous_combined_3d.json
```

Copy the closest case and modify the copy.

## Validate before execution

```bash
./scripts/kwsim-run configs/kwsim/three_d/homogeneous_directional_cli.json --dry-run
```

A dry run resolves defaults and derived values, checks the configuration, and performs resource preflight without executing k-Wave.

## Main configuration sections

A configured simulation is organized into sections such as:

```json
{
  "dimension": 3,
  "scenario": "homogeneous_directional_3d",
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
  "output": {},
  "wavefield_sample": {}
}
```

Not every section is used by every scenario.

## Shear-wave speed

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

Units are Hz.

The shear wavelength is

```text
lambda_s = cs / f0
```

Changing `cs_m_s`, `f0_hz`, or the grid spacing changes the number of points per wavelength and therefore the numerical resolution.

## Grid

Typical 2D fields use:

```json
"grid": {
  "Nx": 96,
  "Nz": 96,
  "dx_m": 0.0005,
  "dz_m": 0.0005
}
```

Typical 3D fields additionally define `Ny` and `dy_m`.

Increasing the number of points or decreasing spacing increases memory use and runtime, especially in 3D.

## Medium and compressional speed

A representative homogeneous medium is:

```json
"medium": {
  "cs_m_s": 2.0,
  "rho_kg_m3": 1000,
  "cp_mode": "reduced",
  "reduced_cp_factor": 10
}
```

The reduced compressional-speed mode is a computational approximation used to reduce cost. It is not a claim about physical tissue compressional speed.

## Sources

A directional 3D source may define:

```json
"source": {
  "f0_hz": 500,
  "velocity_amplitude_m_s": 0.000001,
  "contact_radius_m": 0.001,
  "target_direction_xyz": [1, 0, 0],
  "polarization_xyz": [0, 0, 1]
}
```

For shear-dominant propagation, the prescribed polarization should be transverse to the intended propagation direction.

For multi-source and generated angular fields, begin from an existing verified source-bank configuration rather than constructing the entire bank manually.

## Geometry

The 3D backend supports homogeneous media, spherical inclusions, finite cylinders, bilayers, and combined heterogeneous geometries.

All geometry values use SI units. Object placement is validated against domain and sensor-region constraints.

## Time and harmonic analysis

A typical time block is:

```json
"time": {
  "settling_cycles": 2,
  "analysis_cycles": 8,
  "end_time_s": null
}
```

The solver runs in the time domain. Late-time sensor data are reduced to complex harmonic fields at the configured source frequency.

Do not shorten the simulation without checking steady-state behavior.

## Output controls

A representative output block is:

```json
"output": {
  "enabled": true,
  "directory": "outputs",
  "run_name": "my_simulation",
  "append_timestamp": true,
  "overwrite": false,
  "save_result": true,
  "save_summary": true,
  "save_config_mat": true,
  "save_config_json": true,
  "save_time_series": false,
  "save_wavefield_sample": false,
  "save_figures": true,
  "save_matlab_figures": false
}
```

`save_wavefield_sample` exports the backend-neutral harmonic wavefield contract for downstream analysis. It is not tied to a particular estimator.

Full time-series output can be large and should only be enabled when needed.

## Seed and reproducibility

```json
"seed": 1001
```

Keep seeds fixed to reproduce deterministic random phases and generated source-bank choices. Change them deliberately when studying realization variability.

## Requested and resolved configurations

The requested JSON records user intent. The resolved configuration records the complete values used after defaults, derived parameters, generated geometry, and operational settings are applied.

Preserve the resolved configuration for scientific reproducibility.

## Recommended editing sequence

```text
1. Choose the closest verified configuration.
2. Copy it to a descriptive file.
3. Change one group of parameters at a time.
4. Dry-run after each meaningful change.
5. Review grid resolution, frequency, SWS, geometry, and memory.
6. Execute the solver.
7. Inspect the validation report and diagnostic figures.
8. Inspect the resolved configuration.
9. Record the output directory and software commit.
```

## Parameters requiring extra care

Do not change these casually:

- PML size and placement;
- CFL;
- minimum points per wavelength;
- contact sampling;
- source polarization;
- source-bank geometry constraints;
- compressional-speed model;
- settling and analysis duration;
- memory limits;
- physical validation thresholds.

These parameters affect numerical stability, physical interpretation, or scientific validity.
