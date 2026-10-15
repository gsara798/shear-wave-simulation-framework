# swsynth V2-only cleanup: implementation and acceptance

**Branch:** `develop/v2`  
**Date:** 2026-10-15  
**Status:** migration and source cleanup committed; **post-cleanup MATLAB full-suite acceptance remains pending**. The 10-test V2/simcampaigns integration suite passed before deleting legacy code, as reported by the user.

## What changed

- Modular V2 vector synthesis is the **sole supported swsynth execution path** in `simrunner` and `simcampaigns`.
- `swsynth.io.requireV2Config` rejects V1 swsynth simulation configs with `swsynth:LegacyConfigUnsupported`. No silent fallback to old field generators.
- Preserved the **independent kwsim** dispatch, shared campaign scheduler/expansion/resume/CSV writer, visualization/report functions, `wavefield` contract and all Fast Sweeping/Eikonal physics.
- Removed legacy `swsynth.run`/`run3D`, CLI, compatibility packages, `+directions`, `+phase/+straight_ray`, `+propagation/+projected3d`, legacy `synthesize*.m`, sample builders, old configuration/map helpers and old metrics not used in V2.
- `src/+swsynth` decreased from **98 to 54 MATLAB files**.
- Retired **47** V1-specific/historical test files. Retained 25 active swsynth unit files plus general framework tests and kwsim integration suites.
- Removed 19 old swsynth configuration/campaign files and the complete historical `examples/swsynth` subtree (**186 files, including generated outputs**). All remain recoverable from the repository's Git history and the separate backup worktree.
- Migrated remaining shared runner/campaign/heterogeneity/CSV examples and tests to active schema-2 JSON fixtures; fixed V2 frequency, medium, incidence direction counts and validation report paths in `campaign_runs.csv`.
- Adjusted vector-valued campaign sweeps for MATLAB JSON row/column orientation. Updated PDF report cover fields to `excitation.frequency_hz`, `propagation.phase_method`, explicit incidence and geometry.
- Updated root README, `examples/README.md`, `docs/swsynth/README.md`, `src/+swsynth/README.md` and `src/+swsynth/+propagation/README.md`.

## Canonical V2 call chain

```text
run_simulation / run_campaign
  -> simrunner / simcampaigns (backend=swsynth)
  -> requireV2Config (schema_version=2.0)
  -> io.resolveConfigV2
  -> propagation.synthesize
        domain + medium + excitation + sources/incidence
        phase + polarization
        plane_wave.computeContribution OR spherical.point_source.computeContribution
        propagation.accumulate => complex U_xyz
  -> io.buildWavefieldSampleV2 (observation.projectComponent)
  -> wavefield.validateSample
  -> data/wavefield_sample.mat; summary, validation, campaign CSV, figures/PDF
```

V2 simulation fixtures:
- `configs/swsynth/v2/homogeneous_plane_base.json`
- `configs/swsynth/v2/two_sources_projected3d.json`
- `configs/swsynth/v2/projected3d_heterogeneous_eikonal.json`
- `configs/swsynth/v2/volumetric3d_heterogeneous_eikonal.json`

Campaign fixture: `configs/campaigns/swsynth/smoke/swsynth_v2_homogeneous_smoke.json` (four runs).

## Acceptance in MATLAB (now required)

From the repo root, after `git pull --ff-only`:

```matlab
clear functions
rehash
addpath(fullfile(pwd,'src'))

focused=runtests({ ...
    'tests/unit/test_swsynth_excitation_and_synthesize_v2.m', ...
    'tests/unit/test_swsynth_synthesis_physics_v2.m', ...
    'tests/unit/test_swsynth_wavefield_sample_v2.m', ...
    'tests/unit/test_simcampaigns_swsynth_v2_integration.m', ...
    'tests/unit/test_simcampaigns_configuration.m', ...
    'tests/unit/test_simcampaigns_csv_metadata.m', ...
    'tests/unit/test_simcampaigns_execution.m', ...
    'tests/unit/test_simcampaigns_validation.m', ...
    'tests/unit/test_simcampaigns_explicit_runs.m', ...
    'tests/unit/test_simrunner_unified_entrypoint.m', ...
    'tests/unit/test_example_field_regime_campaigns.m', ...
    'tests/unit/test_public_heterogeneous_examples.m', ...
    'tests/unit/test_write_campaign.m'});
disp(table(focused))
assertSuccess(focused)
```

Once these pass, run `runtests('tests/unit')` and `assertSuccess(results)`. The complete k-Wave solver integration tests additionally require the user's external k-Wave toolbox.

No MATLAB was run from the GitHub editing environment. **Do not claim that these new post-cleanup tests pass yet.**

## Intentional remaining work

- Independent reading of real V2 `wavefield_sample.mat` files through the **separate REQ-ML pipeline** (not proven by the framework schema validator).
- V2 independent random/Fibonacci/cone **incident plane-wave direction sampling** (issue #32).
- Historical heterogeneous spherical travel times, refraction/transport, and other physics extensions remain deferred (issue #31).
- Optional campaign-level provenance enrichment (`dataset_id`, campaign ID, verified Git SHA), large-N memory reduction, independent RNG substreams and production PDF validation.
- Historical architecture documents under `docs/architecture` may still describe retired stages. This file and `src/+swsynth/README.md` supersede them as current API references.

Related cleanup tracking: [issue #30](https://github.com/gsara798/shear-wave-simulation-framework/issues/30).
