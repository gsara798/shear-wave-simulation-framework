# Modular swsynth V2

`develop/v2` maintains **one synthetic source of truth**. Historical scalar swsynth execution, configs, legacy direction generators and wrappers are retired; the old experiment workflow remains in the preserved worktree/Git history.

## Public V2 route

```matlab
result=swsynth.propagation.synthesize(scenario);
wavefield_sample=swsynth.io.buildWavefieldSampleV2(result,scenario);
```

Or run a schema-2 simulation JSON through `simrunner.runConfig` / `run_simulation`, and a campaign through `simcampaigns.runCampaign` / `run_campaign`. `swsynth.io.requireV2Config` produces an explicit error on old swsynth schema.

## Current package layout

| Package | Responsibility |
|---|---|
| `+domain` | Spatial grid and observation plane |
| `+medium` | Background shear speed, material maps, inclusions |
| `+excitation` | Shared harmonic frequency and temporal/spatial convention |
| `+sources` | Physical source positions, amplitudes, phases, force vectors, coherent apertures |
| `+phase/+analytical` | Homogeneous planar/projected/volumetric plane and spherical travel time |
| `+phase/+eikonal`, `+numerics/+eikonal` | Projected/volumetric heterogeneous **plane-wave** Eikonal and Fast Sweeping |
| `+polarization` | Transverse incident polarization and source radiation |
| `+propagation` | One plane or spherical contribution, coherent vector superposition |
| `+observation` | Signed projection along a measurement axis |
| `+io` | Schema-2 JSON validation and `wavefield_sample` adaptation |
| `+diagnostics` | Complex-FFT spectral checks |

The V2 `+phase/resolveSolver.m` and `validateCompatibility.m` files are **active V2 dependencies**. No legacy scalar `synthesize*.m`, `run.m`, `run3D.m`, `+internal`, `+cli`, `+compat`, `+directions`, `+phase/+straight_ray`, or `+propagation/+projected3d` modules are required by the maintained V2 pipeline.

## Current model boundaries

- Plane waves: homogeneous analytical phase in 2D/projected3D/volumetric3D; heterogeneous Eikonal only in projected3D/volumetric3D.
- Spherical point-force waves: homogeneous analytical phase and shear far-field radiation. Heterogeneous spherical propagation is deferred in issue #31.
- Directional `incidence.direction_xyz` is currently explicit: a new V2 direction sampler is deferred in issue #32.
- `wavefield_sample` contains complex projected relative motion and material truth; no implicit calibrated ultrasound acquisition/noise or attenuating viscoelastic transport.

See `docs/architecture/V2_WAVEFIELD_SAMPLE_ADAPTER.md`, `docs/architecture/V2_AUDIT_POST_CAMPAIGN_INTEGRATION_20261015.md`, and issue #30 for migration history.

## Regression

```matlab
results=runtests({ ...
    "tests/unit/test_swsynth_excitation_and_synthesize_v2.m", ...
    "tests/unit/test_swsynth_synthesis_physics_v2.m", ...
    "tests/unit/test_swsynth_wavefield_sample_v2.m", ...
    "tests/unit/test_simcampaigns_swsynth_v2_integration.m"});
disp(table(results));
assertSuccess(results);
```
