# swsynth V2: simcampaigns integration and legacy-folder audit

**Development branch:** `develop/v2`. **State:** V2 runner and integration tests implemented, **not yet executed in MATLAB**. Legacy backend remains independently routable for old config schema. k-Wave campaign backend is untouched.

## 1. Versioned routing (now implemented)

The campaign API uses `backend="swsynth"` for **both** historical and modular runs. The **simulation configuration**, not the campaign schema, selects implementation:

| Simulation config | Routing | Meaning |
|---|---|---|
| `schema_version="2.0"` | `swsynth.io.resolveConfigV2` → `swsynth.propagation.synthesize` → `swsynth.io.buildWavefieldSampleV2` | **Modular V2**, one global frequency, vector field, explicit observed component |
| Legacy schema/config | `swsynth.validateConfig` / `validateConfig3D` → `swsynth.run` / `run3D` | **Old backend**, temporarily retained so its tests and campaigns don't break |
| `backend="kwsim"` | Unchanged | Independent PDE k-Wave backend |

`simcampaigns` campaign documents themselves continue using schemas `1.1` or `1.2` with `backend="swsynth"`. Their `base_config` can now be a **V2 2.0 JSON**. Sweep paths, hashes, campaign IDs and resume behavior remain in `simcampaigns`, not the synthesizer.

### Entry points / fixtures

```matlab
addpath(fullfile(pwd,'src'));

% One new synthetic V2 simulation, saved as wavefield_sample.mat
out=simrunner.runConfig( ...
    'configs/swsynth/v2/homogeneous_plane_base.json', ...
    PlotFigures=false);

% V2 campaign: 2 cs values * 2 frequencies = 4 saved runs
report=simcampaigns.runCampaign( ...
    'configs/campaigns/swsynth/smoke/swsynth_v2_homogeneous_smoke.json', ...
    ContinueOnError=false);

% Also available:
% configs/swsynth/v2/two_sources_projected3d.json
% configs/swsynth/v2/projected3d_heterogeneous_eikonal.json
% configs/swsynth/v2/volumetric3d_heterogeneous_eikonal.json
```

V2 output retains the established run layout:

```text
<campaign output>/<campaign_name>/<run_id>/
    config/resolved_config.json
    data/wavefield_sample.mat
    data/run_summary.json
    validation/validation_report.json
    figures/...
    campaign_run.json
```

The saved MAT variable is `wavefield_sample` validated by `wavefield.validateSample`. The V2 sample stores `sample_id` and `provenance.run_id` derived from the run directory; realized physical source positions/force/phases live in `sample.sources`; initial incoming plane directions live in `sample.directions`.

**Crucial:** `truth.k_map` represents local elastic material `2*pi*f/cs_map`, **not** the phase gradient in an Eikonal field or a measured REQ quantity. `validation.physics_validated=false`, and `quantity="relative_motion"` is not calibrated displacement/velocity. The current temporal sign convention remains undefined.

For stochastic sources, config `seed` is applied within a scoped RNG state (restored afterward). V2 dry-run uses local RandStreams to validate source positions, forces and apertures without consuming caller RNG or synthesizing fields.

## 2. Removed/deprecated folders

After the first cleanup pass (six aliases), this pass removed four additional obsolete forwarding files:

- `+swsynth/+propagation/+volumetric3d/buildIncidentBoundaryCondition.m`: the entire **`+propagation/+volumetric3d` folder is gone**. Its canonical Eikonal boundary condition is in `+phase/+eikonal/+volumetric3d`.
- `+swsynth/+propagation/+projected3d/buildDirectionalSlowness.m` and `buildIncidentBoundaryCondition.m`: the canonical implementations are under `+phase/+eikonal/+projected3d`.
- `+swsynth/+propagation/+spherical/computePointForceShearProjection.m`: redundant wrapper removed; canonical projector under `+spherical/+point_source/+shear_far_field`.

Affected physics tests were retargeted to canonical modules. No Eikonal Fast Sweeping solver, medium builder, source generator, or new V2 contribution was removed.

## 3. Folder-by-folder audit

| Folder / files | Classification | Action |
|---|---|---|
| `+domain`, `+medium`, `+excitation`, `+polarization`, `+observation`, `+io` | V2 core | Keep |
| `+sources/+positions`, `+sources/+excitation`, `+sources/+aperture` | V2 physical source generation | Keep |
| `+phase/+analytical`, `+phase/+eikonal`, `+numerics/+eikonal` | V2 physics and numerical kernels | Keep |
| `+propagation/synthesize.m`, `accumulate.m`, `+plane_wave/computeContribution.m`, `+spherical/+point_source/computeContribution.m` | V2 coherent vector synthesizer | Keep |
| `+propagation/+volumetric3d` | Obsolete Eikonal forwarding folder | **Removed completely** |
| `+propagation/+projected3d` | **Legacy-only** directional filtering, Eikonal helpers, scalar synthesis | Retain until replacing old `synthesizeProjected3DEikonal` backend; then delete folder as a unit |
| `+propagation/+plane_wave/synthesize*.m` | **Legacy-only** scalar synthesis/dispatch (not `computeContribution`) | Retain until retiring old `swsynth.run`; then remove |
| `+propagation/+spherical/+point_source/+shear_far_field/synthesize*.m` | **Legacy-only** scalar adapters | Retain until retiring old `swsynth.run`/run3D; keep core physical projector if used by tests |
| `+phase/+straight_ray` and root `integrateStraightRayTravelTime.m` | Legacy approximate heterogeneous spherical phase, excluded from current V2 scope | Candidate for removal with old backend/tests, NOT an Eikonal replacement |
| `+internal`, `+compat`, `+cli`, `+sources/+compat`, `+metrics` | Primarily legacy execution/compatibility/summary functions | Audit dependent code/tests before removing |
| Root `run.m`, `run3D.m`, `buildMediumMaps*.m`, `defaultConfig*.m`, `validateConfig*.m`, `synthesizeWavefield2D.m`, `buildWavefieldSample*.m`, `generateDirections.m` | Old public backend and configuration pipeline | Retire together **after** the V2 campaign smoke suite is confirmed |

The repository also contains `+kwsim`, `+simcampaigns`, `+simrunner`, `+simviz`, `+simreport`, and `+wavefield`: these are independent/shared subsystems, **not** folders to delete because swsynth is moving to V2.

## 4. Integration/physics still missing from V2

1. Automatic plane-wave direction generation and incidence policies for large REQ-ML campaigns: V2 `scenario.incidence.direction_xyz` is currently explicit; legacy `swsynth.directions.generate` wraps legacy RNG/config. Source positions/phases/amplitudes already support physical random policies.
2. Source/plane spectra and angular support metadata in REQ-ML-specific feature datasets; only a generic V1 `wavefield_sample` adapter is implemented. Test the downstream REQ-ML reader separately.
3. Full source and hardware observation/noise pipeline: current V2 observation is only a signed vector projection. Attenuation/noise/speckle/readout are not implicitly added.
4. Large volumetric memory: `propagation.synthesize` stores intermediate contributions before accumulation; needs future streaming/reduction for high source counts.
5. Legacy physics parity and output/provenance reconciliation before removing older monolithic functions.
6. Numerical solver extension for heterogeneous **spherical** sources remains intentionally deferred (issue #31).
7. Confirm how `simviz`, `simreport`, CLI and PDF reports handle V2 sample metadata and arbitrary-relative-motion units; a figure smoke test is included, but no MATLAB result claimed yet.

## JSON XYZ vector orientation regression (2026-10-15)

A first MATLAB integration run passed 3 of 9 tests and exposed an input-boundary issue: MATLAB `jsondecode` represents some flat JSON `[x,y,z]` arrays as 3-by-1 vectors. The V2 JSON resolver previously required `measurement.axis_xyz` and single `incidence.direction_xyz` to already be 1-by-3. This was not a physical propagation or Eikonal solver failure.

**Fix:** `swsynth.io.resolveConfigV2` converts only known single XYZ vectors to 1-by-3 MATLAB rows, while preserving valid N-by-3 incidence/source matrices. This also covers singleton explicit polarizations, force directions, physical source positions, and aperture axes. A new test `testFlatJsonXYZVectorsAreNormalizedButMatricesPreserved` checks both the 1-by-3 heterogeneous Eikonal case and a 2-by-3 multiwave case directly from the committed JSON files.

**Status:** code fix uploaded; the new/repeated MATLAB results remain pending. Do not treat integration as passing until the full nine-test suite (and the new regression) succeeds.

## 5. MATLAB regression/acceptance commands

```matlab
cd('/Users/sara/local/shear-wave-simulation-framework')
!git pull --ff-only
clear functions
rehash
addpath(fullfile(pwd,'src'))

results=runtests({ ...
 'tests/unit/test_simcampaigns_swsynth_v2_integration.m', ...
 'tests/unit/test_swsynth_wavefield_sample_v2.m', ...
 'tests/unit/test_swsynth_excitation_and_synthesize_v2.m', ...
 'tests/unit/test_swsynth_projected3d_slowness.m', ...
 'tests/unit/test_swsynth_projected3d_phase_delay.m', ...
 'tests/unit/test_swsynth_projected3d_global_phase_reference.m', ...
 'tests/unit/test_swsynth_volumetric_eikonal_physics.m', ...
 'tests/unit/test_swsynth_phase_compute_contract.m', ...
 'tests/unit/test_swsynth_point_force_radiation.m', ...
 'tests/unit/test_simcampaigns_execution.m', ...
 'tests/unit/test_simcampaigns_validation.m', ...
 'tests/unit/test_simrunner_unified_entrypoint.m'});
disp(table(results))
assertSuccess(results)
```

After passing: remove legacy swsynth backend code **as a coherent unit** and migrate/remove legacy-only tests + public examples/configs instead of continuing to maintain two paths in V2. The old worktree remains the preserved source for historic experiments.
