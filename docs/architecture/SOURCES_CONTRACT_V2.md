# Source preparation contract — V2 proposal (not yet wired)

Status: **design contract only**. Existing synthesizers and RNG behavior are unchanged. Do not interpret this document as implemented MATLAB API.

## Ownership and names

The umbrella module `swsynth.sources` orchestrates physical emitters and incident components:
- `sources.prepare` assembles and validates the entire source bundle.
- `sources.validate` checks shape, units, cross-field relationships, and model compatibility.
- `sources.directions` samples *propagation directions* (a directional component need not belong to a finite point source).
- `sources.positions` places finite physical emitters; geometry-specific implementations only when spatial physics differs.
- `sources.excitation` selects source/component amplitude, initial phase and force vectors, with explicit draw scope.
- `sources.polarization` computes shear polarization and projection; do not confuse source force with material displacement.
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

`bundle.excitation`:
- `amplitude`: nonnegative S-by-1 or N-by-1 (scope must be stated explicitly)
- `initial_phase_rad`: S-by-1 or N-by-1; deterministic fixed, shared or independently sampled
- `force_direction_xyz`: source-level parameter when applicable, not a synonym for propagation direction
- `draw_scope`: source / aperture_element / component

`bundle.polarization`:
- `vector_xyz`: N-by-3 for constant directional polarization where meaningful
- `projection`: N-by-1 for an explicitly defined observation axis; position-dependent radiation may require a spatial field, not a constant vector.

Do not silently require S=N. Define source/component mapping explicitly for many components from one actuator.

## Validation ownership

`sources.validate`: source IDs, source/component correspondence, units and shape; reject finite-source position requirements for pure plane-wave incidence; ensure chosen radiation, direction, geometry and polarization models are physically compatible.

`sources.directions.validate`: unit vectors, physical dimension, angular support / sampling configuration.

`sources.positions.validate`: XYZ, source count, aperture geometry and spatial domain.

`sources.excitation.validate`: amplitude sign/unit convention, phase policy (fixed, shared, random) and explicit draw scope, force vectors.

`sources.polarization.validate`: transversality where required and measurement-axis compatibility.

Top-level `validateConfig` owns global combinations and delegates to local validators instead of duplicating all checks.

## Random-number policy (to implement separately)

**Modular mode**: a master seed deterministically derives distinct, fixed substream seeds for `directions`, `positions`, `excitation.amplitude`, `excitation.phase`, and `polarization`. Pass explicit `RandStream` objects into generators; do not call global `rng(cfg.seed)` in a submodule. Never derive seed offsets from varying counts or module call order. MATLAB `RandStream` stream-local draws prevent unrelated modules consuming one another's draws. Preserve a stable seed derivation and record stream policy/seed metadata. Tests: repeatability; changing direction sampling does not alter excitation draws at fixed N; varying N preserves the prefix when samplers permit.

**legacy mode**: existing code paths, global reseeding, random draw consumption, floating precision and accumulation ordering remain unchanged until verified against frozen baseline outputs. New modular mode can differ numerically and must not silently replace legacy.

## Existing code status and migration

Present V2 code uses `swsynth.generateDirections`, `swsynth.generateDirectionalExcitation`, `swsynth.sources.buildCoherentAperture`, and an experimental `swsynth.sources.prepare`. These are **not** the full new contract. In particular the current `sources.prepare` derives point positions even for plane waves to match legacy RNG behavior; do not make this an invariant of the new interface.

Next steps: (1) validate this schema and policies; (2) implement source-local validation and deterministic stream manager with independent tests; (3) adapt directions and positions separately; (4) prepare excitation/polarization and assemble bundle; (5) integrate into synthesis after field-level regressions.
