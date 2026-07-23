# Terminology

This glossary defines the operational, numerical, and physical terminology used
throughout the shear-wave simulation framework.

The goal is to keep configuration files, validation reports, examples, and user
documentation consistent.

## Analysis cycles

The number of complete excitation cycles used to estimate the harmonic field at
the source frequency.

These cycles are analyzed after the settling interval. Increasing the number of
analysis cycles can improve harmonic estimation but also increases simulation
time.

Configuration field:

```text
time.analysis_cycles
```

## Angular source bank

A multi-source configuration designed from target propagation directions rather
than from a single boundary face.

The framework maps requested directions to finite contacts on valid domain
faces and assigns transverse source polarizations.

Examples include:

```text
generated angular N8 P2
generated angular N32 P8
generated angular N128 P8
```

An angular source bank is not automatically an ideal diffuse field. Its angular
coverage must be assessed from the realized source geometry and field metrics.

## Background material

The material that fills the domain before heterogeneous objects or bilayers are
applied.

Typical background properties include:

```text
shear-wave speed
compressional-wave speed
density
material ID
```

In the current 3D geometry implementation, heterogeneous regions are applied
over this background according to the configured geometry precedence.

## Bilayer

A two-material geometry separated by a plane.

The interface is defined by:

```text
a point on the plane
a normal vector
a material on the negative side
a material on the positive side
```

The normal vector determines the orientation of the interface.

## CLI

Command-line interface.

The framework CLI is:

```bash
./scripts/kwsim-run CONFIG.json
```

It loads a JSON configuration, resolves and validates the simulation, runs the
solver when requested, evaluates the result, and saves outputs.

## Configured run

A simulation launched from a JSON configuration through the CLI.

Example:

```bash
./scripts/kwsim-run   configs/three_d/homogeneous_directional_req_validation.json
```

A configured run differs from calling low-level MATLAB functions manually
because it follows the standard configuration, validation, output, and
provenance workflow.

## Contact

The boundary region where prescribed particle velocity is applied.

A contact may be:

```text
a point contact
a finite segment in 2D
a finite disk on a 3D boundary face
```

A contact is a numerical representation of an external actuator. It is not a
complete mechanical model of the actuator, coupling layer, or stress transfer.

## Contact radius

The requested physical half-size of a finite source contact.

Configuration field:

```text
source.contact_radius_m
```

In 2D, this controls the half-extent of a finite segment.

In 3D, this controls the radius of a finite disk.

The realized contact is discretized on the numerical grid.

## Data contract

The documented agreement that defines:

```text
field names
array orientation
units
required metadata
coordinate conventions
saved-file structure
```

The data contract prevents physically incorrect interpretation of arrays that
may otherwise have compatible dimensions.

## Diffuse field

An idealized field with broad and approximately isotropic angular support and
many incoherent contributors.

A finite simulated multi-source field should not be called fully diffuse only
because it contains many sources. Angular coverage, directional bias, and field
statistics must support that interpretation.

## Dimension

The simulation dimensionality.

```text
dimension = 2
dimension = 3
```

In public 2D fields:

```text
x = lateral coordinate
z = axial or depth coordinate
```

In public 3D fields:

```text
x = lateral coordinate
y = elevational or out-of-plane coordinate
z = axial or depth coordinate
```

## Directional field

A wavefield dominated by one principal propagation direction.

The reference directional configuration uses one finite boundary contact with
source motion transverse to the main propagation direction.

## Dry run

A configuration validation and preflight operation that does not execute the
k-Wave solver and does not create simulation outputs.

Command:

```bash
./scripts/kwsim-run CONFIG.json --dry-run
```

A dry run checks that the configuration can be loaded, resolved, and validated.

A successful dry run does not prove that the eventual physical simulation will
pass all post-solver validation checks.

## Finite contact

A source applied over a nonzero physical region rather than at one mathematical
point.

The current framework uses:

```text
finite_segment in 2D
finite_disk in 3D
```

Finite contacts are discretized into solver nodes according to the selected
sampling policy.

## Generated angular bank

A source bank created by selecting target directions and then resolving valid
finite contacts on the available 3D boundary faces.

The generator attempts to satisfy configured angular and placement constraints.

The realized bank must still be inspected because discretization and boundary
mapping can modify the requested geometry.

## Grid

The numerical spatial discretization.

Typical fields include:

```text
Nx, Ny, Nz
dx_m, dy_m, dz_m
```

The number of grid points and spatial spacing determine physical domain size,
points per wavelength, memory use, and computational cost.

## Harmonic field

The complex field estimated at the excitation frequency after the time-domain
simulation.

A harmonic field contains amplitude and phase information.

The phasor convention used by the framework is:

```text
signal(t) = real(phasor * exp(1i * 2*pi*f0*t)) + dc
```

## Heterogeneous medium

A domain containing more than one material.

Heterogeneity may be introduced through:

```text
spheres
finite cylinders
bilayers
combined geometries
```

The saved truth maps identify the local material properties.

## In-plane source

A source whose intended contribution lies predominantly in the selected
acquisition plane.

For the central x-z acquisition plane, in-plane and out-of-plane labels describe
the intended angular contribution relative to that plane.

They do not mean that the full 3D field is restricted to two dimensions.

## Integration test

A test that verifies multiple components working together.

An integration test may include:

```text
configuration loading
source construction
k-Wave execution
harmonic extraction
validation
output generation
```

Integration tests are slower than unit tests because they may execute the
solver.

## Material ID

An integer label identifying which material occupies each grid location.

Material IDs allow saved fields to be associated with truth regions without
reconstructing geometry from floating-point material properties.

## Multiface source bank

A multi-source configuration with contacts distributed across more than one
boundary face.

Multiface placement broadens the set of available propagation directions
compared with a single-face bank.

It does not by itself guarantee isotropy or diffusivity.

## N and P notation

Source-bank names use notation such as:

```text
N8 P2
N32 P8
N128 P8
```

`N` is the total number of sources in the bank.

`P` is the configured number of explicitly in-plane contributors used by the
current source-bank design.

The remaining contributors provide other 3D angular directions, subject to the
bank-generation and boundary-placement constraints.

## Out-of-plane source

A source whose intended propagation contribution includes a significant
component outside the selected acquisition plane.

Out-of-plane contributors help broaden three-dimensional angular support.

## P wave

Compressional or longitudinal wave component.

Particle motion is predominantly parallel to the propagation direction.

The framework estimates compressional contamination rather than assuming it is
zero.

## P/S energy ratio

The ratio of compressional-field energy to shear-field energy in the analyzed
region.

A smaller value indicates a more shear-dominant field.

The acceptance threshold depends on the configured validation case and should
not be treated as universal.

## Partial 3D field

A field with broader three-dimensional angular content than a directional or
single-face field, but without claiming ideal isotropic diffusivity.

The N8 P2 configuration is a reproducible partial-3D development field.

## Phasor

A complex number or complex array representing the amplitude and phase of a
harmonic quantity at one frequency.

The magnitude gives harmonic amplitude, and the angle gives harmonic phase.

## PML

Perfectly matched layer.

The PML is the absorbing numerical boundary region used to reduce reflections
from the edges of the computational domain.

PML settings strongly affect numerical cost and boundary behavior and should
not be modified casually.

## Points per wavelength

The number of spatial samples across one wavelength.

For shear waves:

```text
PPW = lambda_s / dx
lambda_s = cs / f0
```

For anisotropic grids, the relevant spacing must be considered along each axis.

Insufficient points per wavelength can make the simulation inaccurate even when
the solver completes.

## Preflight

The set of checks performed before solver execution.

Preflight may assess:

```text
configuration consistency
units
grid resolution
CFL
material admissibility
geometry placement
sensor region
duration
memory requirements
```

Preflight success means the requested simulation is operationally acceptable
for execution. It is not post-solver physical validation.

## Public orientation

The array orientation exposed by the framework to users and saved outputs.

Public 2D maps use:

```text
[Nz, Nx]
suffix: _zx
```

Public 3D volumes use:

```text
[Nz, Ny, Nx]
suffix: _zyx
```

The internal k-Wave solver orientation is handled inside the adapter layer.

## REQ-ready

A validation-sample status indicating that the exported field satisfies the
operational input requirements for external REQ processing.

Typical requirements include:

```text
finite complex field
known frequency
known spacing
sufficient field dimensions
compatible REQ window
minimum number of placements
documented orientation
```

REQ-ready does not mean that REQ has been executed, that the estimated SWS is
accurate, or that a scientific validation has passed.

## Requested configuration

The parameters supplied directly by the user in the input JSON.

The requested configuration records the simulation intent.

It may omit defaults and derived values.

## Resolved configuration

The complete configuration after defaults, derived parameters, source geometry,
material geometry, and operational settings have been resolved.

Configured runs save the resolved configuration because it is the more complete
record of what was actually executed.

## Run directory

The timestamped directory containing the products of one configured simulation.

Typical structure:

```text
config/
data/
figures/
manifest.txt
```

## Run name

The descriptive label used in the output directory name.

Configuration field:

```text
output.run_name
```

A run name should identify the physical case rather than the person who ran it.

## S wave

Shear or transverse wave component.

Particle motion is predominantly perpendicular to the propagation direction.

## Scenario

A descriptive identifier for the configured physical and validation case.

Configuration field:

```text
scenario
```

The scenario may control which validation logic and figures are used by the CLI.

It should not be changed arbitrarily unless the intended dispatch behavior is
understood.

## Seed

The integer used to reproduce supported random choices, such as source phases or
generated source-bank geometry.

Configuration field:

```text
seed
```

The same configuration and seed should reproduce the same deterministic
realization, subject to the documented software environment.

## Settling cycles

The number of excitation cycles allowed before the harmonic analysis interval.

Configuration field:

```text
time.settling_cycles
```

The settling interval allows transients to decay and the field to approach a
stable harmonic regime.

## Smoke test

A compact end-to-end test that checks whether an important workflow executes and
produces structurally reasonable outputs.

A smoke test answers:

```text
Does the pipeline run?
```

It does not prove broad scientific validity across parameter space.

## Source bank

A collection of independently defined source contacts.

A source bank can include source-specific:

```text
position
boundary face
phase
amplitude
polarization
target direction
```

## Source polarization

The direction of prescribed particle motion at a source.

For shear-dominant excitation, polarization is chosen transverse to the intended
propagation direction.

## Steady-state change

A metric comparing harmonic-field estimates from different late-time cycle
groups.

A small value indicates that the estimated harmonic field is no longer changing
substantially over the analyzed interval.

The configured threshold is case-specific.

## Unit test

A test that checks one small function or component in isolation.

Examples include testing:

```text
configuration resolution
geometry construction
source masks
orientation conversion
metric calculations
```

Unit tests should generally run without executing a full physical simulation.

## Validation

Post-resolution or post-solver checks used to determine whether a result
satisfies the requirements of its configured case.

Validation may include:

```text
finite fields
source-frequency content
P/S energy ratio
steady-state convergence
speed agreement
material IDs
REQ readiness
```

A validation threshold is part of the case definition and should not be treated
as universal.

## Validation report

The structured record of validation metrics, thresholds, pass/fail values, and
summary status.

Configured runs typically save:

```text
data/validation_report.mat
data/validation_summary.txt
```

## Vibrator bank

A source bank intended to represent multiple external shear-wave actuators.

The current framework prescribes boundary particle velocity. It does not model
the complete mechanical actuator, contact stress, or coupling material.

## Wavefield regime

A descriptive class for the angular structure of the field.

Current terminology includes:

```text
directional
single-face multi-source
partial 3D
generated angular
broad angular
diffuse idealization
```

These labels should be used according to realized geometry and validation
evidence, not only source count.
