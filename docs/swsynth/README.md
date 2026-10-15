# swsynth — modular harmonic wavefield synthesis (V2)

The maintained `develop/v2` backend produces complex **vector** shear-like wavefields without invoking k-Wave. It supports homogeneous plane and physical point-force waves, finite coherent apertures, and plane-wave Eikonal in projected/volumetric heterogeneous shear-speed media.

## Public entry points

```matlab
setup_simulation_framework

out=run_simulation("configs/swsynth/v2/homogeneous_plane_base.json");
out=run_simulation("configs/swsynth/v2/two_sources_projected3d.json");

report=run_campaign( ...
    "configs/campaigns/swsynth/smoke/swsynth_v2_homogeneous_smoke.json");
```

The **simulation** JSON requires `"schema_version": "2.0"`. The `swsynth.run`, `swsynth.run3D`, legacy CLI and V1 sample builders were retired. Old configuration files cannot silently run under V2 and instead produce `swsynth:LegacyConfigUnsupported`. Refer to the preserved backup worktree for historical runs.

For programmatic use:
```matlab
result=swsynth.propagation.synthesize(scenario);
wavefield_sample=swsynth.io.buildWavefieldSampleV2(result,scenario);
```

## Physical and data boundaries

- `excitation` controls the shared harmonic frequency; individual physical source force/amplitude/phase remain under `sources.excitation`, while plane-wave incident amplitude/phase live under `incidence`.
- Analytical phase: planar2d/projected3d/volumetric3d, homogeneous plane or spherical fields.
- Heterogeneous phase: Eikonal for incident planes in projected3d/volumetric3d; heterogeneous spherical extension deferred (issue #31).
- Directional plane-wave sets are **explicit N-by-3 input**; automatic Fibonacci/cone/random incidence generation is deferred (issue #32).
- Complex observed `data_zx` or `data_zyx` is a projection of relative motion, *not* calibrated ultrasound displacement; truth `k_map=2*pi*f/c_s` is a local material map, not a spectral estimate.

See the authoritative V2 source guide at `src/+swsynth/README.md`, `docs/architecture/V2_WAVEFIELD_SAMPLE_ADAPTER.md` and `docs/validation/SYNTHESIZER_V2_PHYSICAL_VALIDATION.md`. The archived architecture notes describing legacy models are historical, not active APIs.
