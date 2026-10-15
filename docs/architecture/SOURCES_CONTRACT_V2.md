# Source preparation contract — V2 incremental implementation

Status: **positions, excitation, multi-source aperture, and source assembly are implemented as an additive V2 API**; synthesizers still use their existing backends and RNG contracts. See [SOURCES_PREPARE_V2.md](SOURCES_PREPARE_V2.md) for executable requests and outputs. Remaining portions of this document describe the longer-term wave-component interface, not already connected production behavior.

## Ownership and names

The umbrella module `swsynth.sources` orchestrates physical emitters and incident components:
- `sources.prepare` assembles and validates the entire source bundle.
- `sources.validate` checks shape, units, cross-field relationships, and model compatibility.
- Propagation-direction sampling is a separate wave-incidence concern, not physical source motion; the legacy `swsynth.generateDirections` is not source-force orientation.
- `sources.positions` places finite physical emitters; geometry-specific implementations only when spatial physics differs.
- `sources.excitation` prepares **source-level** force direction, amplitude, and initial phase.
- Polarization of tissue motion belongs to radiation/propagation physics, not source actuation.
- `sources.aperture` describes physical emitting elements.
Shared calculations live at the method root; geometry-specific algorithms live under `+planar2d`, `+projected3d`, `+volumetric3d` only as needed. MATLAB does not permit `+2d`.

## Data contract (proposed, conceptual)

`bundle.sources` (0..S physical sources):
- `source_id`: S-by-1 integer IDs, unique
- `position_xyz_m`: S-by-3 finite XYZ; optional for ideal plane-wave incidences
- `geometry`: point / line_segment / other supported apertures
- `force_direction_xyz`: S-by-3 unit vector when force-based radiation is selected
- `aperture`: emitting nodes and coherent weights, potentially many nodes per source

`bundle.components` (N incident contributions):
- `component_id`: N-by-1 unique IDs
- `source_id`: N-by-1 ID mapping each contribution to its parent source, or absent/undefined for ideal plane-wave components
- `direction_xyz`: N-by-3 unit vectors when plane-wave incidence directions exist; spherical fields obtain local propagation directions from positions and observation points instead
- `count`: N

`bundle.excitation` (implemented source-level):
- `relative_amplitude`: nonnegative S-by-1, may exceed one
- `phase_rad`: initial phase S-by-1
- `force_direction_xyz`: S-by-3 unit actuator force orientation, not propagation direction
- Aperture nodes are coherent: they inherit parent source excitation and are weighted by `bundle.aperture.node_weight`.

`bundle.polarization`:
- `vector_xyz`: N-by-3 for constant directional polarization where meaningful
- `projection`: N-by-1 for an explicitly defined observation axis; position-dependent radiation may require a spatial field, not a constant vector.

Do not silently require S=N. Define source/component mapping explicitly for many components from one actuator.

## Validation ownership

`sources.validate`: source IDs, source/component correspondence, units and shape; reject finite-source position requirements for pure plane-wave incidence; ensure chosen radiation, direction, geometry and polarization models are physically compatible.

Wave-incidence direction validation: a later propagation-side task.

`sources.positions.validate`: XYZ, source count, aperture geometry and spatial domain.

`sources.excitation.validate`: amplitude sign/unit convention, phase policy (fixed, shared, random) and explicit draw scope, force vectors.

Propagation/radiation polarization validation: a later task, separate from actuator forcing.

Top-level `validateConfig` owns global combinations and delegates to local validators instead of duplicating all checks.

## Random-number policy (to implement separately)

**Modular mode**: a master seed deterministically derives distinct, fixed substream seeds for `directions`, `positions`, `excitation.amplitude`, `excitation.phase`, and `polarization`. Pass explicit `RandStream` objects into generators; do not call global `rng(cfg.seed)` in a submodule. Never derive seed offsets from varying counts or module call order. MATLAB `RandStream` stream-local draws prevent unrelated modules consuming one another's draws. Preserve a stable seed derivation and record stream policy/seed metadata. Tests: repeatability; changing direction sampling does not alter excitation draws at fixed N; varying N preserves the prefix when samplers permit.

**legacy mode**: existing code paths, global reseeding, random draw consumption, floating precision and accumulation ordering remain unchanged until verified against frozen baseline outputs. New modular mode can differ numerically and must not silently replace legacy.

## Existing code status and migration

The new single-argument `swsynth.sources.prepare(request)` assembles actual physical sources. The old two-argument `swsynth.sources.prepare(cfg,directions)` remains available for exact legacy reproduction through `swsynth.sources.compat.prepareLegacy`; the legacy radii/directions coupling is **not** a new architectural invariant.

Next steps: verify new tests in MATLAB; finalize named independent RNG streams per excitation property; then integrate the assembled physical-source bundle into spherical propagation after field-level regression tests. Keep wave-incidence and material polarization distinct from actuator force.
