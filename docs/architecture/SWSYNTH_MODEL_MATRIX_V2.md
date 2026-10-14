# SWSYNTH V2 — current model/phase/geometry matrix

Status: **audited source inventory**, not a proposed API. Based on `develop/v2` dispatchers and validators. No physics or runtime behavior changed here.

## Definitions

- **Observation 2D:** `U_zx`, a sampled x-z plane. `directions.space=two_dimensional` restricts angular directions but is **not** a mathematical 2D Green function.
- **Projected 3D:** `U_zx` with 3D source/direction geometry and x-z observation plane.
- **Volumetric 3D:** `U_zyx`; `run3D` uses a separate configuration contract.

## Actual routes in dispatchers

| ID | API | Configuration / constraints | Phase | Implementation today | Key tests |
|---|---|---|---|---|---|
| P1 | `run` | `plane_wave`, `two_dimensional`, homogeneous only | `local_k_distance` field name; synthesis uses analytic directional `k·r` | `+plane_wave/synthesizeObserved2D` → `synthesizeWavefield2D` | `test_swsynth_plane_wave`, `test_swsynth_reproducibility` |
| P2 | `run` | `plane_wave`, `three_dimensional` direction samples but planar measurement; homogeneous | same as P1 | same monolith | `test_swsynth_plane_wave`, `test_swsynth_solid_angle_directions` |
| P3 | `run` | `projected3d_eikonal`, 3D directions, Fibonacci or explicit; Fibonacci requires solid-angle cap; supports heterogeneous `cs(z,x)` invariant in y | specialized projected directional eikonal (the validated `phase_model` field is not its switch) | `synthesizeProjected3DEikonal` → eight `+projected3d` helpers | `test_swsynth_projected3d_* ` family, notably run integration, homogeneous, bilayer, inclusion |
| S1 | `run` | `spherical_wave`, `constant_directional_polarization`; directions 2D or 3D, observed plane | `local_k_distance` or `straight_ray_numerical` | `synthesizeWavefield2D` legacy | `test_swsynth_phase_models`, `test_swsynth_reproducibility` |
| S2 | `run` | `spherical_wave`, `point_force_shear_far_field`, 2D directions, planar observed geometry | `local_k_distance` or `straight_ray_numerical` | `+spherical/+point_source/+shear_far_field/synthesize2D` → legacy monolith | `test_swsynth_modular_point_source`, `test_swsynth_point_force_radiation` |
| S3 | `run` | `spherical_wave`, `point_force_shear_far_field`, 3D directions/sources, planar observation | same as S2 | `synthesizeProjected3D` adapter → monolith | same plus `test_swsynth_finite_aperture` |
| V1 | `run3D` | `plane_wave`, homogeneous | `homogeneous_analytic` | `synthesizePlaneWave3D` | 3D homogeneous / configuration tests |
| V2 | `run3D` | `plane_wave`, heterogeneous supported | `volumetric_eikonal` | `synthesizeVolumetricEikonal3D` → `+volumetric3d` helpers / 3D fast sweeping | 3D eikonal and heterogeneous tests |
| V3 | `run3D` | `spherical_wave` point-force far-field, explicit positions/forces/amplitudes, **homogeneous only** | `homogeneous_analytic` | `+spherical/+point_source/+shear_far_field/synthesizeVolumetric3D` | `test_swsynth_modular_point_source` (cut comparison) |

Key note: the `run` validator accepts `phase_model=local_k_distance|straight_ray_numerical`; for `projected3d_eikonal` the specialized synthesized field uses a different phase path, so the field is misleading in this route. The `run3D` validator accepts `homogeneous_analytic|volumetric_eikonal`, with spherical restricted to the former. Do not conflate these schemas.

## Cross-cutting components / ownership

| Responsibility | Current code | Planned owner |
|---|---|---|
| Public dispatch / result assembly | `run.m`, `run3D.m` | `+swsynth/run*.m` thin orchestrators |
| Defaults, compatibility & validation | `defaultConfig*.m`, `validateConfig*.m`, `+compat` | `+config` eventually, with stable public wrappers |
| Media | `buildMediumMaps*.m`, `evaluateMediumAtXZ.m` | `+medium` (only if justified by shared interface) |
| Direction/sample placement | `generateDirections.m`, `sampleSolidAngleDirections.m`, `summarizePlaneIntersection.m` | `+sources` or `+geometry`; retain compatibility |
| Source excitation | `generateDirectionalExcitation.m`, `+sources/buildCoherentAperture.m`, spherical monolith | `+sources`; share RNG contract carefully |
| Phase/travel time | `integrateStraightRayTravelTime.m`, `+projected3d`, `+volumetric3d`, `+numerics/+eikonal` | `+phase` reusable numerical routines; algorithm-specific parts remain in model |
| Radiation polarization | monolith, `computeShearProjection.m`, directional polarization helpers | physical model-specific projector or shared transverse helper where mathematically valid |
| Measurement/grid/projection | `buildMediumMaps*.m`, synthesis and observation metadata | `+observation` only after identifying common operations |
| Wavefield contracts | `buildWavefieldSample*.m`, `+wavefield/validateSample.m` | public schema adapters; protect |
| CLI/output/provenance | `+cli`, `+io` | keep infrastructural modules |

## Inventory of examples to preserve

- `examples/swsynth/2d/homogeneous/config.json`
- `examples/swsynth/projected3d/{bilayer,inclusion}/config.json`
- `examples/swsynth/volumetric3d/{homogeneous,bilayer,inclusion}/config.json`
- `examples/swsynth/spherical/03_multiple_point_forces/config.json`
- `examples/swsynth/spherical/04_point_force_volumetric3d/config.json`
- Point-force / finite-aperture validation JSONs in `configs/swsynth/validation/`.

The spherical multi-source and volumetric examples do **not** currently share the same requested JSON schema. That is an explicit later compatibility task, not an invisible refactor.

## Test coverage and current uncertainty

Prior local MATLAB report: provenance, canonical projector, legacy-equivalence, radiation and aperture tests passed; a volumetric regression failed in sample metadata assembly (missing `sampling_method`). Two corrections to 3D direction and excitation metadata were committed **after** that report; their tests still require rerun. Never mark P1–V3 as numerically regression-certified solely from the source inventory.

Before any source moves, capture exact outputs/checksums for P1, P2, P3, S1, S2, S3, V1, V2, V3 with fixed seeds, configuration, SHA, field dimensions and metadata. Compare numerical fields with explicit tolerances (bitwise only when feasible) and independent physical invariants.
