# Finite-Contact Sources

This document explains the physical interpretation and numerical implementation
of finite-contact shear-wave sources in the simulation framework.

The goal is to clarify what the source represents, how it moves, why it
preferentially generates shear motion, and which aspects are numerical
approximations rather than complete actuator physics.

## 1. What is a finite-contact source?

A finite-contact source applies prescribed particle velocity over a nonzero
region of the simulation boundary.

The current framework uses:

```text
2D: finite segment
3D: finite disk
```

This differs from an ideal point source, which acts at only one numerical node.

A finite contact is intended to approximate the footprint of a small external
actuator coupled to the material. It represents the region over which motion is
imposed, but it does not model every detail of the actuator itself.

In particular, the current source model does not explicitly simulate:

- actuator mass;
- actuator elasticity;
- a coupling gel or adhesive layer;
- contact pressure;
- frictional slip;
- nonlinear contact;
- a force-controlled electromechanical driver.

It is therefore best interpreted as a prescribed boundary-motion model.

## 2. Source geometry in 2D

In 2D, the source contact is a finite segment located on one side of the
computational domain.

The relevant configuration fields include:

```json
"source": {
  "side": "left",
  "contact_model": "finite_segment",
  "contact_radius_m": 0.001
}
```

Although the parameter is named `contact_radius_m`, in 2D it acts as the
half-extent of the segment.

For example:

```text
contact_radius_m = 1 mm
```

corresponds approximately to a segment with total requested extent:

```text
2 mm
```

The exact realized size depends on the grid spacing and selected source-node
sampling.

## 3. Source geometry in 3D

In 3D, the source contact is a finite disk placed on a boundary face.

Typical fields are:

```json
"source": {
  "side": "left",
  "contact_model": "finite_disk",
  "contact_radius_m": 0.001
}
```

The disk lies in the plane of the selected boundary face.

For a left or right x-face, the disk is represented in the local y-z plane.

For other faces, the same geometric idea is mapped to the corresponding local
face coordinates.

The disk is discretized onto grid nodes, so the realized contact area is an
approximation to the requested continuous disk.

## 4. How does the source move?

The source prescribes particle velocity at the selected contact nodes.

A typical 3D source block is:

```json
"source": {
  "velocity_amplitude_m_s": 0.000001,
  "f0_hz": 500,
  "phase_rad": 0,
  "ramp_cycles": 3,
  "mode": "dirichlet",
  "polarization_xyz": [0, 0, 1]
}
```

Ignoring the startup ramp, the intended harmonic velocity has the form:

```text
v(t) = A cos(2 pi f0 t + phi)
```

where:

```text
A   = velocity amplitude
f0  = excitation frequency
phi = source phase
```

The polarization vector determines the direction of this prescribed motion.

For:

```text
polarization_xyz = [0, 0, 1]
```

the contact oscillates in the positive and negative z direction.

It does not continuously move into the material. It oscillates around its
equilibrium position.

## 5. Dirichlet source interpretation

The current source mode is:

```json
"mode": "dirichlet"
```

A Dirichlet velocity source directly prescribes particle velocity at the driven
nodes.

Conceptually:

```text
the selected nodes are forced to follow the requested velocity waveform
```

This is different from applying a known force or stress and allowing the local
velocity to emerge from the material response.

Advantages:

- direct control of source frequency;
- direct control of velocity amplitude;
- reproducible source waveform;
- convenient comparison between source configurations;
- robust construction of directional and multi-source fields.

Limitations:

- the reaction force is not prescribed;
- mechanical impedance matching to a real actuator is not explicitly modeled;
- closely spaced prescribed contacts can interact numerically;
- source-region behavior is not equivalent to a complete experimental contact.

## 6. Why does the source preferentially generate shear waves?

Shear waves have particle motion predominantly perpendicular to their
propagation direction.

For the reference directional 3D case:

```text
source face:          left x-face
target direction:     +x
source polarization:  +z
```

The target direction and polarization are transverse:

```text
[1, 0, 0] dot [0, 0, 1] = 0
```

Therefore, the imposed motion is oriented to preferentially launch shear motion
traveling away from the left boundary.

The same principle applies in 2D. A source on the left boundary with axial
motion launches a field whose intended principal propagation is lateral while
particle motion is axial.

This does not imply that the field is perfectly shear-only.

Finite contacts, boundaries, heterogeneous interfaces, and numerical
discretization can also produce:

- compressional leakage;
- near-field components;
- mode conversion;
- reflected waves;
- geometrically complex motion.

For that reason, the framework evaluates compressional contamination rather
than assuming it is zero.

## 7. Target direction and polarization

The source may define:

```json
"target_direction_xyz": [1, 0, 0],
"polarization_xyz": [0, 0, 1]
```

The target direction describes the intended propagation direction.

The polarization describes the direction of imposed particle velocity.

For a shear-dominant source, these vectors should satisfy approximately:

```text
polarization dot target_direction = 0
```

For generated angular banks, the framework can derive transverse polarization
from the requested propagation direction according to the configured
polarization policy.

A transverse polarization is not unique in 3D. For any propagation direction,
there is a plane of possible transverse polarizations.

The selected policy determines which direction inside that plane is used.

## 8. Source contact sampling

A continuous contact must be represented using discrete grid nodes.

Typical settings include:

```json
"source": {
  "contact_sampling": "sparse_patch",
  "contact_node_spacing_points": 2,
  "contact_profile": "uniform"
}
```

### Sparse patch

A sparse patch drives selected nodes inside the requested finite contact rather
than every available node.

This helps control the behavior of prescribed Dirichlet contacts and reduces
problems associated with densely constrained adjacent nodes.

### Node spacing

```text
contact_node_spacing_points
```

controls the approximate separation between selected source nodes measured in
grid points.

The realized number of driven nodes depends on:

- contact size;
- grid spacing;
- boundary orientation;
- sampling policy;
- available face nodes.

### Uniform profile

```text
contact_profile = uniform
```

assigns equal profile weight to the selected contact nodes before any global
amplitude normalization.

Other profiles should only be documented after they are verified in executable
configurations.

## 9. Requested contact size versus realized contact

The requested contact is continuous, but the solver uses a discrete grid.

As a result:

```text
requested radius != exact realized radius in general
```

The difference depends on the ratio:

```text
contact size / grid spacing
```

A 1 mm-radius disk on a 0.5 mm grid has only a small number of grid samples
across its radius.

Increasing spatial resolution gives a more detailed geometric approximation but
increases computational cost.

The realized source mask and contact diagnostics should be inspected when
contact geometry is scientifically important.

## 10. Source ramp

A source that starts immediately at full amplitude creates a strong transient.

The framework therefore supports:

```json
"ramp_cycles": 3
```

During the ramp interval, the harmonic source is gradually increased toward its
full amplitude.

The ramp is intended to:

- reduce broadband startup content;
- reduce abrupt numerical forcing;
- improve harmonic-field extraction;
- help the field approach a stable periodic regime.

The ramp does not eliminate the need for settling cycles.

## 11. Ramp cycles versus settling cycles

These are related but distinct.

### Ramp cycles

```text
source.ramp_cycles
```

control how the source amplitude reaches its final value.

### Settling cycles

```text
time.settling_cycles
```

control how much late-time data is allowed before the analysis interval.

A typical sequence is:

```text
startup and ramp
→ wave propagation
→ transient decay
→ settling interval
→ harmonic analysis interval
```

The exact overlap between these stages depends on the resolved timing logic.

## 12. Source phase

For a single source:

```json
"phase_rad": 0
```

sets the temporal phase of its harmonic motion.

For multiple sources, relative phase strongly affects the interference pattern.

Examples:

```text
all sources in phase:
more coherent interference

random independent phases:
less globally coherent interference
```

Random phase alone does not guarantee a diffuse field. Source positions,
directions, polarizations, and angular support also matter.

## 13. Source amplitude

The configured source amplitude is particle velocity:

```json
"velocity_amplitude_m_s": 1e-6
```

Unit:

```text
m/s
```

In the intended linear regime:

```text
doubling source amplitude
→ approximately doubles field amplitude
→ should not change wave speed
```

This scaling should not be interpreted as a direct prediction of displacement
amplitude in a specific experiment unless actuator coupling and measurement
physics are also modeled.

## 14. Multiple finite contacts

A source bank contains multiple finite contacts.

Each contact can have its own:

- boundary face;
- center;
- target direction;
- polarization;
- phase;
- amplitude.

The total field is produced by the simultaneous action and interference of all
contacts.

A multi-contact field can be directional, partially three-dimensional, broadly
angular, or approximately diffuse depending on the realized configuration.

Source count alone is not sufficient to classify the field.

## 15. Total-drive normalization

When comparing source banks with different numbers of contacts, the total drive
should be controlled.

A typical amplitude policy is:

```text
equal_total_rms
```

Its purpose is to avoid automatically injecting more total drive merely because
a bank contains more sources.

Conceptually, the source amplitudes are scaled so that a total RMS drive measure
remains comparable between banks.

This makes comparisons such as N8 versus N32 more meaningful.

It does not guarantee equal energy inside every region of the material because
interference, propagation distance, boundary placement, and material geometry
also affect the field.

## 16. Boundary-face mapping in 3D

In 3D, a requested propagation direction is associated with a valid boundary
contact.

For a source intended to propagate inward, its contact must lie on a face from
which that direction enters the computational domain.

The source-bank implementation therefore resolves:

```text
target direction
→ compatible boundary face
→ finite contact center
→ discrete contact mask
→ transverse polarization
```

The realized direction can differ slightly from the requested direction because
of finite domain size, discrete placement, and contact geometry.

Generated angular banks include constraints intended to control this mapping
error.

## 17. Near field and far field

The region close to a finite contact contains complex near-field motion.

Near the source, the field may contain:

- strong spatial gradients;
- mixed wave components;
- contact-shape effects;
- evanescent or rapidly varying components;
- direct influence of the prescribed nodes.

The sensor configuration therefore includes a source buffer:

```json
"sensor": {
  "source_buffer_m": 0.004
}
```

This helps exclude the region immediately adjacent to the source from
validation and analysis.

A source buffer does not create a mathematically exact far field. It defines an
operational region where source-local effects are reduced.

## 18. Finite contact versus point contact

### Point contact

Advantages:

- simple;
- highly localized;
- low implementation complexity.

Limitations:

- grid-dependent localization;
- broad spatial-frequency content;
- limited resemblance to a finite actuator footprint.

### Finite contact

Advantages:

- represents nonzero actuator size;
- allows explicit contact geometry;
- supports face-based source banks;
- offers more realistic spatial forcing.

Limitations:

- requires discrete mask construction;
- can be sensitive to node spacing;
- creates source-shape-dependent near fields;
- remains an idealized prescribed-motion model.

## 19. Finite contact versus force source

A finite Dirichlet contact prescribes velocity.

A force or stress source would prescribe loading.

These are not equivalent experimental descriptions.

With prescribed velocity:

```text
motion is known
reaction force depends on the medium
```

With prescribed force:

```text
loading is known
motion depends on the medium
```

The current framework uses prescribed velocity because it provides stable,
reproducible control of harmonic source motion for wavefield validation.

## 20. What is physically represented?

The current finite-contact model represents:

- a finite actuator footprint;
- harmonic boundary motion;
- specified motion direction;
- specified frequency and phase;
- multi-actuator interference;
- wave propagation through homogeneous or heterogeneous elastic media.

## 21. What is not yet represented?

The current model does not by itself establish:

- exact experimental actuator force;
- exact contact impedance;
- nonlinear tissue response;
- actuator resonance;
- transducer electromechanics;
- slip or detachment;
- an acoustic ultrasound readout;
- a complete experimental noise model.

Those effects require additional modeling layers.

## 22. Recommended interpretation

Use this wording:

> A finite-contact boundary velocity source that approximates the footprint and
> prescribed harmonic motion of an external shear-wave actuator.

Avoid claiming:

> A complete mechanical simulation of the experimental shaker.

## 23. Validation considerations

A finite-contact source should be evaluated using:

- source-mask geometry;
- realized contact extent;
- source fundamental-frequency fraction;
- finite field checks;
- P/S energy ratio;
- steady-state change;
- directional or angular metrics;
- repeatability under a fixed seed;
- sensitivity to grid resolution when needed.

A solver completing successfully does not by itself validate the source model.

## 24. Reference directional example

The verified directional reference follows this physical design:

```text
boundary face:       left
principal direction: +x
particle motion:     +z / -z harmonic oscillation
contact type:        finite
source frequency:    500 Hz
source amplitude:    1e-6 m/s
```

The transverse relationship is:

```text
propagation direction: [1, 0, 0]
polarization:          [0, 0, 1]
dot product:           0
```

This produces a shear-dominant directional field, while validation quantifies
the remaining compressional contribution.

## 25. Summary

The finite-contact source is a controlled boundary-motion model.

The key ideas are:

```text
finite spatial footprint
+ harmonic prescribed velocity
+ transverse polarization
+ boundary-face placement
+ discrete grid sampling
```

Together these provide a reproducible way to generate directional and
multi-source shear-wave fields without claiming a complete actuator-contact
model.
