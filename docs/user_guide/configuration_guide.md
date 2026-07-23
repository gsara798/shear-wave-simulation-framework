# Configuration Guide

This guide explains how to create and modify JSON configurations for the shear-wave simulation framework.

All examples follow the verified workflow:

```text
copy an existing configuration
→ edit selected parameters
→ run a dry run
→ execute the solver
```

## 1. Start from an existing configuration

Do not begin with an empty JSON file. Copy the closest verified example and modify only the parameters required for the new simulation.

### Available 2D configured case

```text
configs/two_d/homogeneous_directional_cli.json
```

### Representative 3D configured cases

```text
configs/three_d/homogeneous_directional_req_validation.json
configs/three_d/heterogeneous_sphere_3d.json
configs/three_d/homogeneous_generated_angular_n32_p8_req_validation.json
configs/three_d/heterogeneous_combined_generated_angular_n32_p8.json
```

Example:

```bash
cp   configs/three_d/homogeneous_directional_req_validation.json   configs/three_d/my_simulation.json
```

Change the copied file, not the reference configuration.

## 2. Validate every change with a dry run

Before executing k-Wave:

```bash
./scripts/kwsim-run   configs/three_d/my_simulation.json   --dry-run
```

A successful dry run ends with:

```text
Dry run completed successfully.
No solver was executed and no outputs were created.
```

A dry run validates and resolves the configuration without running the solver. It should be the first check after every parameter change.

## 3. Main configuration structure

Configured simulations use JSON objects organized into sections such as:

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
  "req_validation": {},
  "output": {}
}
```

Some configurations contain additional sections such as:

```text
analysis
execution
diagnostics
attenuation
```

Not every section is active in every simulation.

## 4. Change the shear-wave speed

The homogeneous background shear-wave speed is:

```json
"medium": {
  "cs_m_s": 2.0
}
```

Example:

```json
"medium": {
  "cs_m_s": 2.5
}
```

The unit is meters per second. This edit was dry-run verified in both 2D and 3D.

## 5. Change the excitation frequency

The source frequency is:

```json
"source": {
  "f0_hz": 500
}
```

Example:

```json
"source": {
  "f0_hz": 400
}
```

The unit is hertz. This edit was dry-run verified in both 2D and 3D.

## 6. Shear wavelength and spatial resolution

The shear wavelength is:

```text
lambda_s = cs / f0
```

For example:

```text
cs = 2 m/s
f0 = 500 Hz
lambda_s = 4 mm
```

If the spatial step is 0.5 mm, the wavelength is sampled by:

```text
4 mm / 0.5 mm = 8 points per wavelength
```

Changing `cs_m_s`, `f0_hz`, `dx_m`, `dy_m`, or `dz_m` changes the number of points per wavelength.

### 2D

```json
"grid": {
  "Nx": 96,
  "Nz": 96,
  "dx_m": 0.0005,
  "dz_m": 0.0005
}
```

### 3D

```json
"grid": {
  "Nx": 48,
  "Ny": 32,
  "Nz": 48,
  "dx_m": 0.0005,
  "dy_m": 0.0005,
  "dz_m": 0.0005
}
```

Increasing the number of grid points or decreasing the spatial step increases memory use and solver time, especially in 3D.

## 7. Grid extent

The physical grid extent is approximately:

```text
Lx = (Nx - 1) * dx
Ly = (Ny - 1) * dy
Lz = (Nz - 1) * dz
```

The computational domain also includes the solver PML according to the selected settings.

When adding a large object, make sure there is enough space for the object, source region, sensor region, required boundary clearance, and useful propagation distance.

## 8. Medium properties

A typical homogeneous medium block is:

```json
"medium": {
  "cs_m_s": 2.0,
  "rho_kg_m3": 1000,
  "cp_mode": "reduced",
  "reduced_cp_factor": 10
}
```

`cs_m_s` is the shear-wave speed in meters per second.

`rho_kg_m3` is density in kilograms per cubic meter.

With:

```json
"cp_mode": "reduced",
"reduced_cp_factor": 10
```

the framework uses:

```text
cp = reduced_cp_factor * cs
```

The reduced compressional speed is a computational development approximation. It is not a claim that biological tissue has that compressional speed.

## 9. Change the run name

The output name is controlled by:

```json
"output": {
  "run_name": "my_simulation"
}
```

With timestamps enabled, the output directory is similar to:

```text
outputs/<timestamp>_my_simulation/
```

Use descriptive names that identify the physical case.

## 10. Output controls

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
  "save_req_validation_sample": false,
  "save_figures": true,
  "save_matlab_figures": true
}
```

Keep the result, summary, and resolved configuration enabled for reproducible runs.

Full time-series output can be very large. Enable it only when the temporal field is required.

`save_req_validation_sample` exports a lightweight complex field and metadata for external REQ validation when the selected case supports it.

## 11. Time controls

A typical time block is:

```json
"time": {
  "settling_cycles": 2,
  "analysis_cycles": 8,
  "end_time_s": null
}
```

`settling_cycles` allows the field to develop before analysis.

`analysis_cycles` controls the harmonic-analysis interval.

Changing frequency changes the duration of one cycle:

```text
cycle duration = 1 / f0
```

Do not shorten the simulation without checking steady-state convergence.

## 12. Source controls

A directional source may include:

```json
"source": {
  "f0_hz": 500,
  "velocity_amplitude_m_s": 0.000001,
  "contact_radius_m": 0.001,
  "ramp_cycles": 1,
  "target_direction_xyz": [1, 0, 0],
  "polarization_xyz": [0, 0, 1]
}
```

For a shear-dominant directional source, polarization should be transverse to the main propagation direction.

For multi-source cases, start from a verified bank configuration rather than manually constructing the full source block.

Examples:

```text
configs/three_d/homogeneous_partial_3d_n8_p2_req_validation.json
configs/three_d/homogeneous_generated_angular_n32_p8_req_validation.json
configs/three_d/homogeneous_generated_angular_n128_p8_req_validation.json
```

## 13. Geometry

The 3D framework supports:

- homogeneous media;
- spheres;
- finite cylinders;
- bilayers;
- combined geometries.

Start from the closest verified example:

```text
configs/three_d/heterogeneous_sphere_3d.json
configs/three_d/heterogeneous_cylinder_3d.json
configs/three_d/heterogeneous_bilayer_3d.json
configs/three_d/heterogeneous_combined_3d.json
```

Geometry values use meters and SI material units.

The framework validates object placement and can reject objects that violate the sensor-region or boundary-clearance requirements.

## 14. Seed and reproducibility

The top-level seed is:

```json
"seed": 1001
```

Keep the same seed to reproduce deterministic random phases and source-bank choices supported by the configuration.

Change the seed deliberately when studying realization-to-realization variability.

## 15. Requested and resolved configurations

The requested JSON contains the values supplied by the user.

After validation and resolution, the framework saves:

```text
config/resolved_config.json
config/resolved_config.mat
```

The resolved configuration can include defaults, derived values, resolved geometry, generated phases, source placement, and operational settings.

For reproducibility, preserve the resolved configuration rather than relying only on the original JSON.

## 16. Verified parameter-edit workflow

The following workflow was dry-run verified in both 2D and 3D:

1. copy a verified JSON;
2. change `medium.cs_m_s`;
3. change `source.f0_hz`;
4. change `output.run_name`;
5. run `--dry-run`.

Example:

```bash
cp   configs/three_d/homogeneous_directional_req_validation.json   /tmp/kwsim_modified.json

python3 - <<'PY'
import json
from pathlib import Path

path = Path("/tmp/kwsim_modified.json")
cfg = json.loads(path.read_text())

cfg["medium"]["cs_m_s"] = 2.5
cfg["source"]["f0_hz"] = 400
cfg["output"]["run_name"] = "documentation_test_3d"

path.write_text(json.dumps(cfg, indent=2) + "\n")
PY

./scripts/kwsim-run   /tmp/kwsim_modified.json   --dry-run
```

The verified output reported:

```text
Shear speed:   2.5 m/s
Frequency:     400 Hz
Mode:          dry run
```

## 17. Recommended editing sequence

```text
1. Choose the closest verified configuration.
2. Copy it to a new descriptive file.
3. Change one group of parameters at a time.
4. Run a dry run after each meaningful change.
5. Review grid size, physical dimensions, frequency, and SWS.
6. Execute the solver.
7. Inspect validation_summary.txt.
8. Inspect the resolved configuration.
9. Inspect diagnostic figures.
10. Record the run directory in the analysis notes.
```

## 18. Parameters that require additional care

Do not modify these casually:

- PML size and placement;
- CFL;
- minimum points per wavelength;
- source contact sampling;
- Dirichlet source layout;
- compressional-speed model;
- arbitrary source polarization;
- source-bank generation constraints;
- end time and settling duration;
- memory limits;
- validation thresholds.

These parameters affect numerical stability, physical interpretation, or result validity.

## 19. Current scope

This guide documents the currently verified configuration workflow.

It does not yet provide a complete field-by-field schema for every source-bank and heterogeneous-geometry option. Those details will be added incrementally and verified against executable configurations.
