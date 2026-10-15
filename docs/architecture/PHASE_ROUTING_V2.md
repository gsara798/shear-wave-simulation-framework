# V2 phase-model routing (incremental transition)

User intent is expressed separately as `propagation.model`, `propagation.phase_model`, and `observation.geometry`. The user selects **eikonal**, not a geometry-specific solver. The framework resolves the existing implementation deterministically from geometry and validates unsupported cases rather than silently switching physical models.

Implemented new requests:

- `plane_wave + eikonal + projected3d` (planar domain and `observation.geometry=projected3d`): existing projected-3D directional eikonal; invariant in y, transverse slowness conserved. The current internal legacy model key is still `projected3d_eikonal`.
- `plane_wave + eikonal + volumetric3d` (domain with Ly_m): existing volumetric eikonal. Both `eikonal` and legacy `volumetric_eikonal` are accepted.
- `plane_wave + homogeneous_analytic` retains the existing homogeneous analytic path for planar and volumetric configurations.

Not yet implemented: **physical 2D plane-wave eikonal**. This fails explicitly. Point-source eikonal is not implemented; it must not silently use a plane-wave solver. Other geometry/phase combinations remain governed by their existing validators.

Legacy configs continue to execute as before, including `propagation.model=projected3d_eikonal`, which previously used a legacy default `phase_model=local_k_distance`, and `phase_model=volumetric_eikonal` for full 3D. Existing numerical metadata such as `wavefield.phase_model=projected3d_directional_eikonal` and the legacy projected backend model identifier remain unchanged for reproducibility. The requested user-level phase is preserved in resolved config on new paths where possible, but projected-3D currently still reports its legacy internal model identifier in `result.config.propagation.model`.

`swsynth.phase.resolveSolver(model,phaseModel,geometry)` is the new central selection policy. Future steps: unify resolved metadata to report both requested physics and selected solver, and make `synthesizeProjected3D` dispatch analytical vs eikonal while retaining existing regression baselines.
