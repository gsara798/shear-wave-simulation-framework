# V2-first swsynth cleanup log

**Goal:** Keep `develop/v2` unambiguous for new work; the old implementation remains available in the user's separate worktree / Git history. This is a staged deletion, not an automatic switch of legacy runners.

## Pass 1: remove redundant aliases (October 2026)

Deleted six source files from `src/+swsynth`:

| Removed wrapper | Canonical implementation / replacement |
|---|---|
| `synthesizePlaneWave3D.m` | `swsynth.propagation.synthesize` for new 3D plane waves; legacy dispatcher still available under `+propagation/+plane_wave/synthesizeVolumetric3D.m` |
| `synthesizeProjected3DEikonal.m` | `swsynth.phase.eikonal.projected3d.computeTravelTime` via `propagation.synthesize` |
| `synthesizeVolumetricEikonal3D.m` | `swsynth.phase.eikonal.volumetric3d.computeTravelTime` via `propagation.synthesize` |
| `+propagation/+plane_wave/synthesizeObserved2D.m` | `swsynth.propagation.synthesize` then `swsynth.observation.projectComponent` |
| `+propagation/+projected3d/computeDirectionalPhaseDelay.m` | `+phase/+eikonal/+projected3d/computeTravelTime.m` |
| `+propagation/+volumetric3d/computeDirectionalTravelTime.m` | `+phase/+eikonal/+volumetric3d/computeTravelTime.m` |

Tests referencing these old aliases were updated to target the canonical Eikonal implementation or, where they tested only a redundant wrapper-versus-module equality, simplified while keeping meaningful legacy `run` integration tests intact. No numerical kernels were removed.

### Remaining old code — deliberately **not** deleted yet

There are still old monolithic synthesizers and dispatchers (`swsynth.run`, `+internal/runVolumetric`, `synthesizeWavefield2D`, older `+propagation/+plane_wave/synthesize*`, older `+propagation/+spherical/+point_source/+shear_far_field/synthesize*`), and legacy configuration and sample builders. These remain in `src` **because** `simcampaigns.backends.executeRun`, `simrunner`, and old tests depend on them; deleting them without replacing the runners would leave dangling APIs.

We can deliberately migrate or retire these in a later, larger **V2-only** pass, since the old worktree is saved. Before the next deletion, decide whether `simrunner` should immediately support V2 scenarios or explicitly refuse old `swsynth` configs; do not leave an accidentally half-working backend.

### V2 API to use for new work

```matlab
result=swsynth.propagation.synthesize(scenario);
wavefield_sample=swsynth.io.buildWavefieldSampleV2(result,scenario);
```

Canonical packages: `+domain`, `+medium`, `+excitation`, `+sources`, `+phase`, `+polarization`, `+propagation`, `+observation`, `+io` and `+numerics`. We are keeping Eikonal numerical solvers and all physical V2 source/phase modules intact.

### MATLAB verification (required after deletion)

```matlab
cd('/Users/sara/local/shear-wave-simulation-framework')
!git pull --ff-only
clear functions
rehash
addpath(fullfile(pwd,"src"))
results=runtests({ ...
    'tests/unit/test_swsynth_excitation_and_synthesize_v2.m', ...
    'tests/unit/test_swsynth_wavefield_sample_v2.m', ...
    'tests/unit/test_swsynth_phase_eikonal_relocation.m', ...
    'tests/unit/test_swsynth_phase_compute_contract.m', ...
    'tests/unit/test_swsynth_projected3d_phase_delay.m', ...
    'tests/unit/test_swsynth_plane_wave_volumetric_module.m', ...
    'tests/unit/test_swsynth_plane_wave_projected3d_module.m', ...
    'tests/unit/test_swsynth_synthesis_physics_v2.m' ...
});
disp(table(results))
assertSuccess(results)
```

No MATLAB execution is claimed for this deletion batch. Track further cleanup under [issue #30](https://github.com/gsara798/shear-wave-simulation-framework/issues/30).
