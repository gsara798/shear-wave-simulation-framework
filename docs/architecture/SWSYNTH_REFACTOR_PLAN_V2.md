# V2 architecture plan — staged, behavior-preserving

**Depends on:** [SWSYNTH model matrix](SWSYNTH_MODEL_MATRIX_V2.md) and [initial inventory](SWSYNTH_INVENTORY_V2.md).

## Design decisions

1. Organize *primary physical implementations* by `propagation/plane_wave` and `propagation/spherical/point_source/shear_far_field`. A future full point-force Green tensor belongs under `spherical/point_source/green` (not yet implemented).
2. Observation dimensionality is a separate dispatch input (`2d`, `projected3d`, `volumetric3d`); it does **not** imply a new physical source model. Do not call planar cuts a true 2D Green solution.
3. Separate numerical travel-time/phase algorithms from wavefield family **only when genuinely reusable**. Potential `+phase` with straight rays/eikonal orchestration; preserve `+numerics/+eikonal` solvers.
4. Keep source excitation, geometry, sampling, and aperture independent of propagation, with a single well-defined RNG sequence and normalized force-direction convention.
5. Preserve public `swsynth.run`, `swsynth.run3D`, old JSON schemas, sample shape/fields, and previous seeds through transitional adapters. Never silently reinterpret an old config.
6. Prefer one change in one responsibility per PR/commit, with pinned numerical regression references, no wholesale rewrites.

## Desired architecture (conceptual, not folders to create blindly)

```text
+swsynth/
  run.m                        # stable public API, thin orchestration
  run3D.m                      # stable public API, thin orchestration
  +config/                     # optional eventual normalization/validation
  +medium/                     # optional medium construction
  +sources/                    # placement, angular sampling, force/phase/weights, aperture
  +propagation/
    +plane_wave/
      synthesize2D.m
      synthesizeProjected3D.m  # directional eikonal representation
      synthesizeVolumetric3D.m
    +spherical/
      +point_source/
        +shear_far_field/
          computeShearProjection.m
          synthesize2D.m       # planar observation of 3D point sources
          synthesizeProjected3D.m
          synthesizeVolumetric3D.m
        +green/                # future; P/S/near field, not part of refactor
  +phase/                      # only shared phase/travel-time operations
  +numerics/+eikonal/          # pure fast-sweeping solvers
  +observation/                # only shared grids/component projections
  +io/ +cli/ +metrics/ +compat/
```

The current `+projected3d` and `+volumetric3d` namespaces house **directional-wave numerical helpers**; they should migrate only after each helper is classified as model physics vs reusable phase vs observation geometry. Do not simply move all their files into `+phase`.

## Stages, acceptance criteria and rollback

### 0 — freeze behavioral baselines (gate)

- Obtain green full-suite result at current `develop/v2` SHA (or record known failures explicitly).
- Run fixed-seed cases spanning matrix P1–V3, record field outputs/digests, shape, metadata and any physical checks.
- Ensure unique MATLAB source path, exact Git SHA, clean tree, tool version captured.
- **Gate:** every supported route has a source fixture and a test. Fix previously discovered 3D sample metadata issues before moving more synthesis code.

### 1 — make propagation dispatch explicit

- Write a single compatibility map translating *existing* 2D and 3D schemas into internal wave-family, phase method, observation geometry, source model without changing public JSON behavior.
- Keep existing entrypoints; route through thin stable dispatchers.
- **Gate:** same validation errors and equivalent fields for all old configs.

### 2 — extract plane-wave implementations (first physical refactor)

- Move/call the real plane-wave branch from `synthesizeWavefield2D.m` into `+propagation/+plane_wave/synthesize2D.m`.
- Relocate volumetric analytic and volumetric eikonal implementations to plane-wave module, retain compatibility wrappers during transition.
- Classify projected directional eikonal as *plane-wave/directional propagation using a projected-3D observation*, not spherical propagation.
- **Gate:** P1, P2, P3, V1, V2 pass field regression and metadata comparison; no change in RNG or normalization.

### 3 — extract spherical point-force and legacy spherical paths

- Remove spherical contribution loops from monolith into reusable spherical synth modules, preserving distinct `local_k_distance` and straight-ray implementations as needed.
- Keep legacy constant-polarization spherical model explicit (do not falsely label it as a point-force).
- Share physical shear projector across observation geometries, with observation-specific array shapes only.
- **Gate:** S1–S3, V3 regress; 3D slice test passes within precision tolerance, both with 0 and 1 spreading exponents where meaningful.

### 4 — centralize true shared utilities

- Split out reusable phase/travel-time calculations; keep pure fast-sweeping solvers in `+numerics`.
- Move noise, measurement projection, and field packaging only where duplicated; ensure spatially varying point-source projection isn't replaced by a global weight.
- Consider new `+medium`, `+config`, `+observation` packages only if complexity decreases measurably.
- **Gate:** complete suite + example runs; confirm documented contracts and no circular dependencies.

### 5 — JSON schema v2, only after internal structure stable

- Proposed normalized conceptual schema: `propagation.wave_type`, `propagation.model`, `propagation.phase_model`, `observation.geometry`, `observation.component`.
- Provide deterministic version-aware translator from v1 schema; reject ambiguous/incompatible combinations.
- Do **not** silently remap the old `projected3d_eikonal` key to a spherical model.
- **Gate:** every existing checked-in config still runs unchanged or is explicitly routed via versioned compatibility; document any intentional incompatibility.

### 6 — cross-backend and release audit

- Assess `+kwsim`, `+simcampaigns`, `+simrunner`, `+simviz`, `+simreport`, `+wavefield`, examples, generated outputs, and provenance in *direct* `run`/`run3D` as well as CLI/campaigns.
- Test all declared examples; document exact code provenance and sample contracts.
- Merge to stable only when gate passes; tag `v2.0.0` at the final clean commit, preserving the existing v1 refs.

## Practical refactor rules

- Avoid moving physical calculations and changing units, physics assumptions, random phase, or amplitude distributions within the same commit.
- Always keep deterministic reference checks and scientific invariants separate (both are useful).
- Write deprecation wrappers for public functions and migrate their callers before removing wrappers.
- Do not add empty architecture folders merely to match the diagram.
- Each stage should end with a user-runnable MATLAB test command, explicit pass/fail report, commit SHA and rollback point.

**Next actionable task:** Stage 0 fixed-seed baseline and correction/verification of the 3D sample contract. No Green tensor implementation until structure is stable.
