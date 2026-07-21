# Three-dimensional wavefield regimes

## Purpose

This document defines the planned continuum from directional to diffuse
three-dimensional shear-wave fields and distinguishes the full 3D field from
its two-dimensional projection onto an ultrasound acquisition plane.

The acquisition plane is an `x-z` plane at a resolved elevational coordinate
`y = y_acquisition`. The simulation remains fully three-dimensional, while the
REQ validation sample contains the field measured on this plane.

## Diffusivity is not defined by source count alone

Increasing the number of sources generally increases field complexity, but
source count alone does not define a diffuse field.

The effective wavefield geometry also depends on:

- angular support of the nominal propagation directions;
- spatial distribution of the source contacts;
- number of sources contributing within the acquisition plane;
- number of out-of-plane contributors;
- source phases;
- source polarizations;
- relative source amplitudes.

A large number of sources concentrated on one boundary face can still produce
a field with a strong preferred direction. A smaller set distributed across
multiple faces can produce broader three-dimensional angular support.

## Canonical field families

| Family | Typical source count | Angular support | Relation to acquisition plane |
|---|---:|---|---|
| Directional 2D | 1 or few | Narrow and entirely in-plane | All propagation is represented in the plane |
| Diffuse 2D | Many | Broad around the 2D perimeter | All sources and wavevectors remain in-plane |
| Directional 3D | 1 | One dominant 3D direction | The field is observed through its `x-z` projection |
| Partially diffuse 3D | Moderate, initially 4–32 | Multiple in-plane and out-of-plane directions | A prescribed subset contributes directly in or through the plane |
| Diffuse 3D | Many, initially 64–256 | Broad approximately spherical support | No single direction or plane dominates |

These source-count ranges are design candidates, not universal physical
thresholds. The final classification must also be supported by measured angular
metrics.

## Proposed naming convention

Future configurations should encode both the total source count and the
acquisition-plane contribution:

```text
directional_3d_N1
partial_3d_N8_P2
partial_3d_N16_P4
diffuse_3d_N128_P8

Here:

- `N` is the total number of source contacts;
- `P` is the prescribed number of nominal in-plane contributors.

The exact meaning of `P` must be stored in metadata. It may represent:

- source centers inside an acquisition-plane slab;
- nominal source rays intersecting the acquisition ROI;
- or both.

## External-source geometry

The physical model uses external contacts distributed around the boundary of
the simulated material volume.

Sources should not be placed inside the material unless an internal actuator
model is explicitly intended.

For the future multi-face implementation:

1. Generate nominal propagation directions around the unit sphere.
2. Trace the opposite ray from the domain center to the rectangular boundary.
3. Place the source contact at the boundary intersection.
4. Direct the nominal propagation vector toward the domain interior.
5. Reserve a prescribed subset whose source centers or nominal rays intersect
   the acquisition plane.
6. Place the remaining sources at nonzero elevational offsets to generate
   out-of-plane propagation.

A deterministic spherical sequence, such as a Fibonacci-sphere construction,
is preferred over independent random directions. It provides reproducible and
progressively broader angular coverage as `N` increases.

## Controlled quantities across source counts

To isolate the effect of wavefield geometry, comparisons across values of `N`
should preserve:

- total prescribed node-weighted RMS-squared velocity drive;
- temporal frequency;
- contact radius;
- sparse-contact discretization;
- material properties;
- acquisition plane;
- sensor ROI;
- simulation duration;
- random-seed policy.

The current amplitude policy,

```text
equal_total_rms
```

keeps the total prescribed drive equal to the single-contact reference. This
should remain the default for directional-to-diffuse comparisons.

Random phases should use a deterministic local random-number stream so that:

- the same seed reproduces the same phases;
- source construction does not alter MATLAB's global random state;
- multiple seeds can measure phase-realization variability.

## Polarization policy

The current policy is:

```text
project_axial_transverse
```

It projects the axial unit vector onto the plane transverse to each nominal
propagation direction.

This preserves a strong axial component relevant to ultrasound displacement
measurements while maintaining transverse source motion.

This policy introduces a controlled axial preference and should not be
described as polarization-isotropic. A future diffuse-field study may compare
it with uniformly distributed transverse polarizations.

## Required metadata

Every resolved three-dimensional source bank should store:

```text
field_family
bank_name
source_count
in_plane_source_count
out_of_plane_source_count
plane_intersecting_ray_count
source_faces
center_m_xyz
nominal_propagation_xyz
polarization_xyz
phase_rad
velocity_amplitude_m_s
contact_node_count
phase_policy
amplitude_policy
polarization_policy
seed
```

## Required validation metrics

Source-bank validation should include:

- finite harmonic fields;
- low longitudinal P/S leakage;
- non-overlapping contacts;
- unit propagation and polarization vectors;
- transverse source polarization;
- deterministic non-identical phases;
- total-drive normalization;
- source count;
- acquisition-plane contributor count;
- angular-support coverage;
- normalized spherical angular entropy;
- magnitude of the mean propagation-direction vector;
- REQ sample readiness.

For unit propagation vectors `d_i`, the directional resultant is:

```text
R = norm(mean(d_i))
```

Its interpretation is:

- `R` near one indicates a strongly directional distribution;
- smaller `R` indicates broader directional balance.

This measure should be combined with angular entropy rather than used alone.

## Status of the current eight-source bank

The implemented `partial_diffuse_8` bank is a validated development prototype:

- eight non-overlapping finite contacts;
- deterministic random phases;
- transverse source polarizations;
- normalized total prescribed drive;
- full 3D propagation;
- successful central `x-z` REQ export.

However, all eight contacts currently lie on the same left `x` face and point
approximately toward the domain center. The field therefore retains a dominant
positive-`x` orientation.

It is correctly treated as a multi-source, partially distributed 3D field, but
it is not yet the canonical multi-face partially diffuse geometry. It must not
be described as a fully diffuse 3D field.

## Planned progression

The future source-bank study should evaluate:

```text
N = 1, 4, 8, 16, 32, 64, 128
```

with controlled total drive and progressively broader multi-face angular
support.

The initial scientific comparisons should include:

1. directional 3D with `N=1`;
2. partially diffuse 3D with moderate `N` and explicit in-plane contributors;
3. diffuse 3D with large `N` and approximately spherical support;
4. multiple phase seeds for every non-directional configuration.

The transition from partially diffuse to diffuse should be determined from the
measured angular distribution, not assigned solely from `N`.
