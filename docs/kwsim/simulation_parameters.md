# Simulation Parameters

This document explains the main configurable parameters in the shear-wave
simulation framework.

The emphasis is practical: what each parameter controls, its units, its physical
meaning, its numerical consequences, and when it should be changed carefully.

## 1. Top-level parameters

### `schema_version`

```json
"schema_version": "3.0"
```

Defines the configuration schema expected by the current framework.

Do not change this value manually unless the codebase has introduced a new
schema version.

### `dimension`

```json
"dimension": 2
```

or

```json
"dimension": 3
```

Controls whether the simulation uses the 2D or 3D solver path.

Do not convert a configuration from 2D to 3D by changing only this field. The
grid, geometry, source, sensor, solver, and validation sections differ between
dimensions.

### `scenario`

```json
"scenario": "homogeneous_directional_3d"
```

Identifies the physical and validation case.

The scenario may determine which builder, diagnostics, and post-processing
logic are used. It should not be renamed arbitrarily.

### `seed`

```json
"seed": 1001
```

Controls deterministic random choices supported by the configuration, such as
source phases or generated angular-bank geometry.

Use the same seed for reproducibility. Change it deliberately when studying
realization variability.

## 2. Grid parameters

## 2.1 Number of grid points

### 2D

```json
"grid": {
  "Nx": 96,
  "Nz": 96
}
```

### 3D

```json
"grid": {
  "Nx": 48,
  "Ny": 32,
  "Nz": 48
}
```

These values control the number of grid points along each public coordinate:

```text
x = lateral
y = elevational or out-of-plane
z = axial or depth
```

Increasing the number of points increases the physical field of view when
spacing remains fixed, and increases memory use and runtime.

In 3D, computational cost grows rapidly because the number of voxels is
approximately:

```text
Nx * Ny * Nz
```

## 2.2 Spatial spacing

### 2D

```json
"grid": {
  "dx_m": 0.0005,
  "dz_m": 0.0005
}
```

### 3D

```json
"grid": {
  "dx_m": 0.0005,
  "dy_m": 0.0005,
  "dz_m": 0.0005
}
```

Units are meters.

The spacing controls:

- spatial resolution;
- points per wavelength;
- physical domain size;
- numerical dispersion;
- memory use;
- simulation runtime.

Smaller spacing improves sampling but increases cost.

## 2.3 Physical extent

The approximate physical dimensions are:

```text
Lx = (Nx - 1) * dx
Ly = (Ny - 1) * dy
Lz = (Nz - 1) * dz
```

The solver also adds PML according to the selected PML settings.

## 2.4 CFL

```json
"grid": {
  "cfl": 0.20
}
```

The Courant-Friedrichs-Lewy number controls the time-step size.

Smaller CFL values generally improve temporal stability and accuracy but
increase the number of time steps.

Do not increase CFL casually.

## 2.5 Minimum shear points per wavelength

```json
"grid": {
  "minimum_shear_ppw": 8
}
```

Defines the minimum acceptable shear-wave spatial sampling used by validation.

For shear waves:

```text
lambda_s = cs / f0
PPW = lambda_s / dx
```

For anisotropic spacing, evaluate PPW along every relevant axis.

## 3. Medium parameters

## 3.1 Shear-wave speed

```json
"medium": {
  "cs_m_s": 2.0
}
```

Unit:

```text
m/s
```

Physical meaning:

```text
Shear-wave propagation speed in the homogeneous background.
```

Numerical consequences:

- changes the shear wavelength;
- changes PPW;
- changes expected propagation time;
- affects REQ window size;
- can affect validation thresholds and duration.

This parameter was dry-run verified at 2.0 and 2.5 m/s in both 2D and 3D.

## 3.2 Density

```json
"medium": {
  "rho_kg_m3": 1000
}
```

Unit:

```text
kg/m^3
```

Density affects impedance, reflection, transmission, and dynamic response.

In heterogeneous simulations, density can differ between materials.

## 3.3 Compressional-speed mode

```json
"medium": {
  "cp_mode": "reduced"
}
```

The current development configurations commonly use a reduced compressional
speed to reduce numerical cost.

## 3.4 Reduced compressional-speed factor

```json
"medium": {
  "reduced_cp_factor": 10
}
```

With reduced mode:

```text
cp = reduced_cp_factor * cs
```

This is a computational approximation, not a biological tissue value.

Changing this factor affects:

- the fastest wave in the simulation;
- time-step requirements;
- compressional contamination;
- runtime;
- physical interpretation.

## 3.5 Physical compressional speed

```json
"medium": {
  "physical_cp_m_s": 1540
}
```

This stores the nominal physical compressional speed used when the selected
compressional-speed mode requires it.

Do not assume it is active when `cp_mode` is set to `reduced`.

## 4. Geometry parameters

## 4.1 Background material ID

```json
"geometry": {
  "background_material_id": 1
}
```

Identifies the material filling the domain before objects are applied.

## 4.2 Geometry objects

```json
"geometry": {
  "objects": []
}
```

The object list may contain spheres or finite cylinders.

Typical object fields include:

```text
type
name
center_m_xyz
axis_xyz
radius_m
length_m
material_id
cs_m_s
cp_m_s
rho_kg_m3
```

Not every field is used by every object type.

## 4.3 Object center

```json
"center_m_xyz": [0.0, 0.0, 0.0]
```

Unit:

```text
m
```

Defines the object center in public `[x, y, z]` coordinates.

## 4.4 Cylinder axis

```json
"axis_xyz": [0, 1, 0]
```

Defines the cylinder orientation.

The axis does not need to align with the grid axes, but it should be a valid
nonzero vector.

## 4.5 Radius

```json
"radius_m": 0.006
```

Unit:

```text
m
```

Controls sphere radius or cylinder radius.

## 4.6 Length

```json
"length_m": 0.020
```

Unit:

```text
m
```

Used by finite cylinders.

## 4.7 Bilayer

A bilayer is defined by a plane:

```text
interface point
normal vector
negative-side material
positive-side material
```

The plane normal controls orientation.

## 4.8 Boundary clearance

```json
"geometry": {
  "minimum_boundary_clearance_m": 0.002
}
```

Prevents objects from approaching the boundary too closely.

## 4.9 Require objects inside sensor ROI

```json
"geometry": {
  "require_objects_inside_sensor_roi": true
}
```

When enabled, geometry validation rejects objects that are not fully compatible
with the selected sensor region.

## 5. Source parameters

## 5.1 Source layout

```json
"source": {
  "layout": "single_contact"
}
```

Typical layouts include:

```text
single_contact
multi-contact source bank
generated angular bank
```

Start from a verified configuration when changing layouts.

## 5.2 Source side

```json
"source": {
  "side": "left"
}
```

Defines the boundary face used by a single-contact source.

For a left-face source, the main propagation direction is typically toward
positive x.

## 5.3 Excitation frequency

```json
"source": {
  "f0_hz": 500
}
```

Unit:

```text
Hz
```

Physical consequences:

- changes shear wavelength;
- changes cycle duration;
- changes attenuation behavior;
- changes expected wavenumber.

Numerical consequences:

- changes PPW;
- changes time-step count per cycle;
- changes required simulation duration;
- can affect steady-state convergence.

This parameter was dry-run verified at 500 and 400 Hz in both 2D and 3D.

## 5.4 Velocity amplitude

```json
"source": {
  "velocity_amplitude_m_s": 1e-6
}
```

Unit:

```text
m/s
```

Controls prescribed particle-velocity amplitude at the source.

In a linear simulation, scaling the drive should scale field amplitude without
changing wave speed.

Very small amplitudes may approach numerical precision limits. Very large
amplitudes may no longer represent the intended linear regime.

## 5.5 Contact model

2D:

```json
"contact_model": "finite_segment"
```

3D:

```json
"contact_model": "finite_disk"
```

These represent nonzero source regions rather than mathematical point sources.

## 5.6 Contact radius

```json
"source": {
  "contact_radius_m": 0.001
}
```

Unit:

```text
m
```

In 2D, this controls the half-extent of the segment.

In 3D, this controls the disk radius.

The realized contact is discretized on the grid and may not match the requested
size exactly.

## 5.7 Contact profile

```json
"source": {
  "contact_profile": "uniform"
}
```

Controls how source amplitude is distributed over the contact nodes.

## 5.8 Contact sampling

```json
"source": {
  "contact_sampling": "sparse_patch"
}
```

Controls which grid nodes inside the finite contact are driven.

This parameter should not be changed without checking contact stability and
source-spectrum diagnostics.

## 5.9 Contact node spacing

```json
"source": {
  "contact_node_spacing_points": 2
}
```

Unit:

```text
grid points
```

Controls spacing between driven nodes in a sparsely sampled contact.

## 5.10 Ramp cycles

```json
"source": {
  "ramp_cycles": 3
}
```

Controls how gradually the harmonic source reaches full amplitude.

A ramp reduces startup transients.

## 5.11 Source phase

```json
"source": {
  "phase_rad": 0
}
```

Unit:

```text
radians
```

For source banks, relative phase strongly affects interference and wavefield
structure.

## 5.12 Source mode

```json
"source": {
  "mode": "dirichlet"
}
```

Indicates that particle velocity is prescribed directly at source nodes.

This is a numerical boundary-driving model, not a full mechanical actuator
model.

## 5.13 Polarization

```json
"source": {
  "polarization_xyz": [0, 0, 1]
}
```

Defines the direction of prescribed particle motion.

For shear-dominant excitation, polarization should be transverse to the intended
propagation direction.

## 5.14 Target direction

```json
"source": {
  "target_direction_xyz": [1, 0, 0]
}
```

Defines the intended principal propagation direction.

For a directional shear source:

```text
polarization · target_direction ≈ 0
```

## 5.15 Vibrator count

```json
"source": {
  "vibrator_count": 32
}
```

Defines the number of source contacts in a source bank.

Increasing source count does not automatically create an ideal diffuse field.

## 5.16 Source-bank phase policy

```json
"source": {
  "phase_policy": "random_uniform"
}
```

Controls how source phases are assigned.

Random phases help reduce coherent directional interference, but the realized
field still depends on geometry and source count.

## 5.17 Amplitude policy

```json
"source": {
  "amplitude_policy": "equal_total_rms"
}
```

Controls how total drive power is distributed as the number of sources changes.

This is important when comparing N8, N32, and N128 fields fairly.

## 5.18 Polarization policy

```json
"source": {
  "polarization_policy": "project_axial_transverse"
}
```

Controls how each source polarization is made transverse to its target
direction.

## 5.19 N and P parameters

Examples:

```text
N8 P2
N32 P8
N128 P8
```

`N` is the total number of sources.

`P` is the configured number of explicitly in-plane contributors used by the
source-bank design.

These names describe source construction, not guaranteed final-field
diffusivity.

## 6. Time parameters

## 6.1 Settling cycles

```json
"time": {
  "settling_cycles": 2
}
```

Cycles simulated before the harmonic analysis interval.

The purpose is to allow startup transients to decay.

## 6.2 Analysis cycles

```json
"time": {
  "analysis_cycles": 8
}
```

Cycles used to estimate the harmonic field.

More cycles increase runtime but can improve frequency estimation and
steady-state assessment.

## 6.3 End time

```json
"time": {
  "end_time_s": null
}
```

When supported, an empty or null value allows automatic selection.

An explicit value is in seconds.

The total duration must be long enough for:

- source ramp;
- propagation to the region of interest;
- transient decay;
- harmonic analysis.

## 7. Sensor parameters

## 7.1 Source buffer

```json
"sensor": {
  "source_buffer_m": 0.004
}
```

Excludes the region immediately adjacent to the source from the analysis ROI.

## 7.2 Boundary margin

```json
"sensor": {
  "boundary_margin_m": 0.002
}
```

Keeps the analyzed field away from boundaries and PML-related effects.

## 7.3 Save full volume

```json
"sensor": {
  "save_full_volume": true
}
```

Used in 3D to determine whether the full sensor volume is retained.

Full-volume saving increases memory and output size.

## 8. Solver parameters

## 8.1 Backend

```json
"solver": {
  "backend": "cpu"
}
```

Selects the configured solver backend.

Use only backends supported by the current installation.

## 8.2 Data cast

```json
"solver": {
  "data_cast": "single"
}
```

Controls numerical storage precision.

Single precision reduces memory use and is used by the current verified
configurations.

## 8.3 PML inside

```json
"solver": {
  "pml_inside": false
}
```

Controls whether the PML is placed inside or outside the requested physical
grid.

Changing this affects domain interpretation.

## 8.4 PML size

2D:

```json
"pml_size_points": 20
```

3D:

```json
"pml_size_points": [12, 12, 12]
```

Unit:

```text
grid points
```

Larger PML regions reduce boundary reflections but increase computational cost.

## 8.5 PML alpha

```json
"solver": {
  "pml_alpha": 2
}
```

Controls PML absorption strength.

Do not change it without validating boundary behavior.

## 8.6 Plot simulation

```json
"solver": {
  "plot_simulation": false
}
```

Enables or disables live solver plotting.

Live plotting is useful for debugging but can slow execution.

## 8.7 k-Wave path

```json
"solver": {
  "kwave_path": ""
}
```

An empty value uses the configured or discoverable installation path.

The framework also supports selecting the MATLAB executable through the
`MATLAB_BIN` environment variable.

## 9. Execution parameters

## 9.1 Maximum memory

```json
"execution": {
  "maximum_memory_bytes": 8000000000
}
```

Defines the maximum allowed estimated memory for configured 3D execution.

## 9.2 Fail on memory limit

```json
"execution": {
  "fail_on_memory_limit": true
}
```

When enabled, preflight stops the run if the estimated memory exceeds the
configured limit.

## 10. Harmonic-analysis parameters

## 10.1 Harmonic method

```json
"analysis": {
  "harmonic_method": "least_squares"
}
```

Controls how the complex field at `f0` is estimated from time-domain data.

## 10.2 Temporal window

```json
"analysis": {
  "temporal_window": "none"
}
```

Controls temporal weighting during harmonic extraction.

## 10.3 Remove mean

```json
"analysis": {
  "remove_mean": true
}
```

Removes the temporal mean before estimating the harmonic component.

## 11. REQ validation parameters

## 11.1 Quantity

```json
"req_validation": {
  "quantity": "displacement"
}
```

Identifies the exported quantity used by external REQ processing.

## 11.2 Initial SWS guess

```json
"req_validation": {
  "cs_guess_m_s": 3.0
}
```

Unit:

```text
m/s
```

Used to determine operational REQ window dimensions.

It is not ground truth and is not the final REQ estimate.

## 11.3 Window size in wavelengths

```json
"req_validation": {
  "window_wavelengths": 2.0
}
```

Controls the REQ analysis-window size relative to the guessed wavelength.

## 11.4 Minimum placements per axis

```json
"req_validation": {
  "minimum_placements_per_axis": 5
}
```

Ensures that the exported field is large enough for meaningful sliding-window
placement.

## 12. Output parameters

## 12.1 Output enabled

```json
"output": {
  "enabled": true
}
```

Controls whether a configured run creates a run directory.

## 12.2 Output directory

```json
"output": {
  "directory": "outputs"
}
```

Defines the parent output directory.

## 12.3 Run name

```json
"output": {
  "run_name": "my_simulation"
}
```

Defines the descriptive part of the run-directory name.

## 12.4 Append timestamp

```json
"output": {
  "append_timestamp": true
}
```

Adds a timestamp to avoid collisions and preserve run history.

## 12.5 Overwrite

```json
"output": {
  "overwrite": false
}
```

Prevents accidental replacement of existing results.

## 12.6 Saved products

Typical fields:

```json
"save_result": true,
"save_summary": true,
"save_config_mat": true,
"save_config_json": true,
"save_time_series": false,
"save_req_validation_sample": false,
"save_figures": true,
"save_matlab_figures": true
```

Time-series and 3D full-volume outputs can be large.

## 13. Diagnostics parameters

Diagnostics thresholds are part of the validation contract.

Examples include:

```text
maximum P/S energy ratio
maximum steady-state change
maximum speed relative error
minimum source fundamental fraction
maximum geometry error
minimum angular entropy
maximum directional bias
```

These thresholds are case-specific.

Do not weaken validation thresholds only to make a failing run appear valid.
Investigate the physical or numerical cause first.

## 14. Safe first edits

The safest first edits for a new user are:

```text
medium.cs_m_s
source.f0_hz
output.run_name
output.save_figures
output.save_matlab_figures
seed
```

Every change should still be followed by a dry run.

## 15. Parameters that should be changed carefully

These require additional numerical or physical understanding:

```text
grid spacing
grid dimensions
CFL
PML settings
compressional-speed mode
source contact sampling
source polarization
source-bank generation constraints
time duration
memory limits
validation thresholds
```

## 16. Verified editing workflow

The following parameter changes were dry-run verified in both 2D and 3D:

```text
medium.cs_m_s: 2.0 → 2.5 m/s
source.f0_hz: 500 → 400 Hz
output.run_name: documentation test name
```

The correct workflow is:

```text
copy configuration
→ edit one parameter group
→ run dry run
→ inspect resolved summary
→ execute solver
→ inspect validation report
```
