# SWSYNTH architecture inventory — V2 (baseline)

Status: **inventory only**. No physics, schema, numerical implementation, or dispatch changes are authorized by this document. Branch reviewed: `develop/v2`.

## Scope and boundaries

The framework includes multiple backends and infrastructure: `+swsynth` (fast analytical/eikonal synthetic fields), `+kwsim` (k-Wave), `+simcampaigns`, `+simrunner`, `+simreport`, `+simviz`, and `+wavefield`. This first inventory covers **only** `src/+swsynth`: **47 files**, including one Markdown architecture file. Integrations with other backends remain a later audit.

## Current public execution paths

| Entry | Validation / maps | Numerical dispatch | Output |
|---|---|---|---|
| `swsynth.run(cfg)` | `validateConfig`, `buildMediumMaps`, `generateDirections` | `projected3d_eikonal` → `synthesizeProjected3DEikonal`; `spherical_wave` → point-source wrappers OR legacy `synthesizeWavefield2D`; `plane_wave` → `+plane_wave/synthesizeObserved2D` → legacy `synthesizeWavefield2D` | `U_zx`, `buildWavefieldSample`, spectral metrics |
| `swsynth.run3D(cfg)` | `validateConfig3D`, `buildMediumMaps3D` | plane-wave homogeneous → `synthesizePlaneWave3D`; plane-wave eikonal → `synthesizeVolumetricEikonal3D`; spherical point-force homogeneous → `+spherical/+point_source/+shear_far_field/synthesizeVolumetric3D` | `U_zyx`, `buildWavefieldSample3D` |
| `swsynth.cli.runConfig(configFile)` | 2D `validateConfig` | `swsynth.run` | Configs, MAT, summary and manifest; Git provenance included in CLI output |

**Important:** The 3D public API and the CLI use different pathways. CLI provenance is not yet a guarantee for every MATLAB/campaign invocation.

## Where implementation actually lives

| Current location | Responsibility actually implemented | Assessment |
|---|---|---|
| `synthesizeWavefield2D.m` (~603 lines) | Legacy spherical and plane-wave field synthesis; source placement, random draws, phases, geometric decay, radiation projection, output and noise | **Primary monolith; high refactor risk** |
| `+propagation/+plane_wave/synthesizeObserved2D.m` (5 lines) | Delegates to monolith | Adapter only, not a separate implementation |
| `synthesizePlaneWave3D.m` (~167 lines) | Analytic volumetric directional-plane-wave synthesis, polarization and projection | Implemented outside plane-wave folder |
| `synthesizeProjected3DEikonal.m` (~246 lines) | Orchestrates projected 3D directional waves and eikonal-like phase | Implemented outside propagation package; uses `+projected3d` helpers |
| `synthesizeVolumetricEikonal3D.m` (~181 lines) | 3D directional eikonal synthesis, polarization, output | Implemented outside propagation package; uses `+volumetric3d` helpers |
| `+propagation/+projected3d/` (8 files) | Slowness, boundary phase, direction filtering, polarization and directional field synthesis | Organized by observation geometry instead of wave family |
| `+propagation/+volumetric3d/` (2 files) | Incident boundary conditions and directional travel-time | Organized by domain dimensionality |
| `+propagation/+spherical/+point_source/+shear_far_field/` (4 files) | Physical transverse projector; 2D/projected3D adapters; new volumetric calculation | Partially modular: 2D adapters still call monolith |
| `+propagation/+spherical/computePointForceShearProjection.m` | Backward compatibility forwarding to canonical projector | Retain until caller audit |
| `integrateStraightRayTravelTime.m` | Numerical travel-time integration used by legacy spherical model | Candidate for later numerical phase module |
| `+numerics/+eikonal/` (2 files) | 2D/3D fast-sweeping solvers | Already reasonably isolated numerical methods |
| `+sources/buildCoherentAperture.m`, `generateDirectionalExcitation.m`, `generateDirections.m` | Source geometry, directional amplitude/phase and directional sampling | Shared machinery, must not be silently duplicated |
| `defaultConfig*.m`, `validateConfig*.m` | Two distinct configuration contracts | Require explicit compatibility design before JSON migration |
| `buildWavefieldSample*.m` | Public backend-neutral output contract | Must remain stable for REQ-ML and campaigns |
| `+compat/`, `+metrics/`, `+io/`, `+cli/` | Compatibility, spectra, output directories, provenance and JSON execution | Keep separate from physical propagation |

## Three independent axes to represent

1. **Wavefield family:** plane directional superposition vs spherical outgoing point-source waves.
2. **Phase / travel-time algorithm:** homogeneous analytic, local-k distance, straight-ray numerical, projected directional eikonal, volumetric eikonal. These are *not* universally interchangeable; compatibility must be validated.
3. **Observation geometry:** plane 2D, plane-observed projected 3D (sources genuinely 3D), full volumetric 3D. A plane-observed point force is **not** the same physical model as a true 2D line-force Green function.

Do not infer that all combinations of the three axes are supported. The current config names differ across 2D and 3D APIs; keep those stable in phase 1.

## Priority risks and guardrails

- Legacy 2D monolith draws random numbers in a deliberate order, including draws not needed by some modes; preserving the seeded field requires preserving this sequence.
- Source amplitudes, explicit source placement, aperture expansion, and observed polarization interact. Avoid simultaneous semantic changes.
- The point-force 3D implementation was recently added. Ensure `buildWavefieldSample3D` metadata and measured-axis projection are covered by tests.
- A phase eikonal approximation in a heterogeneous medium is not a validated full elastodynamic Green solution.
- Run provenance is implemented in `swsynth.cli.runConfig`, not guaranteed across all direct/campaign routes.
- Preserve legacy calling APIs and JSON behavior during structural refactoring; move implementation first, then deprecate wrappers after inspecting downstream callers.
- Generated `outputs/` are ignored in V2, but previously tracked generated artifacts may still exist in Git history/index.

## Phase 1: baseline to freeze before moving functions

Check and record test outcomes (not automatically assumed passing):

```matlab
addpath(fullfile(pwd,'src'))
r = runtests({ ...
  'tests/unit/test_swsynth_modular_point_source.m', ...
  'tests/unit/test_swsynth_point_force_radiation.m', ...
  'tests/unit/test_swsynth_finite_aperture.m', ...
  'tests/unit/test_swsynth_plane_wave.m', ...
  'tests/unit/test_swsynth_phase_models.m', ...
  'tests/unit/test_swsynth_projected3d_run_integration.m', ...
  'tests/unit/test_swsynth_framework_provenance.m'});
disp(table(r)); assertSuccess(r)
```

Then run the full framework test suite before major moves. For each representative mode, retain a compact reference with config, SHA, seed, array size, finite checks, wavefield checksum or deterministic comparator, and relevant output metadata. Avoid committing large generated MAT files; use fixture hashes or small synthetic fixtures where appropriate.

## Proposed next step (not implemented)

Create a **behavior-preserving dispatch and responsibility matrix** per supported config family, then prioritize extracting `plane_wave` implementation from the monolith in an isolated branch/commit with regression tests. Separate numerical phase helpers only once precise ownership and reuse is established; do not create empty `+phase` or `+observation` packages on speculation.
