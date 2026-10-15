# swsynth V2 audit after campaign integration — 2026-10-15

**Branch inspected:** `develop/v2`, starting at `b7e29ef`. **Validation evidence:** user reported the full 10-test `test_simcampaigns_swsynth_v2_integration.m` suite **passed in MATLAB** after JSON XYZ normalization. This audit is a source/config/test dependency review; no additional MATLAB validation was performed during the audit. The user has preserved legacy work in another worktree.

## Executive finding

**V2 synthesizer ↔ simcampaigns is connected and integration-tested for the implemented smoke scenarios.** The next major task is *not another propagator*; it is retiring the legacy swsynth backend as a coherent set of source functions, old configs/examples, and obsolete tests. Keep the independent campaign orchestration, visualizations, shared wavefield schema, and kwsim backend.

### Baseline inventory (GitHub recursive tree)

- 856 repository tree entries; **223 MATLAB functions in `src`**: `+kwsim` 79, `+swsynth` **98**, `+simcampaigns` 17, `+simviz` 25, `+simreport` 2, `+simrunner` 1, `+wavefield` 1.
- 132 MATLAB tests under `tests/`, including both V2 and legacy swsynth behavior.
- Four source/config V2 fixtures in `configs/swsynth/v2/` and one V2 campaign smoke fixture in `configs/campaigns/swsynth/smoke/`.
- Many historical examples, archives and committed output files are still in the repository. **174 files currently live under paths containing `/outputs/`**, separate from the `src` cleanup; evaluate their value and provenance before deleting.

## A. Existing end-to-end route — KEEP

```text
simrunner.runConfig / simcampaigns.runCampaign
  └─ simcampaigns.loadCampaignJson / expandCampaign / validateCampaign
       └─ backends.loadBaseConfig / validateRun
            └─ schema_version: "2.0" -> swsynth.io.resolveConfigV2
  └─ backends.executeRun -> backends.executeSwsynthV2
       └─ swsynth.propagation.synthesize(scenario)
            ├─ domain.buildGrid, medium.buildMaps, excitation.resolve
            ├─ plane_wave.computeContribution OR spherical.point_source.computeContribution
            ├─ phase.compute / polarization.compute
            └─ propagation.accumulate
       └─ observation.projectComponent via io.buildWavefieldSampleV2
       └─ wavefield.validateSample
       └─ data/wavefield_sample.mat
       └─ data/run_summary.json, validation/validation_report.json,
          config/resolved_config.json
  └─ campaign_run.json / campaign_runs.csv / campaign_summary.json / resume
  └─ optional simviz figures / simreport PDF
```

Schema `2.0` belongs to **simulation configs**, not the campaign document: campaigns still use schema `1.1/1.2` with `backend="swsynth"`. The backend also supports the existing `kwsim` branch, which must not be removed.

V2 scenarios currently exercised by fixtures/tests: 2D multiple explicit plane waves with varied `c_s` and frequency across a four-run campaign; projected3d coherent point sources with seeded random phase; heterogeneous directional projected3d and volumetric3d Eikonal; sample MAT contract/save/read, simrunner dry-run, standard figures, campaign resume, RNG restoration, and fail-fast invalid-config checks.

**What those passes do not prove:** arbitrary external REQ-ML reader compatibility; arbitrary 10k-source memory/performance; calibrated displacement and acquisition noise; every historical legacy configuration; PDF output when `GeneratePdf=true`.

## B. Legacy dependency barrier — delete TOGETHER, not piecemeal

`simcampaigns.backends.loadBaseConfig/validateRun/executeRun` and `simrunner.runConfig` still route old swsynth configurations through `validateConfig`, `validateConfig3D`, `run`, `run3D`, `compat.resolveAnalyticalSphericalConfig`. Therefore simply deleting the old swsynth implementation **right now** would break public examples and old test suites.

**Next coordinated migration (highest cleanup priority):**
1. Change `simcampaigns`/ `simrunner` to explicitly support **only** schema-2 swsynth configurations on `develop/v2` (with clear migration error for old swsynth schema); **leave kwsim as-is**.
2. Decide how to handle each old example, campaign config, MATLAB smoke test, and documentation example: move to a dedicated legacy archive, remove if redundant with worktree history, or convert representative fixtures to schema 2.0. Do not quietly make previously legacy runs produce a different physical field.
3. Remove obsolete old code in a single coherent, reviewable series; maintain shared V2 kernels and end-to-end tests; run both V2 and kwsim regression suites.

### High-confidence whole-folder retirement candidates (AFTER backend switch)
- `src/+swsynth/+internal/`: legacy `runVolumetric.m`, invoked by `swsynth.run`.
- `src/+swsynth/+cli/`: old `runConfig.m`, invokes old `swsynth.run` (the new generic entrypoint is `simrunner.runConfig`).
- `src/+swsynth/+compat/`: old spherical config/excitation converters; presently referenced by the legacy branch of `simrunner.runConfig`.
- `src/+swsynth/+sources/+compat/`: `prepareLegacy.m`; when removed, also remove the two-argument legacy overload in `sources.prepare`.
- `src/+swsynth/+directions/`: **only a wrapper** calling old `swsynth.generateDirections`; V2 currently uses explicit `incidence.direction_xyz`. Replacement plane-wave generator tracked separately in [issue #32](https://github.com/gsara798/shear-wave-simulation-framework/issues/32).
- `src/+swsynth/+phase/+straight_ray/`: approximated legacy spherical ray integration, not selectable from the V2 `propagation.synthesize` contract; also remove its case from shared `phase.compute` if retirement approved.
- `src/+swsynth/+propagation/+projected3d/`: remaining helpers and scalar synthesizer serve the **legacy projected3d Eikonal/direction filtering path**, not the V2 vector contribution; older direct tests may need to be archived or rewritten against `+phase/+eikonal`.

### Delete old subfamilies, but NOT entire parent folder

- `src/+swsynth/+propagation/+plane_wave/synthesize*.m` (seven legacy scalar/dispatcher files) **but keep** `+plane_wave/computeContribution.m`.
- `src/+swsynth/+propagation/+spherical/+point_source/+shear_far_field/synthesize*.m` (three legacy scalar adapters) **but keep** the canonical `computeShearProjection.m` if used by tests/standalone users.
- Old root `buildMediumMaps*.m`, `buildWavefieldSample*.m`, `defaultConfig*.m`, `validateConfig*.m`, `synthesizeWavefield2D.m`, `generateDirections.m`, `generateDirectionalExcitation.m`, `sampleSolidAngleDirections.m`, `run.m`, `run3D.m`, `evaluateMediumAtXZ.m`, `integrateStraightRayTravelTime.m`, etc.: inspect remaining consumers and remove with matching legacy tests.
- `src/+swsynth/+excitation/fromLegacy.m`: remove old-wavefield-frequency adapter; **keep** V2 `+excitation/resolve.m`.
- `src/+swsynth/+io/createRunDirectory.m`: old standalone CLI output helper; **keep** `io.resolveConfigV2` and `io.buildWavefieldSampleV2`. **Keep/reuse** `io.getFrameworkProvenance.m` to improve V2 provenance.
- `+metrics/`: currently used by old `swsynth.run`; assess whether the 2D spectral-entropy utilities merit relocation to `+diagnostics` rather than removing blindly. They are not V2's spectral diagnostic implementation.
- `+phase/resolveSolver.m` and `+phase/validateCompatibility.m` must **remain**: shared V2 analytical and Eikonal dispatch currently call them. Their support for old aliases can be simplified later.

**Never delete `+phase/+eikonal`, `+numerics/+eikonal`, `+domain`, `+medium`, V2 `+sources` generators, `+polarization`, `+observation`, `+propagation/synthesize` or `accumulate`.** Entire `+propagation/+volumetric3d` forwarding folder was already removed in the previous cleanup.

## C. Remaining V2 integration gaps (priority-ranked)

| Priority | Gap | Source evidence / acceptance |
|---|---|---|
| **P0** | Retire legacy dispatch coherently | Legacy calls remain in `simcampaigns.backends.*` and `simrunner.runConfig`; after switch, no default old swsynth code path or dead tests/examples |
| **P0** | Verify **actual REQ-ML consumer** | Framework validator ensures schema, but does not prove the separate REQ-ML loader can read V2 `wavefield_sample.mat`, its `quantity`, units, phase sign, `material_id`, material k_map or 3D arrays; run a minimal RF-free downstream extraction |
| **P1** | Generate **plane-wave directions** independently in V2 | `incidence.direction_xyz` requires explicit N-by-3 rows; `directions.generate` still calls legacy `generateDirections`; issue #32 |
| **P1** | Complete sample/campaign provenance | `wavefield_sample.sample_id` and `provenance.run_id` are filled, but `dataset_id`, `provenance.campaign_id`, `generator.commit`, `created_utc` and source provenance are currently empty unless provided externally; `campaign_run.json` stores config hash separately. Could populate verified git status/SHA using existing provenance helper and pass campaign metadata explicitly |
| **P1** | Test PDF/report metadata | `simreport.generateRunPdf` displays `config.propagation.phase_model` (legacy naming) whereas V2 uses `phase_method`; figure smoke tests passed but PDF report and header semantics need a V2 regression |
| **P1** | Document generated artifacts/truth semantics | `config/resolved_config.json` currently serializes the V2 request `config`, while `resolveConfigV2` normalizes XYZ and material objects into `scenario`. Clarify distinction or save a serializable normalized/resolved view, preserving original inputs |
| **P1** | Ensure full V2-only regression set | Existing `tests/unit` contains dozens of old `swsynth.run` tests; don't label deleted legacy tests as V2 failures. Retain tests of shared Eikonal numerical kernels, projection, sources, MAT export, campaigns, kwsim |
| **P2** | Independent RNG substreams for production | Top-level config `seed` is scoped/restored in the V2 executor; random physical source positions, force and phases share draws unless configured independently. Consider derived streams for stable parameter sweeps and cross-condition paired realizations |
| **P2** | Scale/memory stress | V2 `propagation.synthesize` constructs a cell of all component field contributions before `accumulate`; high N and volumetric grids will allocate more than one full field per component. Consider streaming coherent reduction |
| **P2** | Broader physics/REQ coverage | counterpropagating, angular-aperture sweeps, near-isotropic 2D/3D, projected-3D diffusivity, and reproducible variability across fields; add material/noise perturbations only as separately scoped choices |
| **Deferred** | Heterogeneous spherical Eikonal, reflections, attenuation and ultrasound readout | Deliberately not in current V2 scope; [issue #31](https://github.com/gsara798/shear-wave-simulation-framework/issues/31) |

### Additional sample interpretation cautions

- V2 `truth.k_map=2*pi*f./truth.cs_map` is **local material shear wavenumber**, not an Eikonal wavefront gradient or REQ-estimated k.
- The observed `data_zx`/`data_zyx` is a complex scalar projection of a vector *relative motion* field; **not** raw ultrasound IQ, calibrated displacement/velocity or wavefield plus tracking noise.
- `valid_mask` means finite grid/data, **not** the REQ-ML reliability mask.
- Planar/diffuse field geometry is inferred from explicitly supplied direction sets, not from actual point-source distributions if `model="plane_wave"`.

## D. Recommended order — keep the refactor focused

1. **Freeze** a V2 regression baseline (the user-reported 10/10 end-to-end tests + all V2 physics/unit suites and selected k-Wave tests).
2. **V2-only public swsynth routing** and clean error for old configs. Keep `kwsim` routing and campaign contracts.
3. **Archive/migrate** old swsynth examples/configs/tests. Avoid deleting still needed boundary/source physics tests.
4. **Delete** seven legacy-only groups / root files by dependency family in reviewable commits. Check stale imports with `rg`; run MATLAB V2/kwsim suites.
5. **External REQ-ML loader acceptance** using one single-wave, one seeded multi-source projected3d and a small 3D volume.
6. **Plane-wave incidence direction API** issue #32, then larger REQ-ML simulation campaigns.
7. Provenance/report and performance improvements as needed.

This is the **audit, not a declaration that further cleanup has already been performed**. No new files were deleted during this review.
