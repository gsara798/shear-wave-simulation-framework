# Multiface and Angular Sources

This document explains the physics and implementation of multiface and generated
angular source banks in the 3D shear-wave simulation framework.

The main purpose of these source banks is to produce wavefields with broader
three-dimensional angular support than a single directional contact.

## 1. Why use more than one source?

A single finite contact usually produces a field dominated by one principal
propagation direction.

This is useful for directional validation, but it does not represent a field
with broad angular support.

Using multiple contacts allows the simulation to include waves arriving from
different directions, with different phases and polarizations.

The total field is the linear superposition of all source contributions.

Depending on the source geometry, phase policy, and polarization policy, the
resulting field may be:

```text
directional
multi-directional
partial 3D
broad angular
approximately diffuse
```

Source count alone does not determine the regime.

## 2. What is a multiface source bank?

A multiface source bank places finite contacts on more than one boundary face of
the 3D domain.

Possible faces include:

```text
left and right x-faces
front and back y-faces
top and bottom z-faces
```

Using several faces increases the set of inward propagation directions that can
be represented.

A multiface bank can therefore produce more varied angular support than a bank
restricted to a single face.

However:

```text
multiple faces != guaranteed isotropy
```

The realized angular distribution must still be evaluated.

## 3. What is a generated angular source bank?

A generated angular source bank begins with desired propagation directions.

The framework then resolves each direction into:

```text
a compatible boundary face
a finite contact center
a discrete contact mask
a transverse polarization
a phase
an amplitude
```

The generation process attempts to satisfy constraints on angular coverage and
boundary placement.

A typical workflow is:

```text
generate candidate directions
→ evaluate angular quality
→ choose a bank
→ map directions to boundary faces
→ construct finite contacts
→ validate realized geometry
```

## 4. Direction-first design

The generated angular implementation is direction-first.

This means the desired propagation directions are selected before the exact
source-node masks are constructed.

This differs from first placing random contacts and then accepting whatever
directions result.

Advantages of direction-first design:

- explicit control of angular support;
- reproducible source-bank geometry;
- direct control of in-plane and out-of-plane contributors;
- measurable directional bias;
- clearer comparison between N8, N32, and N128 banks.

The final realized directions may differ slightly from the requested directions
because they must be mapped to finite contacts on a discrete boundary.

## 5. N and P notation

Source-bank names use notation such as:

```text
N8 P2
N32 P8
N128 P8
```

`N` is the total number of finite-contact sources.

`P` is the configured number of explicitly in-plane contributors in the current
bank design.

Examples:

```text
N8 P2:
8 total sources
2 explicitly in-plane contributors

N32 P8:
32 total sources
8 explicitly in-plane contributors

N128 P8:
128 total sources
8 explicitly in-plane contributors
```

The remaining sources provide other 3D angular directions, subject to the
generation and boundary-placement constraints.

The notation describes source construction. It does not by itself prove that
the realized field is diffuse.

## 6. In-plane and out-of-plane directions

For a central x-z acquisition plane:

```text
x = lateral
z = axial
y = elevational or out-of-plane
```

An in-plane propagation direction lies primarily in the x-z plane.

An out-of-plane direction has a meaningful y component.

Examples:

```text
in-plane:
[1, 0, 0]
[0.7, 0, 0.7]

out-of-plane:
[0.7, 0.4, 0.6]
[0.2, -0.8, 0.5]
```

Out-of-plane contributors are essential when the goal is to create a truly
three-dimensional field rather than a collection of 2D waves embedded in a 3D
grid.

## 7. Propagation direction and source face

A source must be placed on a boundary face from which its requested direction
points into the domain.

Conceptually:

```text
requested direction
→ choose an inward-compatible face
→ place finite contact on that face
```

Examples:

```text
direction mainly +x
→ source on left x-face

direction mainly -x
→ source on right x-face

direction mainly +y
→ source on front or negative-y face

direction mainly -z
→ source on the positive-z face
```

The exact face naming depends on the repository convention, but the physical
requirement is always inward propagation.

## 8. Mapping error

The requested target direction and the realized source-to-domain direction are
not always identical.

Differences arise from:

- finite domain size;
- allowed contact regions;
- discrete grid coordinates;
- face selection;
- finite contact geometry;
- boundary margins.

The framework therefore uses a maximum allowed mapping error.

A typical field is:

```json
"maximum_mapping_error_deg": 10
```

The unit is degrees.

A smaller threshold demands closer agreement but can make source-bank
construction harder.

## 9. Angular candidate search

Generated angular banks can use a random-search strategy.

Typical fields include:

```json
"geometry_seed": 8202,
"placement_policy": "angular_random_search",
"angular_candidate_count": 300
```

The generator samples candidate banks and selects one that best satisfies the
configured constraints.

The geometry seed controls reproducibility of the generated bank.

The candidate count controls search effort.

More candidates may improve the selected geometry but increase configuration
resolution time.

## 10. Exact in-plane source count

A generated bank may require:

```json
"exact_in_plane_sources": 8
```

This ensures that the selected bank contains the requested number of explicitly
in-plane contributors.

This constraint is useful when comparing fields that need a controlled amount
of direct support in the acquisition plane.

It does not mean that only those sources contribute energy to the plane.

Out-of-plane waves can still project onto the measured component and central
slice.

## 11. Minimum out-of-plane component

A field such as:

```json
"minimum_out_of_plane_component": 0.20
```

requires selected out-of-plane directions to have a meaningful component along
the elevational axis.

This prevents a supposedly 3D bank from containing directions that are almost
entirely in-plane.

The threshold is dimensionless because it refers to a normalized direction
component.

## 12. Minimum unique faces

A generated bank may require:

```json
"minimum_unique_faces": 1
```

or a larger value.

This controls how many distinct domain faces must be represented.

A larger number promotes multiface coverage.

However, the best value depends on the intended field regime and domain
geometry.

## 13. Effective angular dimension

The source directions can be analyzed through their directional second-moment
matrix.

Conceptually, if normalized directions are \(\mathbf{d}_i\), an angular moment
matrix can be formed as:

```text
M = mean(d_i d_i^T)
```

The eigenvalues of this matrix indicate how broadly the directions occupy 3D
space.

Interpretation:

```text
one dominant eigenvalue:
mostly one-dimensional directional support

two dominant eigenvalues:
approximately planar angular support

three meaningful eigenvalues:
genuinely three-dimensional angular support
```

A field such as:

```json
"minimum_effective_angular_dimension": 1
```

sets an operational lower bound used by the generator.

The exact metric implementation is part of the source-bank diagnostics.

## 14. Directional bias

Directional bias measures whether the source directions favor one net direction.

Conceptually:

```text
bias = magnitude of mean direction vector
```

Interpretation:

```text
bias near 1:
strong net directional preference

bias near 0:
balanced opposing directions
```

A generated bank may specify:

```json
"maximum_directional_bias": 1
```

or a stricter value.

A low directional bias is useful for broad angular fields, but it is not enough
to prove diffusivity.

## 15. Third angular eigenvalue

A bank may require:

```json
"minimum_third_angular_eigenvalue": 0
```

The third angular eigenvalue indicates whether the source directions occupy all
three spatial dimensions.

If the third eigenvalue is nearly zero, the directions are effectively confined
to a plane.

A positive lower bound can enforce stronger 3D support.

## 16. Minimum axis separation

A bank may specify:

```json
"minimum_axis_separation_deg": 0
```

This controls the minimum angular separation between selected propagation axes.

A larger separation prevents source directions from clustering too tightly.

The best value depends on source count and desired angular coverage.

## 17. Source phase policy

A common source-bank setting is:

```json
"phase_policy": "random_uniform"
```

Each source receives a phase sampled over a full cycle.

Random phases reduce global coherence and make the field less dominated by a
single standing interference pattern.

They do not automatically create diffusivity.

A field can still be anisotropic or directionally biased even when phases are
random.

## 18. Amplitude policy

A typical setting is:

```json
"amplitude_policy": "equal_total_rms"
```

This keeps a total RMS drive measure comparable between banks with different
numbers of sources.

Without normalization:

```text
more sources
→ more total imposed drive
→ larger field amplitude for a trivial reason
```

With equal-total-RMS normalization:

```text
source count changes
while total nominal drive remains comparable
```

This is important for comparisons such as:

```text
N8 versus N32
N32 versus N128
```

It does not guarantee equal field energy inside the ROI because geometry and
interference still matter.

## 19. Polarization policy

A common 3D setting is:

```json
"polarization_policy": "project_axial_transverse"
```

The goal is to construct a polarization that is transverse to each target
direction while retaining as much axial component as possible.

Conceptually:

```text
start from axial reference vector
→ remove component parallel to propagation direction
→ normalize remaining transverse vector
```

If the target direction is \(\mathbf{d}\) and the axial reference is
\(\mathbf{e}_z\), then:

```text
p_raw = e_z - (e_z dot d) d
p = p_raw / ||p_raw||
```

This produces:

```text
p dot d = 0
```

except in degenerate cases where the target direction is nearly parallel to the
axial reference.

A fallback transverse direction is needed for such cases.

## 20. Why preserve axial motion?

In many ultrasound elastography settings, the measured motion component is
primarily axial.

An axial-transverse polarization policy therefore seeks a compromise:

```text
transverse to propagation
while remaining observable in the axial component
```

This does not mean every source moves purely axially.

For some propagation directions, a purely axial polarization would not be
transverse.

The projection step removes the longitudinal component.

## 21. Packed source representation

A large source bank must be represented efficiently for the solver.

A packed representation combines source-node masks and source-specific
waveforms into arrays compatible with k-Wave.

The packing stage preserves:

- node identity;
- source assignment;
- phase;
- amplitude;
- polarization component;
- temporal waveform.

Packing is an implementation detail, but it is essential that different source
contacts remain physically distinguishable before they are combined into the
solver input.

## 22. Simultaneous excitation

All contacts in a source bank are active during the same simulation.

The total displacement or velocity field is the superposition of all
contributions.

At any point in the medium:

```text
u_total = sum_i u_i
```

where each contribution depends on:

- source position;
- propagation path;
- material properties;
- phase;
- polarization;
- reflections;
- mode conversion.

The simulation does not separately store each source contribution unless a
special diagnostic workflow is used.

## 23. Partial 3D versus diffuse

A partial-3D field has meaningful out-of-plane content but does not claim ideal
isotropy.

A diffuse field ideally has:

- many independent contributors;
- broad angular support;
- balanced directional statistics;
- weak net directional bias;
- approximately isotropic energy distribution;
- appropriate random phase behavior.

Finite simulations can approach some of these properties, but a source bank
should not be labeled diffuse based only on N.

A more careful terminology is:

```text
directional
partial 3D
broad angular
projected diffuse 3D
diffuse idealization
```

The chosen label should match the realized field and validation metrics.

## 24. Projected 3D field

A 3D field may be observed through:

- one displacement component;
- one central plane;
- one imaging plane;
- one ultrasound-sensitive direction.

The observed 2D field is therefore a projection or slice of a 3D wavefield.

Even if the full 3D source distribution is balanced, the measured projection
may not appear isotropic.

This distinction is important for REQ because the radial spectrum of a projected
3D field differs from that of a genuinely 2D diffuse field.

## 25. N8 P2 interpretation

N8 P2 is a compact partial-3D development field.

Its purpose is to provide:

- more than one direction;
- explicit in-plane support;
- out-of-plane contributions;
- modest computational cost;
- reproducible testing of 3D source handling.

It should not be described as an ideal diffuse field.

## 26. N32 P8 interpretation

N32 P8 provides broader angular support and more contributors than N8 P2.

Its purpose is to provide a stronger multifield validation case while remaining
computationally manageable.

Compared with N8 P2, it can offer:

- more angular samples;
- reduced dependence on individual sources;
- richer interference;
- stronger 3D support.

It still does not guarantee perfect isotropy.

## 27. N128 P8 interpretation

N128 P8 uses many more sources.

Its purpose is to approach a higher-source-count broad angular field and test
the scalability of source-bank construction.

Potential advantages:

- denser angular support;
- reduced prominence of individual contacts;
- richer random-phase superposition.

Potential costs:

- more source nodes;
- larger source arrays;
- more complex validation;
- greater setup and memory demands.

## 28. Finite-contact effects in angular banks

Each generated direction is represented by a finite contact, not an ideal plane
wave.

Therefore each contribution has:

- finite aperture;
- near-field structure;
- angular spread;
- boundary-face dependence;
- discretization effects.

The bank should be interpreted as a collection of finite boundary excitations
whose dominant directions approximate the target angular distribution.

## 29. Heterogeneous media

In heterogeneous media, source-bank angular design describes incident source
geometry, not the final local direction distribution everywhere.

Interfaces can produce:

- reflection;
- refraction;
- mode conversion;
- local focusing;
- shadowing;
- altered polarization.

Therefore the final field inside an inclusion or across a bilayer may have a
different angular structure from the source bank.

## 30. Validation metrics

A multiface or angular source bank should be evaluated using both source-level
and field-level metrics.

### Source-level checks

- number of sources;
- unique faces;
- in-plane count;
- out-of-plane component;
- mapping error;
- directional bias;
- angular eigenvalues;
- total-drive normalization;
- phase policy;
- contact validity.

### Field-level checks

- finite complex fields;
- source-frequency purity;
- P/S energy ratio;
- cross-polarization leakage;
- steady-state change;
- angular spectrum;
- directional concentration;
- angular entropy;
- repeatability;
- REQ readiness.

A good source geometry does not guarantee a good realized field.

## 31. Angular entropy

Angular entropy measures how broadly spectral energy is distributed over angle.

Interpretation:

```text
low entropy:
energy concentrated in a few directions

high entropy:
energy distributed more broadly
```

Angular entropy depends on:

- selected plane or volume;
- spectral estimator;
- angular binning;
- analysis annulus;
- measured component.

It should be interpreted as a case-specific diagnostic, not a universal
diffusivity score.

## 32. Directional concentration

Directional concentration measures how much energy lies near a dominant
direction.

A directional field should have high directional concentration.

A broad angular field should generally have lower concentration.

Thresholds depend on the selected angular window and spectral implementation.

## 33. Reproducibility

A reproducible generated bank requires preserving:

- requested JSON;
- resolved configuration;
- top-level seed;
- geometry seed;
- generated target directions;
- realized source faces;
- source centers;
- phases;
- amplitudes;
- polarizations;
- software version.

The resolved configuration is more important than the requested JSON alone
because it records the generated realization.

## 34. What the framework represents

The multiface and angular source system represents:

- many finite boundary actuators;
- controlled propagation directions;
- controlled source phases;
- transverse polarizations;
- comparable total drive;
- broad 3D angular excitation;
- simultaneous interference.

## 35. What it does not guarantee

The source-bank design does not guarantee:

- a mathematically isotropic diffuse field;
- equal local energy in all directions;
- equal amplitude everywhere;
- absence of compressional waves;
- perfect plane-wave contributions;
- experimental actuator equivalence;
- identical projected and volumetric angular statistics.

These properties must be tested rather than assumed.

## 36. Recommended terminology

Use:

```text
generated angular source bank
multiface finite-contact bank
partial-3D field
broad-angular field
projected 3D field
```

Use `diffuse` only when the source and field metrics support that description.

## 37. Summary

The angular-bank workflow is:

```text
choose desired angular support
→ generate candidate directions
→ enforce in-plane and 3D constraints
→ map directions to valid boundary faces
→ create finite contacts
→ assign transverse polarizations
→ assign phases and normalized amplitudes
→ run all contacts simultaneously
→ validate the realized field
```

The central principle is that angular support is designed explicitly, but the
physical field must still be measured and validated after discretization and
wave propagation.
