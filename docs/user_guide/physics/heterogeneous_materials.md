# Heterogeneous Materials

This document explains how heterogeneous materials are represented in the 3D shear-wave simulation framework.

The current geometry system supports homogeneous backgrounds, spheres, finite cylinders, bilayers, and combined geometries.

## 1. What is a heterogeneous simulation?

A heterogeneous simulation contains more than one material region. Each region may have different shear-wave speed, compressional-wave speed, density, and material ID.

Spatial variation in these properties can change wavelength, impedance, reflection, transmission, refraction, mode conversion, interference, and local phase gradients.

## 2. Background material

The background fills the domain before any heterogeneous object is applied.

```json
"medium": {
  "cs_m_s": 2.0,
  "rho_kg_m3": 1000,
  "cp_mode": "reduced",
  "reduced_cp_factor": 10
}
```

In 3D, the background material ID is stored in:

```json
"geometry": {
  "background_material_id": 1
}
```

## 3. Material properties

A material may define:

```text
material_id
cs_m_s
cp_m_s
rho_kg_m3
```

`cs_m_s` is shear-wave speed in m/s.

`cp_m_s` is compressional-wave speed in m/s.

`rho_kg_m3` is density in kg/m^3.

`material_id` is an integer label used to identify truth regions exactly.

Material IDs are useful for classifying windows as background-pure, inclusion-pure, or mixed.

## 4. Material maps

The geometry builder resolves requested geometry into volumetric maps such as:

```text
cs_map
cp_map
rho_map
material_id_map
```

Public 3D volumes use:

```text
[Nz, Ny, Nx]
```

The saved maps represent the discretized geometry actually used by the solver.

## 5. Continuous versus voxelized geometry

Geometry is requested in physical units, but the solver uses voxels.

Therefore:

```text
requested geometry != exact voxelized geometry in general
```

Differences may appear in radius, volume, boundary position, cylinder end caps, interface position, and object orientation.

When geometry accuracy matters, inspect the resolved maps rather than relying only on requested dimensions.

## 6. Sphere geometry

A sphere is defined by center, radius, material properties, and material ID.

Representative configuration:

```text
configs/three_d/heterogeneous_sphere_3d.json
```

Typical object:

```json
{
  "type": "sphere",
  "name": "inclusion",
  "center_m_xyz": [0.0, 0.0, 0.0],
  "radius_m": 0.006,
  "material_id": 2,
  "cs_m_s": 3.0,
  "rho_kg_m3": 1000
}
```

A point belongs to the ideal sphere when:

```text
||r - r_center|| <= radius
```

## 7. Finite cylinder geometry

A finite cylinder is defined by center, axis, radius, length, material properties, and material ID.

Representative configuration:

```text
configs/three_d/heterogeneous_cylinder_3d.json
```

Typical object:

```json
{
  "type": "cylinder",
  "name": "cylindrical_inclusion",
  "center_m_xyz": [0.0, 0.0, 0.0],
  "axis_xyz": [0.0, 1.0, 0.0],
  "radius_m": 0.004,
  "length_m": 0.016,
  "material_id": 2,
  "cs_m_s": 3.0,
  "rho_kg_m3": 1000
}
```

The axis may be arbitrarily oriented. A point belongs to the finite cylinder when its radial distance to the axis is smaller than the radius and its axial distance from the center is smaller than half the length.

## 8. Bilayer geometry

A bilayer divides the domain with a plane.

Representative configuration:

```text
configs/three_d/heterogeneous_bilayer_3d.json
```

The plane is defined by:

```text
interface point
normal vector
negative-side material
positive-side material
```

For point `r`, interface point `r0`, and normal `n`:

```text
s = (r - r0) dot n
```

Then:

```text
s < 0  -> negative-side material
s >= 0 -> positive-side material
```

The bilayer is not restricted to axis-aligned planes.

## 9. Combined geometries

The framework can combine:

```text
background
bilayer
finite cylinders
spheres
```

Representative configuration:

```text
configs/three_d/heterogeneous_combined_3d.json
```

Combined cases are useful for testing overlap, precedence, arbitrary orientation, material-map consistency, and complex wavefields.

## 10. Geometry precedence

The intended precedence is:

```text
background
-> bilayer
-> cylinders
-> spheres
```

Later geometry types overwrite earlier assignments where they overlap.

Examples:

```text
sphere inside bilayer:
sphere material wins

cylinder crossing bilayer:
cylinder material wins

sphere overlapping cylinder:
sphere material wins
```

This order is part of the geometry contract.

## 11. Overlapping objects

When objects overlap, final material assignment depends on precedence and object application order.

For reproducibility, preserve:

```text
requested object list
object order
resolved configuration
material ID map
geometry precedence
```

## 12. Boundary clearance

```json
"minimum_boundary_clearance_m": 0.002
```

This prevents objects from approaching the boundary too closely and helps avoid object truncation, PML intersection, source overlap, and boundary-dominated analysis.

## 13. Sensor-ROI requirement

```json
"require_objects_inside_sensor_roi": true
```

When enabled, preflight verifies that configured objects are compatible with the selected sensor region.

An object can be valid inside the numerical domain but still be only partially present in the saved analysis region.

## 14. Wave behavior at interfaces

At a material interface, an incident field can produce reflected and transmitted components.

The exact response depends on wave type, incidence angle, polarization, shear-wave speed, compressional-wave speed, density, interface orientation, and source geometry.

For oblique incidence, refraction and mode conversion may also occur.

Therefore local propagation direction inside a heterogeneous region may differ from the original source direction.

## 15. Wavelength contrast

At fixed frequency:

```text
lambda_s = cs / f0
```

Example at 500 Hz:

```text
background cs = 2 m/s
lambda_background = 4 mm

inclusion cs = 3 m/s
lambda_inclusion = 6 mm
```

This difference is the basis for local SWS estimation from wavenumber.

## 16. Reflection and impedance contrast

A shear-speed contrast can produce reflection even when density is unchanged.

A density contrast introduces additional impedance mismatch.

The elastic solver generates reflections from the spatially varying material maps rather than from manually inserted reflection coefficients.

## 17. Reduced compressional speed

Many development cases use:

```text
cp = reduced_cp_factor * cs
```

rather than a fully physiological soft-tissue compressional speed.

Purpose:

```text
larger allowable time step
fewer time steps
lower computational cost
```

Limitations:

```text
nonphysiological P/S speed ratio
altered compressional transit time
potentially altered interface conversion behavior
```

This approximation should be stated explicitly in scientific reporting.

## 18. Density choices

Equal background and inclusion density isolates much of the contrast to wave speed.

Different densities introduce additional interface physics.

For method validation, equal-density inclusions can simplify interpretation. For realism studies, density contrast may be included when justified.

## 19. Attenuation

Geometry and attenuation are separate model layers.

A heterogeneous geometry does not automatically imply heterogeneous attenuation.

When attenuation is enabled, its material assignment and frequency dependence must be documented independently.

## 20. Truth-region classification

Using the material ID map, a sliding window can be classified as:

```text
background-pure
inclusion-pure
mixed
```

A pure window contains only one material ID.

A mixed window intersects an interface or contains more than one material.

Mixed windows do not have one unique local ground-truth SWS.

## 21. Mixed-window interpretation

A mixed-window estimate can depend on material fraction, wavelength, interface orientation, source direction, reflection, spectral leakage, window function, and estimator design.

It should not automatically be labeled an error relative to either material value.

## 22. Inclusion size and analysis-window size

To evaluate inclusion-pure performance, the inclusion must be large enough relative to the analysis window.

To evaluate background-pure performance, the surrounding background must also be wide enough.

A displayed map can clearly show both regions while still producing no pure background windows.

Geometry design must therefore consider:

```text
physical object size
analysis-window size
```

## 23. Large spherical inclusion example

A large sphere with:

```text
background cs = 2 m/s
inclusion cs = 3 m/s
diameter = 24 mm
```

was used for external heterogeneous REQ validation.

The exported central-plane sample produced inclusion-pure and mixed placements, but no background-pure placements for the selected REQ window.

Therefore the case supported inclusion accuracy analysis, but not complete background accuracy or contrast-recovery claims.

## 24. Central-plane exports

A 3D simulation may export a central 2D plane for external analysis.

For a sphere, the central plane gives the largest circular cross-section.

For a tilted cylinder or bilayer, the observed shape depends strongly on orientation.

The exported field and exported truth maps must correspond to the same plane and orientation.

## 25. Coordinate conventions

Public coordinates:

```text
x = lateral
y = elevational / out-of-plane
z = axial / depth
```

Public 3D arrays:

```text
[Nz, Ny, Nx]
```

Public central x-z planes:

```text
[Nz, Nx]
```

Geometry parameters are always interpreted in the public coordinate system.

## 26. Geometry validation

Heterogeneous geometry validation should include:

```text
finite material maps
valid material IDs
object containment
boundary clearance
expected object volume
expected exported-plane area
precedence correctness
repeatability
zero-contrast consistency
orientation correctness
field-truth alignment
```

## 27. Zero-contrast test

A useful geometry test assigns an object the same properties as the background.

Expected result:

```text
geometry mask still exists
but physical wavefield closely matches homogeneous case
```

This helps separate geometry-mask errors from actual material-contrast effects.

## 28. Geometry-resolution error

Voxelized area or volume can differ from the ideal analytical value.

The relative error depends on object size, grid spacing, orientation, shape, and dimensionality.

Small or oblique objects generally show larger discretization error.

## 29. What the framework represents

The heterogeneous-material system represents:

```text
spatially varying elastic properties
finite 3D objects
arbitrary cylinder axes
arbitrarily oriented bilayers
overlap with defined precedence
material truth maps
wave propagation through interfaces
```

## 30. What it does not automatically represent

A heterogeneous geometry does not automatically include:

```text
viscoelastic dispersion
nonlinear elasticity
poroelasticity
anisotropy
frequency-dependent material properties
heterogeneous attenuation
realistic ultrasound readout
experimental noise
imperfect actuator coupling
```

These require additional modeling layers.

## 31. Recommended reporting

For each heterogeneous simulation, report:

```text
background cs, cp, and density
object cs, cp, and density
geometry type
center and orientation
radius and length
material IDs
grid spacing
frequency
source regime
geometry precedence
attenuation model
exported plane or volume
analysis-window size
```

Also preserve the resolved configuration and truth maps.

## 32. Recommended interpretation

Use wording such as:

> A voxelized heterogeneous elastic medium containing a finite spherical, cylindrical, bilayer, or combined material geometry.

Avoid wording such as:

> A complete tissue model.

unless the missing material physics and measurement layers have also been justified.

## 33. Summary

The workflow is:

```text
define homogeneous background
-> define bilayer if enabled
-> define cylinders
-> define spheres
-> apply precedence
-> resolve voxelized material maps
-> validate placement and geometry
-> run elastic solver
-> save truth maps with the field
```

The resolved material maps, not only the requested continuous geometry, define the actual simulation.
